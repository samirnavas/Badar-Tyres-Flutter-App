import 'package:flutter/material.dart';

import '../../../core/models/job.dart';
import '../../../core/repositories/job_repository.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/job_list_tile.dart';
import '../../inspections/presentation/dvi_checklist_screen.dart';
import 'job_status_controller.dart';

class JobExecutionScreen extends StatefulWidget {
  const JobExecutionScreen({super.key, required this.job});

  final Job job;

  @override
  State<JobExecutionScreen> createState() => _JobExecutionScreenState();
}

class _JobExecutionScreenState extends State<JobExecutionScreen> {
  final JobRepository _repository = JobRepository();
  late final JobStatusController _controller;

  @override
  void initState() {
    super.initState();
    _controller = JobStatusController(
      initialJob: widget.job,
      repository: _repository,
    );
    _controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _repository.dispose();
    super.dispose();
  }

  Future<void> _handleStart() async {
    try {
      if (_controller.job.status == JobStatus.onHold) {
        await _controller.resumeJob();
      } else {
        await _controller.startJob();
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Failed to start job: $e');
    }
  }

  Future<void> _handlePause() async {
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
          for (final reason in JobStatusController.pauseReasons)
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

    try {
      await _controller.pauseJob(reason);
    } catch (e) {
      if (!mounted) return;
      _showError('Failed to pause job: $e');
    }
  }

  Future<void> _handleComplete() async {
    try {
      await _controller.completeJob();
    } catch (e) {
      if (!mounted) return;
      _showError('Failed to complete job: $e');
    }
  }

  Future<void> _handleStepToggle(JobStep step, bool? isCompleted) async {
    if (isCompleted == null || isCompleted == step.isCompleted) return;

    try {
      await _controller.toggleStep(step, isCompleted);
    } catch (e) {
      if (!mounted) return;
      _showError('Failed to update step: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final job = _controller.job;

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
          'Job ${job.jobNumber}',
          style: context.typography.titleSm.copyWith(
            color: context.colors.onSurface,
          ),
        ),
        bottom: _controller.isLoading
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.containerPadding,
          AppSpacing.stackMd,
          AppSpacing.containerPadding,
          AppSpacing.stackLg,
        ),
        children: [
          _VehicleHeader(job: job),
          const SizedBox(height: AppSpacing.stackMd),
          _ActionSection(
            job: job,
            formattedElapsed: _controller.formattedElapsed,
            onStart: _handleStart,
            onPause: _handlePause,
            onComplete: _handleComplete,
          ),
          if (job.status == JobStatus.inProgress) ...[
            const SizedBox(height: AppSpacing.stackMd),
            _InspectionButton(job: job),
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
            steps: job.steps,
            onStepToggle: _handleStepToggle,
          ),
          if (job.history.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.stackMd),
            _HistorySection(history: job.history),
          ],
        ],
      ),
    );
  }
}

class _VehicleHeader extends StatelessWidget {
  const _VehicleHeader({required this.job});

  final Job job;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.brLg,
        side: BorderSide(color: context.colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.stackMd),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  job.vehicleModel.isNotEmpty
                      ? job.vehicleModel
                      : 'Unknown Vehicle',
                  style: context.typography.titleSm.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.colors.onSurface,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppStatusColors.tint(job.status.color),
                  borderRadius: AppRadius.brFull,
                ),
                child: Text(
                  job.status.label,
                  style: context.typography.labelSm.copyWith(
                    color: job.status.color,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackSm),
          Row(
            children: [
              Icon(
                Icons.directions_car_rounded,
                size: 22,
                color: context.colors.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                job.vehicleNumber,
                style: context.typography.titleSm.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: context.colors.onSurface,
                ),
              ),
            ],
          ),
          if (job.customerName.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.gutter),
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 16,
                  color: context.colors.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  job.customerName,
                  style: context.typography.bodyMd.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ],
        ),
      ),
    );
  }
}

class _ActionSection extends StatelessWidget {
  const _ActionSection({
    required this.job,
    required this.formattedElapsed,
    required this.onStart,
    required this.onPause,
    required this.onComplete,
  });

  final Job job;
  final String formattedElapsed;
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
            child: FilledButton.icon(
              icon: const Icon(Icons.play_arrow_rounded, size: 24),
              label: Text(
                job.status == JobStatus.pending ? 'START JOB' : 'RESUME JOB',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              onPressed: onStart,
            ),
          ),
        ],
      );
    }

    if (job.status == JobStatus.inProgress) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.brLg,
              side: BorderSide(color: context.colors.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.stackMd,
                vertical: AppSpacing.gutter,
              ),
              child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 20,
                  color: context.colors.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  formattedElapsed,
                  style: context.typography.titleSm.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: context.colors.onSurface,
                  ),
                ),
              ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.gutter),
          Row(
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
                    onPressed: onPause,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.gutter),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.check_rounded, size: 22),
                    label: const Text(
                      'COMPLETE',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppStatusColors.running,
                      foregroundColor: context.colors.onPrimary,
                      elevation: 0,
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.brLg,
                      ),
                    ),
                    onPressed: onComplete,
                  ),
                ),
              ),
            ],
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
    required this.onStepToggle,
  });

  final List<JobStep> steps;
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
              onChanged: (value) => onStepToggle(step, value),
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
