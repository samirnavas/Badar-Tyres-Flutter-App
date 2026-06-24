import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Compact dashboard metric shown as a single-line pill chip.
class MetricChip extends StatelessWidget {
  const MetricChip({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
    this.isActive = false,
    this.isDelayed = false,
    this.onTap,
  });

  const MetricChip.totalJobs({
    super.key,
    required this.value,
    this.label = 'Total Jobs',
    this.isActive = false,
    this.onTap,
  })  : icon = Icons.assignment_outlined,
        accentColor = AppStatusColors.total,
        isDelayed = false;

  const MetricChip.running({
    super.key,
    required this.value,
    this.label = 'Running',
    this.isActive = false,
    this.onTap,
  })  : icon = Icons.play_circle_outline,
        accentColor = AppStatusColors.running,
        isDelayed = false;

  const MetricChip.completed({
    super.key,
    required this.value,
    this.label = 'Completed',
    this.isActive = false,
    this.onTap,
  })  : icon = Icons.check_circle_outline,
        accentColor = AppStatusColors.completed,
        isDelayed = false;

  const MetricChip.delayed({
    super.key,
    required this.value,
    this.label = 'Delayed',
    this.isActive = false,
    this.onTap,
  })  : icon = Icons.schedule,
        accentColor = AppStatusColors.delayed,
        isDelayed = true;

  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;
  final bool isActive;
  final bool isDelayed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final foreground = colors.onSurfaceVariant;

    final background = isActive
        ? AppStatusColors.tint(accentColor)
        : isDelayed
            ? AppStatusColors.tint(AppStatusColors.delayed)
            : colors.surfaceContainerLow;

    return ActionChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foreground),
          const SizedBox(width: AppSpacing.stackSm),
          Text(
            '$label: $value',
            style: context.typography.bodyMd.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: foreground,
              height: 1.2,
            ),
          ),
        ],
      ),
      onPressed: onTap,
      backgroundColor: background,
      elevation: 0,
      pressElevation: 0,
      side: BorderSide.none,
      shape: const StadiumBorder(),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
    );
  }
}
