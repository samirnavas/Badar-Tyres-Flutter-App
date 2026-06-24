import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/job.dart';
import '../../../core/repositories/job_repository.dart';
import '../../../core/theme/theme.dart';
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

  static const _pauseReasons = [
    'Waiting for parts',
    'Customer approval needed',
    'Bay unavailable',
    'Technical issue',
  ];

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

  Future<void> _handleStart() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    try {
      await _repository.updateJobStatus(_job.id, JobStatus.inProgress);
      if (!mounted) return;
      setState(() => _job = _job.copyWith(status: JobStatus.inProgress));
      _showSuccess('Job started successfully.');
    } catch (_) {
      if (!mounted) return;
      _showDbError();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handlePause() async {
    if (_isLoading) return;

    final reason = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        backgroundColor: context.colors.surface,
        title: Text(
          'Pause job',
          style: context.typography.titleSm.copyWith(
            color: context.colors.onSurface,
          ),
        ),
        children: [
          for (final reason in _pauseReasons)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(reason),
              child: Text(
                reason,
                style: context.typography.bodyMd.copyWith(
                  color: context.colors.onSurface,
                ),
              ),
            ),
        ],
      ),
    );

    if (reason == null) return;

    setState(() => _isLoading = true);
    try {
      await _repository.updateJobStatus(
        _job.id,
        JobStatus.onHold,
        pauseReason: reason,
      );
      if (!mounted) return;
      setState(() => _job = _job.copyWith(status: JobStatus.onHold));
      _showSuccess('Job paused successfully.');
    } catch (_) {
      if (!mounted) return;
      _showDbError();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleComplete() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    try {
      await _repository.updateJobStatus(_job.id, JobStatus.completed);
      if (!mounted) return;
      setState(() => _job = _job.copyWith(status: JobStatus.completed));
      _showSuccess('Job marked as complete.');
    } catch (_) {
      if (!mounted) return;
      _showDbError();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleStepToggle(JobStep step, bool? isCompleted) async {
    if (isCompleted == null || isCompleted == step.isCompleted || _isLoading) {
      return;
    }

    final previousSteps = _job.steps;
    final completedAt = isCompleted ? DateTime.now() : null;
    final updatedSteps = _job.steps
        .map(
          (item) => item.id == step.id
              ? item.copyWith(
                  isCompleted: isCompleted,
                  completedAt: completedAt,
                  clearCompletedAt: !isCompleted,
                )
              : item,
        )
        .toList();

    setState(() {
      _isLoading = true;
      _job = _job.copyWith(steps: updatedSteps);
    });

    try {
      await _repository.toggleJobStep(_job.id, step.id, isCompleted);
    } catch (_) {
      if (!mounted) return;
      setState(() => _job = _job.copyWith(steps: previousSteps));
      _showDbError();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showDbError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Failed to update database. Please check connection.'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppStatusColors.completed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.surface,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        foregroundColor: context.colors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Job ${_job.jobNumber}',
          style: context.typography.titleSm.copyWith(
            color: context.colors.onSurface,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.containerPadding,
          AppSpacing.stackMd,
          AppSpacing.containerPadding,
          AppSpacing.stackLg,
        ),
        children: [
          _VehicleHeader(job: _job),
          const SizedBox(height: AppSpacing.stackMd),
          _ActionSection(
            job: _job,
            isLoading: _isLoading,
            onStart: _handleStart,
            onPause: _handlePause,
            onComplete: _handleComplete,
          ),
          if (_job.status == JobStatus.inProgress) ...[
            const SizedBox(height: AppSpacing.stackMd),
            _InspectionButton(job: _job),
          ],
          const SizedBox(height: AppSpacing.stackMd),
          Text(
            'Checklist',
            style: context.typography.titleSm.copyWith(
              fontSize: 18,
              color: context.colors.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.gutter),
          _StepsChecklist(
            steps: _job.steps,
            isLoading: _isLoading,
            onStepToggle: _handleStepToggle,
          ),
          if (_job.history.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.stackMd),
            _HistorySection(history: _job.history),
          ],
        ],
      ),
    );
  }
}

class _VehicleHeader extends StatelessWidget {
  const _VehicleHeader({required this.job});

  final Job job;

