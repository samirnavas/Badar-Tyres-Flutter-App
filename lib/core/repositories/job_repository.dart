import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/session_store.dart';
import '../models/job.dart';
import '../models/job_metrics.dart';
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
    final id = SessionStore.currentUser?.id;
    if (id == null) throw Exception('User not logged in');
    return id;
  }

  Future<JobMetrics> fetchMetrics() async {
    final response = await _supabase
        .from('jobs')
        .select('status')
        .eq('technician_id', _userId);

    int total = response.length;
    int completed =
        response.where((j) => j['status'] == 'completed').length;
    int pending = response.where((j) => j['status'] == 'pending').length;
    int inProgress =
        response.where((j) => j['status'] == 'in_progress').length;

    return JobMetrics(
      totalJobs: total,
      completed: completed,
      pending: pending,
      running: inProgress,
      delayed: 0,
    );
  }

  Stream<List<Job>> streamJobs({String status = 'all'}) {
    final stream = _supabase
        .from('jobs')
        .stream(primaryKey: ['id'])
        .eq('technician_id', _userId);
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
    try {
      var query = _supabase
          .from('jobs')
          .select('*, vehicles(*, customers(first_name, last_name, phone)), bays(name)')
          .eq('technician_id', _userId);

      if (status != 'all') {
        query = query.eq('status', status);
      }

      if (search.isNotEmpty) {
        query = query.ilike('job_number', '%$search%');
      }

      final data = await query;
      final jobs = data.map((e) => Job.fromJson(e)).toList();
      await _syncManager.cacheJobs(jobs);
      return jobs;
    } catch (e) {
      debugPrint('Fetching jobs failed, falling back to cache: $e');
      final cached = _syncManager.getCachedJobs();
      if (cached.isNotEmpty) {
        var filtered = cached;
        if (status != 'all') {
          filtered =
              filtered.where((j) => j.status.apiName == status).toList();
        }
        if (search.isNotEmpty) {
          filtered = filtered
              .where(
                (j) => j.jobNumber.toLowerCase().contains(search.toLowerCase()),
              )
              .toList();
        }
        return filtered;
      }
      throw Exception('Failed to fetch active jobs and cache is empty: $e');
    }
  }

  Future<List<Vehicle>> fetchVehicles() async {
    final data = await _supabase.from('vehicles').select();
    return data.map((e) => Vehicle.fromJson(e)).toList();
  }

  Future<Job> fetchJob(String id) async {
    final data = await _supabase
        .from('jobs')
        .select('*, vehicles(*, customers(first_name, last_name, phone)), bays(name)')
        .eq('id', id)
        .eq('technician_id', _userId)
        .single();
    return Job.fromJson(data);
  }

  Future<void> updateJobStatus(
    String jobId,
    JobStatus newStatus, {
    String? pauseReason,
    JobHistoryEntry? historyEntry,
  }) async {
    await _syncManager.updateJobInCache(jobId, (job) {
      final updatedHistory = historyEntry == null
          ? job.history
          : [...job.history, historyEntry];
      return job.copyWith(status: newStatus, history: updatedHistory);
    });

    try {
      await _supabase
          .from('jobs')
          .update({'status': newStatus.supabaseName})
          .eq('id', jobId)
          .eq('technician_id', _userId);
    } catch (e) {
      throw Exception('Failed to update job status: $e');
    }
  }

  Future<void> toggleJobStep(
    String jobId,
    String stepId,
    bool isCompleted,
  ) async {
    final completedAt = isCompleted ? DateTime.now() : null;

    await _syncManager.updateJobInCache(jobId, (job) {
      final updatedSteps = job.steps
          .map(
            (step) => step.id == stepId
                ? step.copyWith(
                    isCompleted: isCompleted,
                    completedAt: completedAt,
                    clearCompletedAt: !isCompleted,
                  )
                : step,
          )
          .toList();
      return job.copyWith(steps: updatedSteps);
    });

    try {
      await _syncManager.enqueueJobStep(jobId, stepId, isCompleted);
    } catch (e) {
      throw Exception('Failed to toggle job step: $e');
    }
  }

  Future<void> startJob(String jobId) async {
    await updateJobStatus(jobId, JobStatus.inProgress);
  }

  Future<void> pauseJob(
    String jobId,
    JobStatus reasonStatus, {
    String? pauseReason,
  }) async {
    await updateJobStatus(
      jobId,
      reasonStatus,
      pauseReason: pauseReason,
      historyEntry: pauseReason == null
          ? null
          : JobHistoryEntry(
              action: 'paused',
              timestamp: DateTime.now(),
              note: pauseReason,
            ),
    );
  }

  Future<void> completeJob(String jobId) async {
    await updateJobStatus(jobId, JobStatus.completed);
  }

  Future<void> updateServiceStatus(String serviceId, bool isCompleted) async {
    try {
      await _syncManager.enqueueServiceStatus(serviceId, isCompleted);
    } catch (e) {
      throw Exception('Failed to enqueue service status: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchTechnicians() async {
    final data =
        await _supabase.from('users').select('id, name').eq('role', 'technician');
    return data;
  }

  Future<Map<String, List<String>>> fetchManufacturers() async {
    final data = await _supabase.from('manufacturers').select();
    final map = <String, List<String>>{};
    for (final row in data) {
      final name = row['name'] as String;
      final models = (row['models'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      map[name] = models;
    }
    return map;
  }

  Future<Job> createJob(Map<String, dynamic> payload) async {
    payload['technician_id'] ??= _userId;

    final data =
        await _supabase.from('jobs').insert(payload).select().single();
    return Job.fromJson(data);
  }

  void dispose() {}
}
