import 'package:flutter/material.dart';

import '../../../core/auth/session_store.dart';
import '../../../core/models/job.dart';

import '../../../core/repositories/job_repository.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/job_list_tile.dart';
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
      final jobs = await _repository.fetchJobs();
      if (mounted) {
        setState(() {
          _jobs = jobs;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _handleStatusChange(Job job, JobStatus newStatus) async {
    // 1. Optimistic UI update
    setState(() {
      final index = _jobs?.indexWhere((j) => j.id == job.id) ?? -1;
      if (index != -1) {
        String? newStartTime = job.startTime;
        String? newActualEnd = job.actualEnd;
        final now =
            "${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}";

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
      }
    });

    // 2. Backend update
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
      // Revert on failure
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
        _loadJobs(); // refresh
      }
    }
  }

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        backgroundColor: context.colors.surface,
        body: Center(
          child: Text(
            'Error: $_error',
            style: TextStyle(color: context.colors.error),
          ),
        ),
      );
    }

    if (_jobs == null) {
      return Scaffold(
        backgroundColor: context.colors.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final currentUser = SessionStore.currentUser;
    final currentUserId = currentUser?.id;

    final myActiveJobs = _jobs!.where((job) {
      return job.technicianId == currentUserId;
    }).toList();

    // Sort by expected delivery time (prioritized)
    myActiveJobs.sort((a, b) => a.expectedEnd.compareTo(b.expectedEnd));

    return Scaffold(
      backgroundColor: context.colors.surface,
      body: RefreshIndicator(
        color: context.colors.primary,
        onRefresh: _loadJobs,
        child: myActiveJobs.isEmpty
            ? LayoutBuilder(
                builder: (context, constraints) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    Container(
                      height: constraints.maxHeight,
                      alignment: Alignment.center,
                      child: _buildEmptyState(),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.containerPadding,
                ),
                itemCount: myActiveJobs.length,
                itemBuilder: (context, index) {
                  try {
                    final job = myActiveJobs[index];
                    return Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppSpacing.gutter,
                      ),
                      child: JobListTile(
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
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => JobExecutionScreen(job: job),
                            ),
                          );
                        },
                        onStatusChange: (newStatus) {
                          _handleStatusChange(job, newStatus);
                        },
                      ),
                    );
                  } catch (e) {
                    return Card(
                      color: context.colors.errorContainer,
                      margin: const EdgeInsets.only(
                        bottom: AppSpacing.gutter,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Error loading job: $e',
                          style: TextStyle(color: context.colors.error),
                        ),
                      ),
                    );
                  }
                },
              ),
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
            'All caught up! You have no active tasks assigned.',
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
