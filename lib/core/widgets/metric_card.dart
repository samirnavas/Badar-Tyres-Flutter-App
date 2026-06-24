import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Dashboard metric summary using Material 3 [Card].
class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
    this.onTap,
  });

  const MetricCard.totalJobs({
    super.key,
    required this.value,
    this.label = 'Total Jobs',
    this.onTap,
  })  : icon = Icons.assignment_outlined,
        accentColor = AppStatusColors.total;

  const MetricCard.running({
    super.key,
    required this.value,
    this.label = 'Running',
    this.onTap,
  })  : icon = Icons.play_circle_outline,
        accentColor = AppStatusColors.running;

  const MetricCard.completed({
    super.key,
    required this.value,
    this.label = 'Completed',
    this.onTap,
  })  : icon = Icons.check_circle_outline,
        accentColor = AppStatusColors.completed;

  const MetricCard.delayed({
    super.key,
    required this.value,
    this.label = 'Delayed',
    this.onTap,
  })  : icon = Icons.schedule,
        accentColor = AppStatusColors.delayed;

  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.brLg,
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brLg,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.stackMd),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppStatusColors.tint(accentColor),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: accentColor, size: 22),
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
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 13,
                            height: 1.1,
                            color: colors.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.stackSm),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: accentColor,
                            fontWeight: FontWeight.w700,
                            height: 1.0,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
