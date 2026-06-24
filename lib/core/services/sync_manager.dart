import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/job.dart';
import '../models/inspection.dart';

class SyncManager {
  final _supabase = Supabase.instance.client;
  
  Box get _jobCache => Hive.box('job_cache');
  Box get _queue => Hive.box('mutation_queue');

  String get _userId {
    final id = _supabase.auth.currentUser?.id;
    if (id == null) throw Exception('User not logged in');
    return id;
  }

  Future<void> init() async {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.isNotEmpty && results.first != ConnectivityResult.none) {
        _attemptSync();
      }
    });
    
    // Also try syncing on startup if online
    final results = await Connectivity().checkConnectivity();
    if (results.isNotEmpty && results.first != ConnectivityResult.none) {
      _attemptSync();
    }
  }

  // --- JOB CACHING ---
  Future<void> cacheJobs(List<Job> jobs) async {
    await _jobCache.clear();
    final Map<String, String> data = {};
    for (final job in jobs) {
      data[job.id] = jsonEncode(job.toJson());
    }
    await _jobCache.putAll(data);
  }

  List<Job> getCachedJobs() {
    return _jobCache.values.map((v) => Job.fromJson(jsonDecode(v))).toList();
  }

  Future<void> updateJobInCache(
    String jobId,
    Job Function(Job current) transform,
  ) async {
    final jobs = getCachedJobs();
    final index = jobs.indexWhere((job) => job.id == jobId);
    if (index == -1) return;

    jobs[index] = transform(jobs[index]);
    await cacheJobs(jobs);
  }

  // --- OFFLINE MUTATIONS ---
  Future<void> enqueueJobStatus(
    String jobId,
    String status, {
    String? pauseReason,
  }) async {
    await _enqueue({
      'type': 'job_status',
      'id': jobId,
      'value': status,
      'pause_reason': ?pauseReason,
    });
  }

  Future<void> enqueueJobStep(
    String jobId,
    String stepId,
    bool isCompleted,
  ) async {
    await _enqueue({
      'type': 'job_step',
      'id': jobId,
      'step_id': stepId,
      'value': isCompleted,
    });
  }

  Future<void> enqueueServiceStatus(String serviceId, bool isCompleted) async {
    await _enqueue({
      'type': 'service_status',
      'id': serviceId,
      'value': isCompleted,
    });
  }

  Future<void> enqueueDviInspection(InspectionReport report) async {
    await _enqueue({
      'type': 'dvi_inspection',
      'id': report.jobId,
      'value': report.toSupabaseRow(),
    });
  }

  Future<void> _enqueue(Map<String, dynamic> payload) async {
    await _queue.add(jsonEncode(payload));
    _attemptSync(); // Immediately attempt just in case we are online
  }

  Future<void> _attemptSync() async {
    if (_queue.isEmpty) return;

    final results = await Connectivity().checkConnectivity();
    if (results.isEmpty || results.first == ConnectivityResult.none) return;

    final keys = _queue.keys.toList();

    for (final key in keys) {
      final item = _queue.get(key);
      if (item == null) continue;

      try {
        final payload = jsonDecode(item) as Map<String, dynamic>;
        final type = payload['type'];
        final id = payload['id'];
        final value = payload['value'];

        if (type == 'job_status') {
          final status = jobStatusFromName(value as String?);
          await _supabase
              .from('jobs')
              .update({'status': status.supabaseName})
              .eq('id', id)
              .eq('technician_id', _userId);
        } else if (type == 'job_step') {
          await _updateJobStepInLineItems(
            jobId: id as String,
            stepId: payload['step_id'] as String,
            isCompleted: value as bool,
          );
        } else if (type == 'service_status') {
          await _updateServiceInLineItems(
            serviceId: id as String,
            isCompleted: value as bool,
          );
        } else if (type == 'dvi_inspection') {
          final row = Map<String, dynamic>.from(value as Map);
          row['technician_id'] ??= _userId;
          await _supabase.from('inspections').insert(row);
        }
        
        // If successful, remove from queue
        await _queue.delete(key);
      } catch (e) {
        // If it fails due to network/server, keep it in queue for next time.
      }
    }
  }

  Future<void> _updateJobStepInLineItems({
    required String jobId,
    required String stepId,
    required bool isCompleted,
  }) async {
    final row = await _supabase
        .from('jobs')
        .select('line_items')
        .eq('id', jobId)
        .eq('technician_id', _userId)
        .single();

    final updated = _toggleCompletionInLineItems(
      row['line_items'],
      matchId: stepId,
      isCompleted: isCompleted,
    );
    if (updated == null) return;

    await _supabase
        .from('jobs')
        .update({'line_items': updated})
        .eq('id', jobId)
        .eq('technician_id', _userId);
  }

  Future<void> _updateServiceInLineItems({
    required String serviceId,
    required bool isCompleted,
  }) async {
    final rows = await _supabase
        .from('jobs')
        .select('id, line_items')
        .eq('technician_id', _userId);

    for (final row in rows) {
      final updated = _toggleCompletionInLineItems(
        row['line_items'],
        matchId: serviceId,
        isCompleted: isCompleted,
        matchKey: 'serviceId',
      );
      if (updated == null) continue;

      await _supabase
          .from('jobs')
          .update({'line_items': updated})
          .eq('id', row['id'])
          .eq('technician_id', _userId);
      return;
    }
  }

  List<Map<String, dynamic>>? _toggleCompletionInLineItems(
    dynamic rawLineItems, {
    required String matchId,
    required bool isCompleted,
    String matchKey = 'id',
  }) {
    if (rawLineItems is! List) return null;

    var changed = false;
    final items = rawLineItems.map((entry) {
      final item = Map<String, dynamic>.from(entry as Map);
      if (item['name'] == '__meta__') return item;

      final candidate = item[matchKey]?.toString() ?? item['id']?.toString();
      if (candidate != matchId) return item;

      changed = true;
      return {...item, 'is_completed': isCompleted};
    }).toList();

    return changed ? items : null;
  }
}
