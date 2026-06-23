import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SyncManager {
  static const _queueKey = 'offline_mutation_queue';
  final _supabase = Supabase.instance.client;

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

  Future<void> enqueueJobStatus(String jobId, String status) async {
    await _enqueue({
      'type': 'job_status',
      'id': jobId,
      'value': status,
    });
    _attemptSync(); // Immediately attempt just in case we are online
  }

  Future<void> enqueueServiceStatus(String serviceId, bool isCompleted) async {
    await _enqueue({
      'type': 'service_status',
      'id': serviceId,
      'value': isCompleted,
    });
    _attemptSync(); // Immediately attempt just in case we are online
  }

  Future<void> _enqueue(Map<String, dynamic> payload) async {
    final prefs = await SharedPreferences.getInstance();
    final queue = prefs.getStringList(_queueKey) ?? [];
    queue.add(jsonEncode(payload));
    await prefs.setStringList(_queueKey, queue);
  }

  Future<void> _attemptSync() async {
    final prefs = await SharedPreferences.getInstance();
    final queue = prefs.getStringList(_queueKey) ?? [];
    if (queue.isEmpty) return;

    final List<String> failedQueue = [];

    for (final item in queue) {
      try {
        final payload = jsonDecode(item) as Map<String, dynamic>;
        final type = payload['type'];
        final id = payload['id'];
        final value = payload['value'];

        if (type == 'job_status') {
          await _supabase
              .from('jobs')
              .update({'status': value})
              .eq('id', id)
              .eq('technician_id', _userId);
        } else if (type == 'service_status') {
          await _supabase
              .from('invoices')
              .update({'is_completed': value})
              .eq('id', id);
        }
      } catch (e) {
        // If it fails (e.g. network still down despite Connectivity saying otherwise), keep it in queue
        failedQueue.add(item);
      }
    }

    await prefs.setStringList(_queueKey, failedQueue);
  }
}
