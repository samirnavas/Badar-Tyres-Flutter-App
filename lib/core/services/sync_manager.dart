import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../api/api_client.dart';
import '../models/job.dart';
import '../models/inspection.dart';

class SyncManager {
  final _supabase = Supabase.instance.client;
  final _apiClient = ApiClient();
  
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

  // --- OFFLINE MUTATIONS ---
  Future<void> enqueueJobStatus(String jobId, String status) async {
    await _enqueue({
      'type': 'job_status',
      'id': jobId,
      'value': status,
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
      'value': report.toJson(),
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
          await _apiClient.postJson('sync/job_status', {
             'id': id,
             'technician_id': _userId,
             'status': value,
          });
        } else if (type == 'service_status') {
          await _apiClient.postJson('sync/service_status', {
             'id': id,
             'is_completed': value,
          });
        } else if (type == 'dvi_inspection') {
          await _apiClient.postJson('sync/dvi_inspection', value);
        }
        
        // If successful, remove from queue
        await _queue.delete(key);
      } catch (e) {
        // If it fails due to network/server, keep it in queue for next time.
        // It will just continue and try the next item (or fail as well).
      }
    }
  }
}
