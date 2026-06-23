import 'package:flutter/material.dart';

import '../../../core/models/job.dart';
import '../../../core/repositories/job_repository.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/job_list_tile.dart';
import '../../inspections/presentation/dvi_checklist_screen.dart';

class JobExecutionScreen extends StatefulWidget {
  const JobExecutionScreen({super.key, required this.job});

  final Job job;

  @override
  State<JobExecutionScreen> createState() => _JobExecutionScreenState();
}

class _JobExecutionScreenState extends State<JobExecutionScreen> {
  final JobRepository _repository = JobRepository();
  late Job _job;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _job = widget.job;
  }

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(JobStatus newStatus) async {
    if (_job.status == newStatus) return;

    setState(() => _isLoading = true);
    try {
      final statusString = newStatus.name; // Uses enum name e.g. "awaiting_parts"
      await _repository.updateJobStatus(_job.id, statusString);
      setState(() {
        _job = Job(
          id: _job.id,
          jobNumber: _job.jobNumber,
          customerName: _job.customerName,
          mobile: _job.mobile,
          vehicleModel: _job.vehicleModel,
          vehicleNumber: _job.vehicleNumber,
          status: newStatus,
          time: _job.time,
          date: _job.date,
          technician: _job.technician,
          startTime: _job.startTime,
          expectedEnd: _job.expectedEnd,
          actualEnd: _job.actualEnd,
          delay: _job.delay,
          remarks: _job.remarks,
          services: _job.services,
          subTotal: _job.subTotal,
          gst: _job.gst,
          grandTotal: _job.grandTotal,
        );
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update status: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleService(JobService service, bool? isCompleted) async {
    if (isCompleted == null || isCompleted == service.isCompleted) return;

    setState(() => _isLoading = true);
    try {
      await _repository.updateServiceStatus(service.id, isCompleted);
      
      final updatedServices = _job.services.map((s) {
        if (s.id == service.id) {
          return JobService(
            id: s.id,
            name: s.name,
            description: s.description,
            amount: s.amount,
            isCompleted: isCompleted,
          );
        }
        return s;
      }).toList();

      setState(() {
        _job = Job(
          id: _job.id,
          jobNumber: _job.jobNumber,
          customerName: _job.customerName,
          mobile: _job.mobile,
          vehicleModel: _job.vehicleModel,
          vehicleNumber: _job.vehicleNumber,
          status: _job.status,
          time: _job.time,
          date: _job.date,
          technician: _job.technician,
          startTime: _job.startTime,
          expectedEnd: _job.expectedEnd,
          actualEnd: _job.actualEnd,
          delay: _job.delay,
          remarks: _job.remarks,
          services: updatedServices,
          subTotal: _job.subTotal,
          gst: _job.gst,
          grandTotal: _job.grandTotal,
        );
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update service: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _flagIssue() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Flag Issue'),
        content: const Text('Are you sure you want to block this job? This will notify the admin.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.errorContainer,
              foregroundColor: context.colors.onErrorContainer,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Block Job'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _updateStatus(JobStatus.blocked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Job ${_job.jobNumber}'),
        bottom: _isLoading
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(
                  minHeight: 2,
                  backgroundColor: Colors.transparent,
                  color: context.colors.primary,
                ),
              )
            : null,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.containerPadding,
              AppSpacing.stackLg,
              AppSpacing.containerPadding,
              180.0, // Space for the bottom block buttons
            ),
            children: [
              _buildVehicleHeader(context),
              const SizedBox(height: AppSpacing.stackLg),
              _buildStatusToggles(context),
              const SizedBox(height: AppSpacing.stackLg),
              Text('Checklist', style: context.typography.titleSm.copyWith(fontSize: 18)),
              const SizedBox(height: AppSpacing.gutter),
              _buildChecklist(context),
            ],
          ),
          Positioned(
            left: AppSpacing.containerPadding,
            right: AppSpacing.containerPadding,
            bottom: 32,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_job.status == JobStatus.running) ...[
                  ElevatedButton.icon(
                    icon: const Icon(Icons.checklist),
                    label: const Text('PERFORM DIGITAL INSPECTION'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DviChecklistScreen(job: _job),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.stackMd),
                ],
                ElevatedButton.icon(
                  icon: const Icon(Icons.warning_amber_rounded),
                  label: const Text('FLAG ISSUE / BLOCKED'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.errorContainer,
                    foregroundColor: context.colors.onErrorContainer,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _job.status != JobStatus.blocked ? _flagIssue : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: context.colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _job.vehicleModel.isNotEmpty ? _job.vehicleModel : 'Unknown Vehicle',
                style: context.typography.headlineMd,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppStatusColors.tint(_job.status.color),
                  borderRadius: AppRadius.brFull,
                ),
                child: Text(
                  _job.status.label,
                  style: context.typography.labelSm.copyWith(
                    color: _job.status.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackSm),
          Row(
            children: [
              Icon(Icons.directions_car_outlined, size: 16, color: context.colors.secondary),
              const SizedBox(width: 6),
              Text(
                _job.vehicleNumber,
                style: context.typography.bodyMd.copyWith(color: context.colors.secondary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.gutter),
          Row(
            children: [
              Icon(Icons.person_outline, size: 16, color: context.colors.secondary),
              const SizedBox(width: 6),
              Text(
                _job.customerName,
                style: context.typography.bodyMd.copyWith(color: context.colors.secondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusToggles(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Status', style: context.typography.titleSm.copyWith(fontSize: 18)),
        const SizedBox(height: AppSpacing.gutter),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<JobStatus>(
            emptySelectionAllowed: false,
            multiSelectionEnabled: false,
            selected: {_job.status == JobStatus.blocked ? JobStatus.pending : _job.status},
            onSelectionChanged: (Set<JobStatus> newSelection) {
              _updateStatus(newSelection.first);
            },
            segments: const [
              ButtonSegment<JobStatus>(
                value: JobStatus.pending,
                label: Text('Pending'),
              ),
              ButtonSegment<JobStatus>(
                value: JobStatus.running,
                label: Text('In Progress'),
              ),
              ButtonSegment<JobStatus>(
                value: JobStatus.awaitingParts,
                label: Text('Awaiting Parts'),
              ),
              ButtonSegment<JobStatus>(
                value: JobStatus.completed,
                label: Text('Completed'),
              ),
            ],
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return context.colors.primaryContainer;
                }
                return context.colors.surfaceContainerHigh;
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return context.colors.onPrimaryContainer;
                }
                return context.colors.onSurfaceVariant;
              }),
              side: WidgetStatePropertyAll(
                BorderSide(color: context.colors.outlineVariant),
              ),
              shape: const WidgetStatePropertyAll(
                RoundedRectangleBorder(borderRadius: AppRadius.brBase),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChecklist(BuildContext context) {
    if (_job.services.isEmpty) {
      return Text(
        'No services assigned to this job.',
        style: context.typography.bodyMd.copyWith(color: context.colors.secondary),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: context.colors.outlineVariant),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _job.services.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          thickness: 1,
          color: context.colors.outlineVariant.withValues(alpha: 0.5),
        ),
        itemBuilder: (context, index) {
          final service = _job.services[index];
          return CheckboxListTile(
            value: service.isCompleted,
            onChanged: (val) => _toggleService(service, val),
            title: Text(
              service.name,
              style: context.typography.bodyMd.copyWith(
                decoration: service.isCompleted ? TextDecoration.lineThrough : null,
                color: service.isCompleted ? context.colors.secondary : context.colors.onSurface,
              ),
            ),
            subtitle: service.description.isNotEmpty
                ? Text(
                    service.description,
                    style: context.typography.bodyMd.copyWith(
                      fontSize: 13,
                      color: context.colors.secondary,
                    ),
                  )
                : null,
            activeColor: context.colors.primaryContainer,
            checkColor: context.colors.onPrimaryContainer,
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          );
        },
      ),
    );
  }
}
