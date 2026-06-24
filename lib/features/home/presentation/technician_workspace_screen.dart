import 'package:flutter/material.dart';

import '../../../core/auth/session_store.dart';
import '../../../core/models/job.dart';
import '../../../core/repositories/job_repository.dart';
import '../../../core/theme/theme.dart';
import '../../job_card/presentation/job_card_preview_screen.dart';
import 'widgets/active_job_card.dart';
import 'widgets/pending_job_tile.dart';

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

  Job? _activeJob(List<Job> jobs) {
    for (final job in jobs) {
      if (job.status == JobStatus.inProgress) return job;
    }
    return null;
  }

  List<Job> _pendingJobs(List<Job> jobs) {
    final pending =
        jobs.where((job) => job.status == JobStatus.pending).toList();
    pending.sort(_compareUrgency);
    return pending;
  }

  int _compareUrgency(Job a, Job b) {
    final endCompare = _expectedEndSortKey(a.expectedEnd)
        .compareTo(_expectedEndSortKey(b.expectedEnd));
    if (endCompare != 0) return endCompare;

    final delayCompare =
        _delaySortKey(a.delay).compareTo(_delaySortKey(b.delay));
    if (delayCompare != 0) return delayCompare;

    final aCreated = a.createdAt?.millisecondsSinceEpoch ?? 0;
    final bCreated = b.createdAt?.millisecondsSinceEpoch ?? 0;
    return aCreated.compareTo(bCreated);
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

  String _bayHeading(Job? activeJob, List<Job> pendingJobs) {
    final bay = activeJob?.bayName?.trim();
    if (bay != null && bay.isNotEmpty) return bay;

    for (final job in pendingJobs) {
      final pendingBay = job.bayName?.trim();
      if (pendingBay != null && pendingBay.isNotEmpty) return pendingBay;
    }

    return 'Unassigned';
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
    final activeJob = _activeJob(myJobs);
    final pendingJobs = _pendingJobs(myJobs);
    final bayHeading = _bayHeading(activeJob, pendingJobs);

    return RefreshIndicator(
      color: context.colors.primary,
      onRefresh: _loadJobs,
      child: myJobs.isEmpty
          ? LayoutBuilder(
              builder: (context, constraints) => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: constraints.maxHeight,
                    child: _buildEmptyState(),
                  ),
                ],
              ),
            )
          : ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.containerPadding,
                AppSpacing.stackMd,
                AppSpacing.containerPadding,
                AppSpacing.stackLg,
              ),
              children: [
                if (activeJob != null) ...[
                  ActiveJobCard(
                    job: activeJob,
                    onPause: () =>
                        _handleStatusChange(activeJob, JobStatus.onHold),
                    onComplete: () =>
                        _handleStatusChange(activeJob, JobStatus.completed),
                    onOpenDetails: () => _openJob(activeJob),
                  ),
                  const SizedBox(height: AppSpacing.stackLg),
                ] else ...[
                  _NoActiveJobBanner(),
                  const SizedBox(height: AppSpacing.stackLg),
                ],
                Text(
                  'Up Next ($bayHeading)',
                  style: context.typography.titleSm.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.gutter),
                if (pendingJobs.isEmpty)
                  _NoPendingJobsMessage(hasActiveJob: activeJob != null)
                else
                  ...pendingJobs.asMap().entries.map((entry) {
                    final index = entry.key;
                    final job = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.gutter),
                      child: PendingJobTile(
                        key: ValueKey(job.id),
                        job: job,
                        position: index + 1,
                        onTap: () => _openJob(job),
                        onStart: activeJob == null
                            ? () => _handleStatusChange(
                                  job,
                                  JobStatus.inProgress,
                                )
                            : null,
                      ),
                    );
                  }),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
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

class _NoActiveJobBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: context.colors.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.play_circle_outline,
              color: context.colors.onSurfaceVariant),
          const SizedBox(width: AppSpacing.gutter),
          Expanded(
            child: Text(
              'No job in progress. Start the next pending job below.',
              style: context.typography.bodyMd.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoPendingJobsMessage extends StatelessWidget {
  const _NoPendingJobsMessage({required this.hasActiveJob});

  final bool hasActiveJob;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.stackMd),
      child: Text(
        hasActiveJob
            ? 'No pending jobs in your queue.'
            : 'No pending jobs waiting in your bay.',
        style: context.typography.bodyMd.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      ),
    );
  }
}
