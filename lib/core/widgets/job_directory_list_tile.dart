import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../theme/theme.dart';
import 'job_list_tile.dart';

/// Directory row for the global Jobs screen — shows shop-wide assignment.
class JobDirectoryListTile extends StatelessWidget {
  const JobDirectoryListTile({
    super.key,
    required this.jobNumber,
    required this.customerName,
    required this.vehicleModel,
    required this.vehicleNumber,
    required this.status,
    required this.time,
    required this.date,
    required this.technician,
    this.bayName,
    required this.startTime,
    required this.expectedEnd,
    this.actualEnd,
    this.delay,
    this.onTap,
    this.onStatusChange,
  });

  final String jobNumber;
  final String customerName;
  final String vehicleModel;
  final String vehicleNumber;
  final JobStatus status;
  final String time;
  final String date;
  final String technician;
  final String? bayName;
  final String startTime;
  final String expectedEnd;
  final String? actualEnd;
  final String? delay;
  final VoidCallback? onTap;
  final void Function(JobStatus)? onStatusChange;

  bool get _canQuickStart =>
      status == JobStatus.pending && onStatusChange != null;

  bool get _canMarkComplete =>
      status == JobStatus.inProgress && onStatusChange != null;

  String get _assignmentLabel {
    final tech = technician.trim();
    final bay = bayName?.trim();
    final hasTech = tech.isNotEmpty && tech != '-';
    final hasBay = bay != null && bay.isNotEmpty;

    if (hasTech && hasBay) return '$tech • $bay';
    if (hasTech) return tech;
    if (hasBay) return bay;
    return 'Unassigned';
  }

  @override
  Widget build(BuildContext context) {
    final card = _DirectoryJobCard(
      jobNumber: jobNumber,
      customerName: customerName,
      vehicleModel: vehicleModel,
      vehicleNumber: vehicleNumber,
      status: status,
      time: time,
      date: date,
      assignmentLabel: _assignmentLabel,
      delay: delay,
      onTap: onTap,
    );

    if (!_canQuickStart && !_canMarkComplete) return card;

    return Slidable(
      key: key ?? ValueKey(jobNumber),
      groupTag: 'jobs-directory',
      startActionPane: _canMarkComplete
          ? ActionPane(
              motion: const DrawerMotion(),
              extentRatio: 0.34,
              children: [
                SlidableAction(
                  onPressed: (context) {
                    Slidable.of(context)?.close();
                    onStatusChange!(JobStatus.completed);
                  },
                  backgroundColor: AppStatusColors.completed,
                  foregroundColor: Colors.white,
                  icon: Icons.check_circle_outline,
                  label: 'Mark Complete',
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ],
            )
          : null,
      endActionPane: _canQuickStart
          ? ActionPane(
              motion: const DrawerMotion(),
              extentRatio: 0.34,
              children: [
                SlidableAction(
                  onPressed: (context) {
                    Slidable.of(context)?.close();
                    onStatusChange!(JobStatus.inProgress);
                  },
                  backgroundColor: AppStatusColors.running,
                  foregroundColor: Colors.white,
                  icon: Icons.play_arrow_rounded,
                  label: 'Quick Start',
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
              ],
            )
          : null,
      child: card,
    );
  }
}

class _DirectoryJobCard extends StatelessWidget {
  const _DirectoryJobCard({
    required this.jobNumber,
    required this.customerName,
    required this.vehicleModel,
    required this.vehicleNumber,
    required this.status,
    required this.time,
    required this.date,
    required this.assignmentLabel,
    this.delay,
    this.onTap,
  });

  final String jobNumber;
  final String customerName;
  final String vehicleModel;
  final String vehicleNumber;
  final JobStatus status;
  final String time;
  final String date;
  final String assignmentLabel;
  final String? delay;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final muted = colors.onSurfaceVariant;
    final isDelayed = _isDelayedJob(status, delay);
    final regNum = vehicleNumber.trim();
    final registration =
        (regNum.toUpperCase() == 'N/A' || regNum.isEmpty) ? 'Unregistered' : regNum;

    return Material(
      elevation: 0,
      color: colors.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.brLg,
        side: BorderSide(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: isDelayed
              ? const Border(
                  left: BorderSide(color: AppStatusColors.delayed, width: 3),
                )
              : null,
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.stackMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      jobNumber,
                      style: context.typography.labelSm.copyWith(
                        letterSpacing: 0,
                        color: muted,
                      ),
                    ),
                    _StatusPill(status: status),
                  ],
                ),
                const SizedBox(height: AppSpacing.stackMd),
                Text(
                  registration,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.typography.titleSm.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    height: 1.2,
                  ),
                ),
                if (vehicleModel.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    vehicleModel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.typography.bodyMd.copyWith(color: muted),
                  ),
                ],
                if (customerName.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    customerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.typography.bodyMd.copyWith(color: muted),
                  ),
                ],
                const SizedBox(height: AppSpacing.stackMd),
                Row(
                  children: [
                    Icon(Icons.badge_outlined, size: 14, color: muted),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        assignmentLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.typography.labelSm.copyWith(
                          color: muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.base),
                    Icon(Icons.access_time, size: 14, color: muted),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: context.typography.bodyMd.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final JobStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppStatusColors.tint(status.color),
        borderRadius: AppRadius.brFull,
      ),
      child: Text(
        status.label,
        style: context.typography.labelSm.copyWith(
          letterSpacing: 0.2,
          fontWeight: FontWeight.w600,
          color: status.color,
        ),
      ),
    );
  }
}

bool _isDelayedJob(JobStatus status, String? delay) {
  if (status == JobStatus.onHold) return true;

  final normalized = delay?.trim().toLowerCase();
  if (normalized == null || normalized.isEmpty || normalized == '-') {
    return false;
  }

  return normalized != '0' &&
      normalized != '0 min' &&
      !normalized.startsWith('0 min');
}
