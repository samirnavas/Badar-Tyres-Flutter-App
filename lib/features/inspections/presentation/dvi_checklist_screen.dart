import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
  final ImagePicker _picker = ImagePicker();
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
        photoUrls: _items[index].photoUrls,
      );
    });
  }

  void _updateNotes(int index, String notes) {
    _items[index] = InspectionItem(
      system: _items[index].system,
      condition: _items[index].condition,
      notes: notes,
      photoUrls: _items[index].photoUrls,
    );
  }

  Future<void> _captureImage(int index) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 50,
      );
      if (image != null) {
        setState(() {
          final updatedUrls = List<String>.from(_items[index].photoUrls)..add(image.path);
          _items[index] = InspectionItem(
            system: _items[index].system,
            condition: _items[index].condition,
            notes: _items[index].notes,
            photoUrls: updatedUrls,
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to capture image: $e')),
        );
      }
    }
  }

  void _removeImage(int itemIndex, int photoIndex) {
    setState(() {
      final updatedUrls = List<String>.from(_items[itemIndex].photoUrls)..removeAt(photoIndex);
      _items[itemIndex] = InspectionItem(
        system: _items[itemIndex].system,
        condition: _items[itemIndex].condition,
        notes: _items[itemIndex].notes,
        photoUrls: updatedUrls,
      );
    });
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: CustomTextField(
                        hint: 'Add Notes (Optional)',
                        onChanged: (val) => _updateNotes(index, val),
                        minLines: 1,
                        maxLines: 3,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.stackSm),
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: context.colors.primaryContainer.withValues(alpha: 0.1),
                        borderRadius: AppRadius.brBase,
                      ),
                      child: IconButton(
                        onPressed: () => _captureImage(index),
                        icon: const Icon(Icons.camera_alt),
                        color: context.colors.primaryContainer,
                        iconSize: 24,
                        tooltip: 'Take Photo',
                      ),
                    ),
                  ],
                ),
                if (item.photoUrls.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.stackSm),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: item.photoUrls.length,
                      itemBuilder: (context, photoIndex) {
                        return Container(
                          width: 80,
                          margin: const EdgeInsets.only(right: AppSpacing.stackSm),
                          decoration: BoxDecoration(
                            borderRadius: AppRadius.brBase,
                            border: Border.all(color: context.colors.outlineVariant),
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: AppRadius.brBase,
                                child: Image.file(
                                  File(item.photoUrls[photoIndex]),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: -8,
                                right: -8,
                                child: IconButton(
                                  icon: const Icon(Icons.cancel, color: Colors.white, size: 20),
                                  padding: EdgeInsets.zero,
                                  onPressed: () => _removeImage(index, photoIndex),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
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
