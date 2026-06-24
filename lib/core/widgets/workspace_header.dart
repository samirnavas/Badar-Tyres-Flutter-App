import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../theme/theme.dart';

/// Compact branded header shown across technician workspace tabs.
class WorkspaceHeader extends StatelessWidget {
  const WorkspaceHeader({
    super.key,
    required this.userName,
    this.onSyncTap,
    this.onNotificationsTap,
  });

  final String userName;
  final VoidCallback? onSyncTap;
  final VoidCallback? onNotificationsTap;

  String get _firstName {
    final trimmed = userName.trim();
    if (trimmed.isEmpty) return 'Technician';
    return trimmed.split(RegExp(r'\s+')).first;
  }

  String get _todayLabel {
    final now = DateTime.now();
    return 'Today, ${DateFormat('MMM d').format(now)}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final logoAsset = Theme.of(context).brightness == Brightness.dark
        ? 'assets/images/badar_logo_white.svg'
        : 'assets/images/badar_logo_black.svg';

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.containerPadding,
          AppSpacing.stackSm,
          AppSpacing.stackSm,
          AppSpacing.gutter,
        ),
        child: SizedBox(
          height: kToolbarHeight,
          child: Row(
            children: [
              SvgPicture.asset(
                logoAsset,
                height: 35,
                semanticsLabel: 'Badar Tyres',
              ),
              const SizedBox(width: AppSpacing.gutter),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 25),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hi, $_firstName',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.typography.titleSm.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                      Text(
                        _todayLabel,
                        style: context.typography.labelSm.copyWith(
                          fontSize: 11,
                          letterSpacing: 0,
                          fontWeight: FontWeight.w400,
                          height: 1.2,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: onSyncTap,
                    tooltip: 'Sync status',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    icon: Icon(
                      Icons.cloud_outlined,
                      size: 22,
                      color: colors.onSurface,
                    ),
                  ),
                  IconButton(
                    onPressed: onNotificationsTap,
                    tooltip: 'Notifications',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    icon: Icon(
                      Icons.notifications_none_rounded,
                      size: 22,
                      color: colors.onSurface,
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
