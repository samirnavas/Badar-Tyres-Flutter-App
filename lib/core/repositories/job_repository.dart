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

  Future<JobMetrics> fetchMetrics({bool global = false}) async {
    var query = _supabase.from('jobs').select('status');
    if (!global) {
      query = query.eq('technician_id', _userId);
    }

    final response = await query;

    int total = response.length;
    int completed = 0;
    int pending = 0;
    int inProgress = 0;
    int onHold = 0;

    for (final row in response) {
      switch (jobStatusFromName(row['status']?.toString())) {
        case JobStatus.completed:
          completed++;
        case JobStatus.pending:
          pending++;
        case JobStatus.inProgress:
          inProgress++;
        case JobStatus.onHold:
          onHold++;
      }
    }

    return JobMetrics(
      totalJobs: total,
      completed: completed,
      pending: pending,
      running: inProgress,
      delayed: onHold,
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

  Future<List<Job>> fetchJobs({
    String status = 'all',
    String search = '',
    bool assignedToCurrentUserOnly = true,
  }) async {
    try {
      var query = _supabase
          .from('jobs')
          .select(
            '*, vehicles(*, customers(first_name, last_name, phone)), bays(name)',
          );

      if (assignedToCurrentUserOnly) {
        query = query.eq('technician_id', _userId);
      }

      if (status != 'all') {
        final targetStatus = jobStatusFromName(status);
        query = query.eq('status', targetStatus.supabaseName);
      }

      final data = await query;
      var jobs = data.map((e) => Job.fromJson(e)).toList();

      if (search.isNotEmpty) {
        final needle = search.toLowerCase();
        jobs = jobs
            .where(
              (job) =>
                  job.jobNumber.toLowerCase().contains(needle) ||
                  job.vehicleNumber.toLowerCase().contains(needle) ||
                  job.customerName.toLowerCase().contains(needle) ||
                  job.mobile.toLowerCase().contains(needle),
            )
            .toList();
      }

      if (assignedToCurrentUserOnly) {
        await _syncManager.cacheJobs(jobs);
      }
      return jobs;
    } catch (e) {
      debugPrint('Fetching jobs failed, falling back to cache: $e');
      if (!assignedToCurrentUserOnly) {
        throw Exception('Failed to fetch shop jobs: $e');
      }
      final cached = _syncManager.getCachedJobs();
      if (cached.isNotEmpty) {
        var filtered = cached;
        if (status != 'all') {
          final targetStatus = jobStatusFromName(status);
          filtered =
              filtered.where((j) => j.status == targetStatus).toList();
        }
        if (search.isNotEmpty) {
          final needle = search.toLowerCase();
          filtered = filtered
              .where(
                (job) =>
                    job.jobNumber.toLowerCase().contains(needle) ||
                    job.vehicleNumber.toLowerCase().contains(needle) ||
                    job.customerName.toLowerCase().contains(needle) ||
                    job.mobile.toLowerCase().contains(needle),
              )
              .toList();
        }
        return filtered;
      }
      throw Exception('Failed to fetch active jobs and cache is empty: $e');
    }
  }

  /// All jobs in the shop for the global Jobs directory.
  Future<List<Job>> fetchAllJobs({
    String status = 'all',
    String search = '',
  }) =>
      fetchJobs(
        status: status,
        search: search,
        assignedToCurrentUserOnly: false,
      );

  /// Jobs assigned to the signed-in technician for workspace views.
  Future<List<Job>> fetchMyJobs({
    String status = 'all',
    String search = '',
  }) =>
      fetchJobs(
        status: status,
        search: search,
        assignedToCurrentUserOnly: true,
      );

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
    final job = await fetchJob(jobId);
    final completedAt = isCompleted ? DateTime.now() : null;

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

    await _syncManager.updateJobInCache(jobId, (cached) {
      return cached.copyWith(steps: updatedSteps);
    });

    try {
      await _supabase.rpc(
        'update_job_checklist',
        params: {
          'p_job_id': jobId,
          'p_technician_id': _userId,
          'p_checklist': updatedSteps.map((step) => step.toJson()).toList(),
        },
      );
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
