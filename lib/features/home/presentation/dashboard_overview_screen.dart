import 'dart:ui';
import 'package:flutter/material.dart';


import '../../../core/models/job.dart';
import '../../../core/repositories/job_repository.dart';
import '../../../core/theme/theme.dart';
import '../../job_card/presentation/job_card_preview_screen.dart' as job_card;

/// The modernized Technician "My Workspace" view.
class DashboardOverviewScreen extends StatefulWidget {
  const DashboardOverviewScreen({
    super.key,
    required this.onCreateJob,
    required this.onViewJobs,
  });

  final VoidCallback onCreateJob;
  final VoidCallback onViewJobs;

  @override
  State<DashboardOverviewScreen> createState() => _DashboardOverviewScreenState();
}

class _DashboardOverviewScreenState extends State<DashboardOverviewScreen> {
  final JobRepository _repository = JobRepository();
  late Stream<List<Job>> _jobsStream;

  @override
  void initState() {
    super.initState();
    _jobsStream = _repository.streamJobs();
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
      appBar: AppBar(
        title: const Text('My Workspace'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              setState(() {
                _jobsStream = _repository.streamJobs();
              });
            },
          ),
          const SizedBox(width: AppSpacing.base),
        ],
      ),
      body: StreamBuilder<List<Job>>(
        stream: _jobsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final allJobs = snapshot.data ?? [];
          final inProgress = allJobs.where((j) => j.status.name == 'running' || j.status.name == 'in_progress').toList();
          final pending = allJobs.where((j) => j.status.name == 'pending').toList();
          final activeJob = inProgress.isNotEmpty ? inProgress.first : null;

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.containerPadding,
              AppSpacing.stackMd,
              AppSpacing.containerPadding,
              AppSpacing.stackLg,
            ),
            children: [
              Text('Current Active Job',
                  style: context.typography.titleSm.copyWith(fontSize: 16)),
              const SizedBox(height: AppSpacing.gutter),
              if (activeJob != null)
                _ActiveJobHeroCard(job: activeJob)
              else
                _buildEmptyActiveJob(),
              
              const SizedBox(height: AppSpacing.stackLg),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Today\'s Queue',
                      style: context.typography.titleSm.copyWith(fontSize: 16)),
                  Text('${pending.length} Jobs',
                      style: context.typography.bodyMd.copyWith(color: context.colors.secondary)),
                ],
              ),
              const SizedBox(height: AppSpacing.gutter),
              
              if (pending.isNotEmpty)
                ...pending.map((job) => _QueueJobItem(job: job))
              else
                _buildEmptyQueue(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyActiveJob() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.stackLg),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: context.colors.outlineVariant),
      ),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.check_circle_outline, size: 48, color: context.colors.secondary),
          const SizedBox(height: AppSpacing.gutter),
          Text(
            'No active jobs right now.',
            style: context.typography.bodyMd.copyWith(color: context.colors.secondary),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyQueue() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.stackLg),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: context.colors.outlineVariant, style: BorderStyle.solid),
      ),
      alignment: Alignment.center,
      child: Text(
        'Your queue is clear.',
        style: context.typography.bodyMd.copyWith(color: context.colors.secondary),
      ),
    );
  }
}

class _ActiveJobHeroCard extends StatelessWidget {
  const _ActiveJobHeroCard({required this.job});

  final Job job;

  @override
  Widget build(BuildContext context) {
    // Glassmorphism and monochromatic base
    return ClipRRect(
      borderRadius: AppRadius.brLg,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: context.colors.surfaceContainerHighest.withValues(alpha: 0.6),
            borderRadius: AppRadius.brLg,
            // STRICT LIGHT GREY BORDER IN DARK MODE RULE
            border: Border.all(color: const Color(0xFFE0E0E0), width: 1.5),
          ),
          padding: const EdgeInsets.all(AppSpacing.stackMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.colors.surface,
                      borderRadius: AppRadius.brFull,
                      border: Border.all(color: context.colors.outlineVariant),
                    ),
                    child: Text(
                      job.jobNumber,
                      style: context.typography.labelSm,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Started ${job.startTime}',
                        style: context.typography.labelSm,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.stackMd),
              Text(
                job.vehicleModel.isNotEmpty ? job.vehicleModel : 'Unknown Vehicle',
                style: context.typography.headlineMd.copyWith(fontSize: 22),
              ),
              const SizedBox(height: AppSpacing.stackSm),
              Row(
                children: [
                  Icon(Icons.directions_car_filled_outlined,
                      size: 18, color: context.colors.secondary),
                  const SizedBox(width: 8),
                  Text(
                    job.vehicleNumber,
                    style: context.typography.bodyMd.copyWith(color: context.colors.secondary),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.stackMd),
              const Divider(color: Color(0xFF555555), height: 1),
              const SizedBox(height: AppSpacing.stackMd),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: context.colors.onSurface),
                        foregroundColor: context.colors.onSurface,
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => job_card.JobExecutionScreen(job: job)),
                        );
                      },
                      child: const Text('View Details'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.gutter),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colors.onSurface,
                        foregroundColor: context.colors.surface,
                      ),
                      onPressed: () {},
                      child: const Text('Complete Job'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QueueJobItem extends StatelessWidget {
  const _QueueJobItem({required this.job});

  final Job job;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.gutter),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHigh,
        borderRadius: AppRadius.brLg,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: context.colors.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(Icons.build_outlined, color: context.colors.onSurface),
        ),
        title: Text(
          job.vehicleModel.isNotEmpty ? job.vehicleModel : 'Unknown Vehicle',
          style: context.typography.titleSm.copyWith(fontSize: 16),
        ),
        subtitle: Text(
          '${job.jobNumber} • ${job.vehicleNumber}',
          style: context.typography.bodyMd.copyWith(fontSize: 13, color: context.colors.secondary),
        ),
        trailing: Icon(Icons.chevron_right_rounded, color: context.colors.secondary),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => job_card.JobExecutionScreen(job: job)),
          );
        },
      ),
    );
  }
}