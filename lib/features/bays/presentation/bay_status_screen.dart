import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/models/job.dart';
import '../../../core/repositories/job_repository.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/job_list_tile.dart';

class BayStatusScreen extends StatefulWidget {
  const BayStatusScreen({super.key});

  @override
  State<BayStatusScreen> createState() => _BayStatusScreenState();
}

class _BayStatusScreenState extends State<BayStatusScreen> {
  List<Job>? _jobs;
  List<String>? _bays;
  String? _error;
  final JobRepository _repository = JobRepository();

  @override
  void initState() {
    super.initState();
    _loadBays();
  }

  Future<void> _loadBays() async {
    try {
      // Fetch all shop jobs (not just assigned to this tech)
      final jobsFuture = _repository.fetchAllJobs();
      final baysFuture = _repository.fetchBays();
      
      final results = await Future.wait([jobsFuture, baysFuture]);
      final jobs = results[0] as List<Job>;
      final bays = results[1] as List<String>;
      
      // Filter for active jobs that would occupy a bay
      final activeJobs = jobs.where((job) {
        return job.status == JobStatus.inProgress || 
               job.status == JobStatus.pending || 
               job.status == JobStatus.onHold;
      }).toList();

      if (mounted) {
        setState(() {
          _jobs = activeJobs;
          _bays = bays;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
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
                'Unable to load bay status',
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
                onPressed: _loadBays,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_jobs == null || _bays == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Group active jobs by bay
    final bayGroups = <String, List<Job>>{};
    for (final job in _jobs!) {
      final bayName = job.bayName?.trim().isNotEmpty == true 
          ? job.bayName!.trim() 
          : 'Unassigned / Waiting';
      bayGroups.putIfAbsent(bayName, () => []).add(job);
    }

    // Standard bays to show even if empty, to give a layout view
    for (final bay in _bays!) {
      bayGroups.putIfAbsent(bay, () => []);
    }

    final sortedBayNames = bayGroups.keys.toList()..sort((a, b) {
      if (a.contains('Unassigned')) return 1;
      if (b.contains('Unassigned')) return -1;
      return a.compareTo(b);
    });

    return RefreshIndicator(
      color: context.colors.primary,
      onRefresh: _loadBays,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.containerPadding),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Shop Floor Status',
                style: context.typography.headlineMd.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.containerPadding,
            ).copyWith(bottom: AppSpacing.stackLg),
            sliver: SliverList.separated(
              separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.gutter),
              itemCount: sortedBayNames.length,
              itemBuilder: (context, index) {
                final bayName = sortedBayNames[index];
                final jobsInBay = bayGroups[bayName]!;
                
                // Sort by urgency inside the bay
                jobsInBay.sort((a, b) {
                   if (a.status == JobStatus.inProgress) return -1;
                   if (b.status == JobStatus.inProgress) return 1;
                   return 0;
                });

                return _BayCard(
                  bayName: bayName,
                  jobs: jobsInBay,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BayCard extends StatefulWidget {
  const _BayCard({
    required this.bayName,
    required this.jobs,
  });

  final String bayName;
  final List<Job> jobs;

  @override
  State<_BayCard> createState() => _BayCardState();
}

class _BayCardState extends State<_BayCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final muted = colors.onSurfaceVariant;
    
    final activeJob = widget.jobs.isNotEmpty ? widget.jobs.first : null;
    final queueCount = widget.jobs.length > 1 ? widget.jobs.length - 1 : 0;
    
    final statusColor = activeJob != null ? activeJob.status.color : colors.outlineVariant;
    final isOccupied = activeJob != null;

    return GestureDetector(
      onTap: () {
        if (queueCount > 0) {
          HapticFeedback.lightImpact();
          setState(() {
            _isExpanded = !_isExpanded;
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: colors.surfaceContainerHigh,
          borderRadius: AppRadius.brLg,
          border: Border.all(
            color: isOccupied ? statusColor : colors.outlineVariant,
            width: isOccupied ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.stackMd),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.bayName,
                    style: context.typography.titleSm.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isOccupied)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppStatusColors.tint(statusColor),
                      borderRadius: AppRadius.brFull,
                    ),
                    child: Text(
                      activeJob.status.label,
                      style: context.typography.labelSm.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest,
                      borderRadius: AppRadius.brFull,
                    ),
                    child: Text(
                      'Available',
                      style: context.typography.labelSm.copyWith(
                        color: muted,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
            ],
            ),
            const Divider(height: 24),
            if (isOccupied) ...[
              Text(
                activeJob.vehicleNumber.isNotEmpty ? activeJob.vehicleNumber : 'No Plate',
                style: context.typography.titleSm.copyWith(
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                activeJob.vehicleModel.isNotEmpty ? activeJob.vehicleModel : 'Unknown Vehicle',
                style: context.typography.bodyMd.copyWith(color: muted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: muted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      activeJob.technician.isNotEmpty ? activeJob.technician : 'Unassigned',
                      style: context.typography.labelSm.copyWith(color: muted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (queueCount > 0) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      '+$queueCount in queue',
                      style: context.typography.labelSm.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: colors.primary,
                      size: 20,
                    ),
                  ],
                ),
                if (_isExpanded) ...[
                  const Divider(height: 16),
                  Text(
                    'Queue List',
                    style: context.typography.titleSm.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...widget.jobs.skip(1).map((job) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
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
                    ),
                  )),
                ],
              ]
            ] else ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: Text(
                    'No vehicle\nassigned',
                    textAlign: TextAlign.center,
                    style: context.typography.bodyMd.copyWith(
                      color: muted.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        ),
      ),
    );
  }
}

