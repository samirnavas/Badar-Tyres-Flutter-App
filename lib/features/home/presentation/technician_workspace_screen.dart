import 'package:flutter/material.dart';

import '../../../core/auth/session_store.dart';
import '../../../core/models/job.dart';
import '../../../core/repositories/job_repository.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/job_list_tile.dart';
import '../../../core/widgets/metric_card.dart';
import '../../job_card/presentation/job_card_preview_screen.dart';

class TechnicianWorkspaceScreen extends StatefulWidget {
  const TechnicianWorkspaceScreen({super.key});

  @override
  State<TechnicianWorkspaceScreen> createState() =>
      _TechnicianWorkspaceScreenState();
}

class _TechnicianWorkspaceScreenState extends State<TechnicianWorkspaceScreen> {
  List<Job>? _jobs;
  String? _error;
  final JobRepository _repository = JobRepository();

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    try {
      final jobs = await _repository.fetchMyJobs();
      if (mounted) {
        setState(() {
          _jobs = jobs;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    }
  }

  Future<void> _handleStatusChange(Job job, JobStatus newStatus) async {
    setState(() {
      final index = _jobs?.indexWhere((j) => j.id == job.id) ?? -1;
      if (index == -1) return;

      var newStartTime = job.startTime;
      var newActualEnd = job.actualEnd;
      final now =
          '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}';

      if (newStatus == JobStatus.inProgress &&
          job.status != JobStatus.inProgress) {
        if (job.startTime == '-') newStartTime = now;
      } else if (newStatus == JobStatus.completed) {
        newActualEnd = now;
      }

      _jobs![index] = job.copyWith(
        status: newStatus,
        startTime: newStartTime,
        actualEnd: newActualEnd,
      );
    });

    try {
      if (newStatus == JobStatus.inProgress) {
        await _repository.startJob(job.id);
      } else if (newStatus == JobStatus.completed) {
        await _repository.completeJob(job.id);
      } else if (newStatus == JobStatus.onHold) {
        await _repository.pauseJob(job.id, newStatus);
      } else {
        await _repository.updateJobStatus(job.id, newStatus);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update: $e')),
      );
      await _loadJobs();
    }
  }

  List<Job> _myJobs(List<Job> jobs) {
    final currentUserId = SessionStore.currentUser?.id;
    return jobs.where((job) => job.technicianId == currentUserId).toList();
  }

  List<Job> _sortJobs(List<Job> jobs) {
    final sorted = List<Job>.from(jobs);
    sorted.sort((a, b) {
      // In progress first
      if (a.status == JobStatus.inProgress && b.status != JobStatus.inProgress) return -1;
      if (a.status != JobStatus.inProgress && b.status == JobStatus.inProgress) return 1;
      
      // Then pending
      if (a.status == JobStatus.pending && b.status != JobStatus.pending) return -1;
      if (a.status != JobStatus.pending && b.status == JobStatus.pending) return 1;

      // Then urgency
      final endCompare = _expectedEndSortKey(a.expectedEnd)
          .compareTo(_expectedEndSortKey(b.expectedEnd));
      if (endCompare != 0) return endCompare;

      final delayCompare =
          _delaySortKey(a.delay).compareTo(_delaySortKey(b.delay));
      if (delayCompare != 0) return delayCompare;

      final aCreated = a.createdAt?.millisecondsSinceEpoch ?? 0;
      final bCreated = b.createdAt?.millisecondsSinceEpoch ?? 0;
      return aCreated.compareTo(bCreated);
    });
    return sorted;
  }

  int _expectedEndSortKey(String value) {
    if (value == '-' || value.isEmpty) return 1 << 20;
    final parts = value.split(':');
    if (parts.length < 2) return 1 << 19;
    final hour = int.tryParse(parts[0]) ?? 24;
    final minute = int.tryParse(parts[1]) ?? 59;
    return hour * 60 + minute;
  }

  int _delaySortKey(String? value) {
    final normalized = value?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty || normalized == '-') {
      return 0;
    }
    final digits = RegExp(r'\d+').firstMatch(normalized);
    return int.tryParse(digits?.group(0) ?? '0') ?? 0;
  }

  bool _isDelayed(Job job) {
    if (job.status == JobStatus.onHold) return true;
    final delay = _delaySortKey(job.delay);
    return delay > 0;
  }

  void _openJob(Job job) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => JobExecutionScreen(job: job)),
    );
  }

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.stackLg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_rounded,
                  size: 48, color: context.colors.secondary),
              const SizedBox(height: AppSpacing.stackMd),
              Text(
                'Unable to load workspace',
                style: context.typography.titleSm,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.base),
              Text(
                _error!,
                style: context.typography.bodyMd.copyWith(
                  color: context.colors.secondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.stackLg),
              OutlinedButton.icon(
                onPressed: _loadJobs,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_jobs == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final myJobs = _myJobs(_jobs!);
    final sortedJobs = _sortJobs(myJobs);

    final totalCount = myJobs.length;
    final runningCount = myJobs.where((j) => j.status == JobStatus.inProgress).length;
    final completedCount = myJobs.where((j) => j.status == JobStatus.completed).length;
    final delayedCount = myJobs.where((j) => _isDelayed(j)).length;

    return RefreshIndicator(
      color: context.colors.primary,
      onRefresh: _loadJobs,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.containerPadding),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: MetricCard.totalJobs(
                          value: totalCount.toString(),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.gutter),
                      Expanded(
                        child: MetricCard.running(
                          value: runningCount.toString(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.gutter),
                  Row(
                    children: [
                      Expanded(
                        child: MetricCard.completed(
                          value: completedCount.toString(),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.gutter),
                      Expanded(
                        child: MetricCard.delayed(
                          value: delayedCount.toString(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (sortedJobs.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(context),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.containerPadding,
              ).copyWith(bottom: AppSpacing.stackLg),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final job = sortedJobs[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.gutter),
                      child: JobListTile(
                        key: ValueKey(job.id),
                        jobNumber: job.jobNumber,
                        customerName: job.customerName,
                        vehicleModel: job.vehicleModel,
                        vehicleNumber: job.vehicleNumber,
                        status: job.status,
                        time: job.time,
                        date: job.date,
                        technician: job.technician,
                        startTime: job.startTime,
                        expectedEnd: job.expectedEnd,
                        actualEnd: job.actualEnd,
                        delay: job.delay,
                        onTap: () => _openJob(job),
                        onStatusChange: (status) =>
                            _handleStatusChange(job, status),
                      ),
                    );
                  },
                  childCount: sortedJobs.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: context.colors.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.stackMd),
          Text(
            'All caught up! You have no tasks assigned.',
            style: context.typography.bodyMd.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

