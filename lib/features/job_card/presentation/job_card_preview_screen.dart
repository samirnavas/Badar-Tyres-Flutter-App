import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/job.dart';
import '../../../core/repositories/job_repository.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/red_button.dart';
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
  late JobStatusController _controller;

  static const _pauseReasons = [
    'Waiting for parts',
    'Customer approval needed',
    'Bay unavailable',
    'Technical issue',
  ];

  @override
  void initState() {
    super.initState();
    _controller = JobStatusController(initialJob: widget.job, repository: _repository);
  }

  @override
  void dispose() {
    _controller.dispose();
    _repository.dispose();
    super.dispose();
  }

  void _showDbError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Failed to update database. Please check connection.'),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _handlePause() async {
    if (_controller.isLoading) return;

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

    try {
      await _controller.pauseJob(reason);
    } catch (_) {
      if (!mounted) return;
      _showDbError();
    }
  }

  Future<void> _showAddEstimateDialog() async {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.colors.surface,
        title: Text('Add to Estimate', style: context.typography.titleSm),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                controller: titleController,
                hint: 'Service / Part name',
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: amountController,
                hint: 'Amount (e.g. 50.00)',
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Required';
                  if (double.tryParse(val) == null) return 'Invalid number';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: TextStyle(color: context.colors.onSurfaceVariant)),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() == true) {
                final service = JobService(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: titleController.text,
                  description: 'Added by technician',
                  amount: double.parse(amountController.text),
                );
                _controller.addEstimate(service);
                Navigator.of(context).pop();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final job = _controller.job;
        final isLoading = _controller.isLoading;

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
              'Job ',
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
              _VehicleHeader(job: job),
              const SizedBox(height: AppSpacing.stackMd),
              _ActionSection(
                job: job,
                isLoading: isLoading,
                onStart: () => _controller.startJob(),
                onPause: _handlePause,
                onComplete: () => _controller.completeJob(),
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
                isLoading: isLoading,
                onStepToggle: (step, val) => _controller.toggleStep(step, val ?? false),
              ),
              const SizedBox(height: AppSpacing.stackLg),
              _EstimatesSection(job: job, onAddEstimate: _showAddEstimateDialog),
              const SizedBox(height: AppSpacing.stackLg),
              _TechnicianNotesSection(
                initialNotes: job.technicianNotes,
                onNotesChanged: _controller.updateNotes,
              ),
              if (job.history.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.stackLg),
                _HistorySection(history: job.history),
              ],
            ],
          ),
        );
      },
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
      return RedButton(
        label: job.status == JobStatus.onHold ? 'Resume Job' : 'Start Job',
        icon: Icons.play_arrow_rounded,
        isLoading: isLoading,
        onPressed: onStart,
      );
    }

    if (job.status == JobStatus.inProgress) {
      return Row(
        children: [
          Expanded(
            child: RedButton.outlined(
              label: 'Pause',
              icon: Icons.pause_rounded,
              isLoading: isLoading,
              onPressed: onPause,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RedButton(
              label: 'Complete Job',
              icon: Icons.check_rounded,
              isLoading: isLoading,
              onPressed: onComplete,
            ),
          ),
        ],
      );
    }

    if (job.status == JobStatus.completed) {
      final color = AppStatusColors.completed;
      return Container(
        height: 52,
        width: double.infinity,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color),
          borderRadius: AppRadius.brBase,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_rounded, color: color, size: 24),
            const SizedBox(width: 8),
            Text(
              'JOB COMPLETED',
              style: context.typography.titleSm.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
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

class _EstimatesSection extends StatelessWidget {
  const _EstimatesSection({required this.job, required this.onAddEstimate});

  final Job job;
  final VoidCallback onAddEstimate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Additional Estimates',
              style: context.typography.titleSm.copyWith(
                fontSize: 18,
                color: context.colors.onSurface,
              ),
            ),
            TextButton.icon(
              onPressed: onAddEstimate,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.stackSm),
        if (job.estimates.isEmpty)
          Text(
            'No additional estimates added.',
            style: context.typography.bodyMd.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          )
        else
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.brLg,
              side: BorderSide(color: context.colors.outlineVariant),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: job.estimates.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                thickness: 1,
                color: context.colors.outlineVariant.withValues(alpha: 0.8),
              ),
              itemBuilder: (context, index) {
                final est = job.estimates[index];
                return ListTile(
                  title: Text(est.name, style: context.typography.bodyMd.copyWith(fontWeight: FontWeight.w600)),
                  trailing: Text('\$${est.amount.toStringAsFixed(2)}', style: context.typography.bodyMd),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _TechnicianNotesSection extends StatefulWidget {
  const _TechnicianNotesSection({required this.initialNotes, required this.onNotesChanged});

  final String initialNotes;
  final ValueChanged<String> onNotesChanged;

  @override
  State<_TechnicianNotesSection> createState() => _TechnicianNotesSectionState();
}

class _TechnicianNotesSectionState extends State<_TechnicianNotesSection> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNotes);
  }

  @override
  void didUpdateWidget(_TechnicianNotesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialNotes != oldWidget.initialNotes && _controller.text != widget.initialNotes) {
      _controller.text = widget.initialNotes;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Internal Technician Notes',
          style: context.typography.titleSm.copyWith(
            fontSize: 18,
            color: context.colors.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.gutter),
        CustomTextField(
          controller: _controller,
          hint: 'Type or dictate internal memos here...',
          minLines: 3,
          maxLines: 6,
          onChanged: widget.onNotesChanged,
        ),
      ],
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
                  ':'
                  '';
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
