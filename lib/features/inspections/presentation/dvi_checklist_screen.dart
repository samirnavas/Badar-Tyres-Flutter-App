import 'package:flutter/material.dart';

import '../../../core/models/inspection.dart';
import '../../../core/models/job.dart';
import '../../../core/repositories/inspection_repository.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/custom_text_field.dart';

class DviChecklistScreen extends StatefulWidget {
  final Job job;

  const DviChecklistScreen({super.key, required this.job});

  @override
  State<DviChecklistScreen> createState() => _DviChecklistScreenState();
}

class _DviChecklistScreenState extends State<DviChecklistScreen> {
  final InspectionRepository _repository = InspectionRepository();
  bool _isSubmitting = false;

  late List<InspectionItem> _items;

  @override
  void initState() {
    super.initState();
    // Initialize default items
    _items = [
      'Front Tyres',
      'Rear Tyres',
      'Brake Pads',
      'Battery',
      'Oil Level',
    ].map((system) => InspectionItem(
          system: system,
          condition: 'Green',
          notes: '',
        )).toList();
  }

  void _updateCondition(int index, String condition) {
    setState(() {
      _items[index] = InspectionItem(
        system: _items[index].system,
        condition: condition,
        notes: _items[index].notes,
        photoUrl: _items[index].photoUrl,
      );
    });
  }

  void _updateNotes(int index, String notes) {
    _items[index] = InspectionItem(
      system: _items[index].system,
      condition: _items[index].condition,
      notes: notes,
      photoUrl: _items[index].photoUrl,
    );
  }

  Future<void> _submitReport() async {
    setState(() => _isSubmitting = true);

    final report = InspectionReport(
      jobId: widget.job.id,
      technicianId: widget.job.technician, // using technician name/id available from Job
      vehicleId: widget.job.vehicleNumber, // simplified mapping
      status: 'Submitted',
      items: _items,
    );

    try {
      final success = await _repository.submitInspection(report);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inspection report submitted successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
        title: const Text('Vehicle Inspection'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.containerPadding,
          AppSpacing.stackMd,
          AppSpacing.containerPadding,
          100.0, // Space for bottom button
        ),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          return Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.stackLg),
            padding: const EdgeInsets.all(AppSpacing.stackMd),
            decoration: BoxDecoration(
              color: context.colors.surfaceContainerLow,
              borderRadius: AppRadius.brLg,
              border: Border.all(color: context.colors.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.system,
                  style: context.typography.titleSm.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: AppSpacing.stackMd),
                Row(
                  children: [
                    Expanded(
                      child: _ConditionButton(
                        label: 'Good',
                        color: Colors.green,
                        isSelected: item.condition == 'Green',
                        onTap: () => _updateCondition(index, 'Green'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.stackSm),
                    Expanded(
                      child: _ConditionButton(
                        label: 'Monitor',
                        color: Colors.orange,
                        isSelected: item.condition == 'Yellow',
                        onTap: () => _updateCondition(index, 'Yellow'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.stackSm),
                    Expanded(
                      child: _ConditionButton(
                        label: 'Action',
                        color: Colors.red,
                        isSelected: item.condition == 'Red',
                        onTap: () => _updateCondition(index, 'Red'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.stackMd),
                CustomTextField(
                  hint: 'Add Notes (Optional)',
                  onChanged: (val) => _updateNotes(index, val),
                  minLines: 1,
                  maxLines: 3,
                ),
              ],
            ),
          );
        },
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(AppSpacing.containerPadding),
        decoration: BoxDecoration(
          color: context.colors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.primaryContainer,
              foregroundColor: context.colors.onPrimaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.brBase,
              ),
            ),
            onPressed: _isSubmitting ? null : _submitReport,
            child: _isSubmitting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Submit Report',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ),
    );
  }
}

class _ConditionButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ConditionButton({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : context.colors.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: context.typography.labelSm.copyWith(
            color: isSelected ? color : context.colors.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
