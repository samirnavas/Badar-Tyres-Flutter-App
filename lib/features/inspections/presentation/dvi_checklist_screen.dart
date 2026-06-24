import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
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
  bool _isCompleting = false;

  late List<InspectionItem> _items;
  Timer? _notesDebounce;

  bool get _allItemsChecked => _items.every((item) => item.isChecked);

  @override
  void initState() {
    super.initState();
    _items = _defaultItems();
    _loadExistingInspection();
  }

  List<InspectionItem> _defaultItems() {
    return [
      'Front Tyres',
      'Rear Tyres',
      'Brake Pads',
      'Battery',
      'Oil Level',
    ]
        .map(
          (system) => InspectionItem(
            system: system,
            condition: 'Pending',
            notes: '',
          ),
        )
        .toList();
  }

  String get _vehicleId =>
      widget.job.vehicleId?.isNotEmpty == true
          ? widget.job.vehicleId!
          : (widget.job.vehicle?.id ?? '');

  Future<void> _loadExistingInspection() async {
    final existing =
        await _repository.fetchInspectionForJob(widget.job.id);
    if (!mounted || existing == null || existing.items.isEmpty) return;
    setState(() => _items = existing.items);
  }

  @override
  void dispose() {
    _notesDebounce?.cancel();
    super.dispose();
  }

  InspectionReport _buildReport({required String status}) {
    return InspectionReport(
      jobId: widget.job.id,
      technicianId: widget.job.technicianId ?? '',
      vehicleId: _vehicleId,
      status: status,
      items: _items,
    );
  }

  void _autoSaveDraft() {
    if (_vehicleId.isEmpty) {
      if (kDebugMode) {
        debugPrint('Inspection auto-save skipped: missing vehicle id');
      }
      return;
    }

    final report = _buildReport(status: 'Draft');
    unawaited(
      _repository.saveInspectionReport(report.jobId, report).catchError((Object e) {
        if (kDebugMode) {
          debugPrint('Silent inspection auto-save failed: $e');
        }
      }),
    );
  }

  void _applyItemUpdate(int index, InspectionItem updated) {
    setState(() => _items[index] = updated);
    _autoSaveDraft();
  }

  void _toggleChecked(int index, bool? value) {
    if (value == null) return;
    _applyItemUpdate(index, _items[index].copyWith(isChecked: value));
  }

  void _updateCondition(int index, String condition) {
    _applyItemUpdate(
      index,
      _items[index].copyWith(
        condition: condition,
        isChecked: true,
      ),
    );
  }

  void _updateNotes(int index, String notes) {
    setState(() => _items[index] = _items[index].copyWith(notes: notes));
    _notesDebounce?.cancel();
    _notesDebounce = Timer(const Duration(milliseconds: 500), _autoSaveDraft);
  }

  Future<void> _captureImage(int index) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 50,
      );
      if (image != null) {
        final updatedUrls = List<String>.from(_items[index].photoUrls)
          ..add(image.path);
        _applyItemUpdate(
          index,
          _items[index].copyWith(
            photoUrls: updatedUrls,
            isChecked: true,
          ),
        );
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
    final updatedUrls = List<String>.from(_items[itemIndex].photoUrls)
      ..removeAt(photoIndex);
    _applyItemUpdate(
      itemIndex,
      _items[itemIndex].copyWith(photoUrls: updatedUrls),
    );
  }

  Future<void> _completeInspection() async {
    if (!_allItemsChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please check every inspection item before completing.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_vehicleId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vehicle information is missing for this job.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isCompleting = true);

    final report = _buildReport(status: 'Submitted');

    try {
      await _repository.saveInspectionReport(report.jobId, report);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Inspection completed successfully.'),
            backgroundColor: AppStatusColors.completed,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update database. Please check connection.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCompleting = false);
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
          100.0,
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
              border: Border.all(
                color: item.isChecked
                    ? context.colors.primary.withValues(alpha: 0.4)
                    : context.colors.outlineVariant,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: item.isChecked,
                      onChanged: (value) => _toggleChecked(index, value),
                      activeColor: context.colors.primary,
                      checkColor: context.colors.onPrimary,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                    Expanded(
                      child: Text(
                        item.system,
                        style: context.typography.titleSm.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    if (item.condition != 'Pending')
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _conditionColor(item.condition)
                              .withValues(alpha: 0.15),
                          borderRadius: AppRadius.brFull,
                        ),
                        child: Text(
                          item.condition,
                          style: context.typography.labelSm.copyWith(
                            color: _conditionColor(item.condition),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.stackMd),
                Row(
                  children: [
                    Expanded(
                      child: _ConditionButton(
                        label: 'Good',
                        color: AppStatusColors.running,
                        isSelected: item.condition == 'Good',
                        onTap: () => _updateCondition(index, 'Good'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.stackSm),
                    Expanded(
                      child: _ConditionButton(
                        label: 'Monitor',
                        color: AppStatusColors.pending,
                        isSelected: item.condition == 'Monitor',
                        onTap: () => _updateCondition(index, 'Monitor'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.stackSm),
                    Expanded(
                      child: _ConditionButton(
                        label: 'Replace',
                        color: AppStatusColors.delayed,
                        isSelected: item.condition == 'Replace',
                        onTap: () => _updateCondition(index, 'Replace'),
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
                        color: context.colors.primaryContainer
                            .withValues(alpha: 0.1),
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
                          margin:
                              const EdgeInsets.only(right: AppSpacing.stackSm),
                          decoration: BoxDecoration(
                            borderRadius: AppRadius.brBase,
                            border: Border.all(
                              color: context.colors.outlineVariant,
                            ),
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
                                  icon: Icon(
                                    Icons.cancel,
                                    color: context.colors.onPrimary,
                                    size: 20,
                                  ),
                                  padding: EdgeInsets.zero,
                                  onPressed: () =>
                                      _removeImage(index, photoIndex),
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
              color: context.colors.scrim.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton(
            onPressed: (_isCompleting || !_allItemsChecked)
                ? null
                : _completeInspection,
            child: _isCompleting
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: context.colors.onPrimary,
                    ),
                  )
                : Text(
                    _allItemsChecked
                        ? 'Complete Inspection'
                        : 'Complete Inspection (${_items.where((i) => i.isChecked).length}/${_items.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Color _conditionColor(String condition) => switch (condition) {
        'Good' => AppStatusColors.running,
        'Monitor' => AppStatusColors.pending,
        'Replace' => AppStatusColors.delayed,
        _ => context.colors.onSurfaceVariant,
      };
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
          color: isSelected ? color.withValues(alpha: 0.15) : context.colors.surface,
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