  Future<void> _callCustomer(BuildContext context) async {
    final phone = job.mobile.trim();
    if (phone.isEmpty) return;

    final uri = Uri(scheme: 'tel', path: phone);
    if (!await canLaunchUrl(uri)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open the phone dialer')),
        );
      }
      return;
    }
    await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final model = job.vehicleModel.isNotEmpty
        ? job.vehicleModel
        : (job.vehicle?.vehicleModel ?? 'Unknown Vehicle');
    final registration = job.vehicleNumber.isNotEmpty
        ? job.vehicleNumber
        : (job.vehicle?.vehicleNumber ?? 'N/A');

    return Card(
      elevation: 0,
      color: context.colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.brLg,
        side: BorderSide(color: context.colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.stackMd,
          vertical: AppSpacing.gutter,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              model,
              style: context.typography.titleSm.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                height: 1.2,
                color: context.colors.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.directions_car_rounded,
                  size: 18,
                  color: context.colors.primary,
                ),
                const SizedBox(width: 6),
                _LicensePlate(registration: registration),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    job.customerName.isNotEmpty
                        ? job.customerName
                        : 'Customer',
                    style: context.typography.bodyMd.copyWith(
                      fontWeight: FontWeight.w500,
                      color: context.colors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (job.mobile.trim().isNotEmpty)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    tooltip: 'Call ${job.mobile}',
                    icon: Icon(
                      Icons.phone_in_talk_rounded,
                      size: 22,
                      color: context.colors.primary,
                    ),
                    onPressed: () => _callCustomer(context),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LicensePlate extends StatelessWidget {
  const _LicensePlate({required this.registration});

  final String registration;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: context.colors.outline,
          width: 1.5,
        ),
      ),
      child: Text(
        registration.toUpperCase(),
        style: context.typography.labelSm.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.4,
          color: context.colors.onSurface,
        ),
      ),
    );
  }
}

class _ActionSection extends StatelessWidget {
  const _ActionSection({
    required this.job,
    required this.isLoading,
    required this.onStart,
    required this.onPause,
    required this.onComplete,
  });

  final Job job;
  final bool isLoading;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    if (job.status == JobStatus.pending || job.status == JobStatus.onHold) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: isLoading ? null : onStart,
              child: isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: context.colors.onPrimary,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.play_arrow_rounded, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          job.status == JobStatus.pending
                              ? 'START JOB'
                              : 'RESUME JOB',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      );
    }

    if (job.status == JobStatus.inProgress) {
      return Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.pause_rounded, size: 22),
                label: const Text(
                  'PAUSE',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.colors.onSurface,
                  side: BorderSide(color: context.colors.outline),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.brLg,
                  ),
                ),
                onPressed: isLoading ? null : onPause,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.gutter),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: isLoading ? null : onComplete,
                style: FilledButton.styleFrom(
                  backgroundColor: AppStatusColors.running,
                  foregroundColor: context.colors.onPrimary,
                  elevation: 0,
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.brLg,
                  ),
                ),
                child: isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: context.colors.onPrimary,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_rounded, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'COMPLETE',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}

class _InspectionButton extends StatelessWidget {
  const _InspectionButton({required this.job});

  final Job job;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.checklist, size: 22),
        label: const Text(
          'PERFORM DIGITAL INSPECTION',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: context.colors.onSurface,
          side: BorderSide(color: context.colors.outline),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.brLg),
        ),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DviChecklistScreen(job: job),
            ),
          );
        },
      ),
    );
  }
}

class _StepsChecklist extends StatelessWidget {
  const _StepsChecklist({
    required this.steps,
    required this.isLoading,
    required this.onStepToggle,
  });

  final List<JobStep> steps;
  final bool isLoading;
  final void Function(JobStep step, bool? isCompleted) onStepToggle;

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) {
      return Text(
        'No steps assigned to this job.',
        style: context.typography.bodyMd.copyWith(
                    color: context.colors.onSurfaceVariant,
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.brLg,
        side: BorderSide(color: context.colors.outlineVariant),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: steps.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          thickness: 1,
          color: context.colors.outlineVariant.withValues(alpha: 0.8),
        ),
        itemBuilder: (context, index) {
          final step = steps[index];
          return SizedBox(
            height: 56,
            child: CheckboxListTile(
              value: step.isCompleted,
              onChanged: isLoading ? null : (value) => onStepToggle(step, value),
              title: Text(
                step.title,
                style: context.typography.bodyMd.copyWith(
                  decoration:
                      step.isCompleted ? TextDecoration.lineThrough : null,
                  color: step.isCompleted
                      ? context.colors.onSurfaceVariant
                      : context.colors.onSurface,
                ),
              ),
              activeColor: context.colors.primary,
              checkColor: context.colors.onPrimary,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              visualDensity: VisualDensity.standard,
            ),
          );
        },
      ),
    );
  }
}

class _HistorySection extends StatelessWidget {
  const _HistorySection({required this.history});

  final List<JobHistoryEntry> history;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'History',
          style: context.typography.titleSm.copyWith(
            fontSize: 18,
            color: context.colors.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.gutter),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.brLg,
            side: BorderSide(color: context.colors.outlineVariant),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: history.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: context.colors.outlineVariant.withValues(alpha: 0.8),
            ),
            itemBuilder: (context, index) {
              final entry = history[index];
              final time =
                  '${entry.timestamp.hour.toString().padLeft(2, '0')}:'
                  '${entry.timestamp.minute.toString().padLeft(2, '0')}';
              return ListTile(
                minVerticalPadding: 12,
                leading: Icon(
                  Icons.history,
                  color: context.colors.onSurfaceVariant,
                  size: 20,
                ),
                title: Text(
                  entry.action,
                  style: context.typography.bodyMd.copyWith(
                    color: context.colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: entry.note == null
                    ? null
                    : Text(
                        entry.note!,
                        style: context.typography.bodyMd.copyWith(
                          fontSize: 13,
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                trailing: Text(
                  time,
                  style: context.typography.labelSm.copyWith(
                    letterSpacing: 0,
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
