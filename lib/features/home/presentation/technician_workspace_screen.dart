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
  late Future<List<Job>> _jobsFuture;
  final JobRepository _repository = JobRepository();

  @override
  void initState() {
    super.initState();
    _jobsFuture = _repository.fetchJobs();
  }

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.surface,
      appBar: AppBar(title: const Text('My Workspace')),
      body: FutureBuilder<List<Job>>(
        future: _jobsFuture,
        builder: (context, snapshot) {
          debugPrint('--- BUILDER CALLED ---');
          debugPrint('ConnectionState: ${snapshot.connectionState}');
          if (snapshot.hasError) {
            debugPrint('ERROR: ${snapshot.error}');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final jobs = snapshot.data ?? [];
          final currentUser = SessionStore.currentUser;

          // Filter jobs: Temporary debug filter to show all assigned jobs
          final currentUserId = SessionStore.currentUser?.id;
          
          final myActiveJobs = jobs.where((job) {
            return job.technicianId == currentUserId;
          }).toList();
          
          debugPrint('--- DEBUG WORKSPACE ---');
          debugPrint('Logged in as ID: ${SessionStore.currentUser?.id}');
          debugPrint('Total Jobs in DB: ${jobs.length}');
          if (jobs.isNotEmpty) {
            debugPrint('First Job Tech ID: ${jobs.first.technicianId}');
            debugPrint('First Job Status: ${jobs.first.status}');
          }
          debugPrint('Matched Jobs: ${myActiveJobs.length}');
          debugPrint('-----------------------');

          return Column(
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
          );
        },
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
