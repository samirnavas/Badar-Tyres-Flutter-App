import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/job.dart';
import '../models/job_metrics.dart';
import '../models/job_status.dart';
import '../models/vehicle.dart';
import '../services/sync_manager.dart';

/// Data access for jobs, metrics, and technicians. Talks to Supabase.
class JobRepository {
  final _syncManager = SyncManager();

  JobRepository() {
    _syncManager.init();
  }

  final _supabase = Supabase.instance.client;

  String get _userId {
    final id = _supabase.auth.currentUser?.id;
    if (id == null) throw Exception('User not logged in');
    return id;
  }

  Future<JobMetrics> fetchMetrics() async {
    final response = await _supabase
        .from('jobs')
        .select('status')
        .eq('technician_id', _userId);
        
    int total = response.length;
    int completed = response.where((j) => j['status'] == 'completed').length;
    int pending = response.where((j) => j['status'] == 'pending').length;
    int inProgress = response.where((j) => j['status'] == 'in_progress').length;

    return JobMetrics(
      totalJobs: total,
      completed: completed,
      pending: pending,
      running: inProgress,
      delayed: 0,
    );
  }

  Stream<List<Job>> streamJobs({String status = 'all'}) {
    final stream = _supabase.from('jobs').stream(primaryKey: ['id']).eq('technician_id', _userId);
    return stream.map((data) {
      final jobs = data.map((e) => Job.fromJson(e)).toList();
      if (status != 'all') {
        final targetStatus = jobStatusFromName(status);
        return jobs.where((j) => j.status == targetStatus).toList();
      }
      return jobs;
    });
  }

  Future<List<Job>> fetchJobs({String status = 'all', String search = ''}) async {
    var query = _supabase.from('jobs').select('*, services:invoices(*)').eq('technician_id', _userId);
    
    if (status != 'all') {
      query = query.eq('status', status);
    }
    
    if (search.isNotEmpty) {
      query = query.ilike('jobNumber', '%$search%'); // Assuming search by jobNumber
    }

    final data = await query;
    return data.map((e) => Job.fromJson(e)).toList();
  }

  Future<List<Vehicle>> fetchVehicles() async {
    final data = await _supabase.from('vehicles').select();
    return data.map((e) => Vehicle.fromJson(e)).toList();
  }

  Future<Job> fetchJob(String id) async {
    final data = await _supabase
        .from('jobs')
        .select('*, services:invoices(*)')
        .eq('id', id)
        .eq('technician_id', _userId) // Security check
        .single();
    return Job.fromJson(data);
  }

  Future<void> updateJobStatus(String jobId, String status) async {
    // Offline-first approach via SyncManager
    await _syncManager.enqueueJobStatus(jobId, status);
  }

  Future<void> updateServiceStatus(String serviceId, bool isCompleted) async {
    // Offline-first approach via SyncManager
    await _syncManager.enqueueServiceStatus(serviceId, isCompleted);
  }

  Future<List<String>> fetchTechnicians() async {
    final data = await _supabase.from('users').select('name').eq('role', 'technician');
    return data.map((e) => e['name'].toString()).toList();
  }

  Future<Map<String, List<String>>> fetchManufacturers() async {
    // Simplified fetch for manufacturers/models from Supabase
    final data = await _supabase.from('manufacturers').select();
    final map = <String, List<String>>{};
    for (final row in data) {
      final name = row['name'] as String;
      final models = (row['models'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
      map[name] = models;
    }
    return map;
  }

  Future<Job> createJob(Map<String, dynamic> payload) async {
    // Enforce technician_id check on creation
    payload['technician_id'] = _userId;
    
    final data = await _supabase
        .from('jobs')
        .insert(payload)
        .select()
        .single();
    return Job.fromJson(data);
  }

  void dispose() {}
}
