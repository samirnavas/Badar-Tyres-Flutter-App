import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Summary metric card for profile analytics grids.
class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
  });

  const MetricCard.totalJobs({
    super.key,
    required this.value,
    this.label = 'Total Jobs',
  })  : icon = Icons.assignment_outlined,
        accentColor = AppStatusColors.total;

  const MetricCard.running({
    super.key,
    required this.value,
    this.label = 'Running',
  })  : icon = Icons.play_circle_outline,
        accentColor = AppStatusColors.running;

  const MetricCard.completed({
    super.key,
    required this.value,
    this.label = 'Completed',
  })  : icon = Icons.check_circle_outline,
        accentColor = AppStatusColors.completed;

  const MetricCard.delayed({
    super.key,
    required this.value,
    this.label = 'Delayed',
  })  : icon = Icons.schedule,
        accentColor = AppStatusColors.delayed;

  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.brLg,
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.stackMd),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppStatusColors.tint(accentColor),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: accentColor, size: 20),
            ),
            const SizedBox(width: AppSpacing.gutter),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.typography.labelSm.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.stackSm),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.typography.titleSm.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
