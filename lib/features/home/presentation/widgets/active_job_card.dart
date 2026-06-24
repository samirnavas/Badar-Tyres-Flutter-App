import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/models/job.dart';
import '../../../../core/theme/theme.dart';

/// Prominent execution card for the technician's in-progress job.
class ActiveJobCard extends StatefulWidget {
  const ActiveJobCard({
    super.key,
    required this.job,
    required this.onPause,
    required this.onComplete,
    this.onOpenDetails,
  });

  final Job job;
  final VoidCallback onPause;
  final VoidCallback onComplete;
  final VoidCallback? onOpenDetails;

  @override
  State<ActiveJobCard> createState() => _ActiveJobCardState();
}

class _ActiveJobCardState extends State<ActiveJobCard> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _syncElapsed();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _syncElapsed());
  }

  @override
  void didUpdateWidget(covariant ActiveJobCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.job.startTime != widget.job.startTime) {
      _syncElapsed();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _syncElapsed() {
    final startedAt = _parseStartTime(widget.job.startTime);
    if (startedAt == null) return;
    setState(() => _elapsed = DateTime.now().difference(startedAt));
  }

  DateTime? _parseStartTime(String value) {
    if (value == '-' || value.isEmpty) return null;
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  String _formatRegistration(String vehicleNumber) {
    final regNum = vehicleNumber.trim();
    if (regNum.toUpperCase() == 'N/A' || regNum.isEmpty) {
      return 'Unregistered';
    }
    return regNum;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final muted = colors.onSurfaceVariant;
    final registration = _formatRegistration(widget.job.vehicleNumber);
    final bayLabel = widget.job.bayName?.trim().isNotEmpty == true
        ? widget.job.bayName!
        : 'Unassigned';

    return Material(
      elevation: 0,
      color: colors.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.brLg,
        side: BorderSide(color: AppStatusColors.tint(AppStatusColors.running)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onOpenDetails,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.stackMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppStatusColors.tint(AppStatusColors.running),
                      borderRadius: AppRadius.brFull,
                    ),
                    child: Text(
                      'ACTIVE JOB',
                      style: context.typography.labelSm.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: AppStatusColors.running,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.garage_outlined, size: 16, color: muted),
                  const SizedBox(width: 4),
                  Text(
                    bayLabel,
                    style: context.typography.labelSm.copyWith(
                      color: muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.stackMd),
              Text(
                _formatDuration(_elapsed),
                textAlign: TextAlign.center,
                style: context.typography.titleSm.copyWith(
                  fontSize: 44,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Elapsed',
                textAlign: TextAlign.center,
                style: context.typography.labelSm.copyWith(color: muted),
              ),
              const SizedBox(height: AppSpacing.stackMd),
              Text(
                registration,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.typography.titleSm.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  height: 1.15,
                ),
              ),
              if (widget.job.vehicleModel.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  widget.job.vehicleModel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.typography.bodyMd.copyWith(color: muted),
                ),
              ],
              if (widget.job.customerName.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  widget.job.customerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.typography.bodyMd.copyWith(color: muted),
                ),
              ],
              const SizedBox(height: 6),
              Text(
                widget.job.jobNumber,
                style: context.typography.labelSm.copyWith(color: muted),
              ),
              const SizedBox(height: AppSpacing.stackMd),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: widget.onPause,
                      icon: const Icon(Icons.pause_rounded, size: 22),
                      label: const Text('PAUSE'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppStatusColors.pending,
                        side: const BorderSide(color: AppStatusColors.pending),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: context.typography.bodyMd.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.gutter),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: widget.onComplete,
                      icon: const Icon(Icons.check_rounded, size: 22),
                      label: const Text('COMPLETE'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppStatusColors.completed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: context.typography.bodyMd.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
