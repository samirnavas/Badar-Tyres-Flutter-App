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
        final now = "${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}";

        if (newStatus == JobStatus.running && job.status != JobStatus.running) {
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
      if (newStatus == JobStatus.running) {
        await _repository.startJob(job.id);
      } else if (newStatus == JobStatus.completed) {
        await _repository.completeJob(job.id);
      } else {
        await _repository.pauseJob(job.id, newStatus);
      }
    } catch (e) {
      // Revert on failure
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
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
        appBar: AppBar(title: const Text('My Workspace')),
        body: Center(
          child: Text(
            'Error: $_error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    if (_jobs == null) {
      return Scaffold(
        backgroundColor: context.colors.surface,
        appBar: AppBar(title: const Text('My Workspace')),
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
      appBar: AppBar(title: const Text('My Workspace')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.stackLg),
            child: Text(
              'Hello, ${currentUser?.name ?? 'Technician'}',
              style: context.typography.headlineMd,
            ),
          ),
          Expanded(
            child: myActiveJobs.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
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
                                  builder: (_) =>
                                      JobExecutionScreen(job: job),
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
                          color: Colors.red.shade50,
                          margin: const EdgeInsets.only(
                            bottom: AppSpacing.gutter,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'Error loading job: $e',
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        );
                      }
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
          const SizedBox(height: AppSpacing.stackMd),
          Text(
            'All caught up! You have no active tasks assigned.',
            style: context.typography.bodyMd.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
