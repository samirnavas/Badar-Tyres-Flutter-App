import 'package:flutter/material.dart';

import '../../../core/auth/session_store.dart';
import '../../../core/theme/theme.dart';
import '../../auth/presentation/login_screen.dart';
import '../../services/presentation/services_catalog_screen.dart';
import '../../settings/presentation/settings_screen.dart';

/// The "More" tab — a settings-style menu of secondary destinations and the
/// sign-out action.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  void _openServices(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ServicesCatalogScreen()),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (shouldLogout != true) return;
    await SessionStore.instance.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.surface,
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.containerPadding,
          AppSpacing.stackMd,
          AppSpacing.containerPadding,
          AppSpacing.stackLg,
        ),
        children: [
          const _ProfileHeader(),
          const SizedBox(height: AppSpacing.stackLg),
          _MoreTile(
            icon: Icons.build_circle_outlined,
            label: 'Services',
            onTap: () => _openServices(context),
          ),
          _MoreTile(
            icon: Icons.person_outline,
            label: 'Profile',
            onTap: () {},
          ),
          _MoreTile(
            icon: Icons.settings_outlined,
            label: 'Settings',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          _MoreTile(
            icon: Icons.help_outline,
            label: 'Help & Support',
            onTap: () {},
          ),
          const SizedBox(height: AppSpacing.stackMd),
          _MoreTile(
            icon: Icons.logout,
            label: 'Log out',
            danger: true,
            onTap: () => _confirmLogout(context),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: context.colors.outlineVariant, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppStatusColors.tint(context.colors.primaryContainer),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.person_rounded,
              color: context.colors.primaryContainer,
              size: 30,
            ),
          ),
          const SizedBox(width: AppSpacing.stackMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Badar Tyres', style: context.typography.titleSm),
                const SizedBox(height: 2),
                Text(
                  'Workshop Admin',
                  style: context.typography.bodyMd.copyWith(
                    fontSize: 13,
                    color: context.colors.secondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? context.colors.primaryContainer : context.colors.onSurface;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.base),
      child: Material(
        color: context.colors.surfaceContainerLow,
        borderRadius: AppRadius.brBase,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.stackMd,
              vertical: 14,
            ),
            child: Row(
              children: [
                Icon(icon, size: 22, color: color),
                const SizedBox(width: AppSpacing.gutter),
                Expanded(
                  child: Text(
                    label,
                    style: context.typography.bodyMd.copyWith(
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (!danger)
                  Icon(Icons.chevron_right_rounded,
                      color: context.colors.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}