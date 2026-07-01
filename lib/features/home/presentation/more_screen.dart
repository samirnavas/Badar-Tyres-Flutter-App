import 'package:flutter/material.dart';

import '../../../core/auth/session_store.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/models/user.dart';
import '../../../core/theme/theme.dart';
import '../../auth/presentation/login_screen.dart';
import '../../services/presentation/services_catalog_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import 'vehicles_screen.dart';

/// The "More" tab — secondary destinations, account actions, and sign-out.
class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key, this.overflowRoutes = const []});

  final List<String> overflowRoutes;

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  @override
  void initState() {
    super.initState();
    SessionStore.instance.refreshPermissions();
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final colors = context.colors;

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out of Badar Tyres?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: colors.errorContainer,
              foregroundColor: colors.onErrorContainer,
            ),
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

  List<_MoreMenuItem> _workshopItems(AuthUser user) {
    final permissions = user.permissions;
    final items = <_MoreMenuItem>[];

    if (widget.overflowRoutes.contains(AppRoutes.vehicles)) {
      items.add(
        _MoreMenuItem(
          icon: Icons.directions_car_outlined,
          label: 'Vehicles',
          subtitle: 'Browse registered vehicles',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const VehiclesScreen()),
          ),
        ),
      );
    }
    if (permissions.canAccess(AppRoutes.services)) {
      items.add(
        _MoreMenuItem(
          icon: Icons.build_circle_outlined,
          label: 'Services',
          subtitle: 'View service catalogue',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ServicesCatalogScreen()),
          ),
        ),
      );
    }
    if (permissions.canAccess(AppRoutes.inventory)) {
      items.add(
        _MoreMenuItem(
          icon: Icons.inventory_2_outlined,
          label: 'Inventory',
          subtitle: 'Stock and parts',
          onTap: () {},
        ),
      );
    }
    if (permissions.canAccess(AppRoutes.customers)) {
      items.add(
        _MoreMenuItem(
          icon: Icons.people_outline,
          label: 'Customers',
          subtitle: 'Customer directory',
          onTap: () {},
        ),
      );
    }
    if (permissions.canAccess(AppRoutes.billing)) {
      items.add(
        _MoreMenuItem(
          icon: Icons.receipt_long_outlined,
          label: 'Billing',
          subtitle: 'Invoices and payments',
          onTap: () {},
        ),
      );
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SessionStore.instance,
      builder: (context, _) {
        final user = SessionStore.currentUser;
        final isTechnician = user?.isTechnician ?? false;
        final workshopItems =
            user != null ? _workshopItems(user) : const <_MoreMenuItem>[];

        return Scaffold(
          backgroundColor: context.colors.surface,
          appBar: isTechnician
              ? null
              : AppBar(title: const Text('More')),
          body: RefreshIndicator(
            onRefresh: SessionStore.instance.refreshPermissions,
            color: context.colors.primary,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                AppSpacing.containerPadding,
                isTechnician ? AppSpacing.stackSm : AppSpacing.stackMd,
                AppSpacing.containerPadding,
                AppSpacing.stackLg,
              ),
              children: [
                if (isTechnician) ...[
                  Text('More', style: context.typography.titleSm),
                  const SizedBox(height: AppSpacing.stackMd),
                ],
                if (user != null) _ProfileCard(user: user),
                if (workshopItems.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.stackLg),
                  _MoreSection(title: 'Workshop', items: workshopItems),
                ],
                const SizedBox(height: AppSpacing.stackLg),
                _MoreSection(
                  title: 'Account',
                  items: [
                    _MoreMenuItem(
                      icon: Icons.settings_outlined,
                      label: 'Settings',
                      subtitle: 'Profile, appearance & preferences',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      ),
                    ),
                    _MoreMenuItem(
                      icon: Icons.help_outline,
                      label: 'Help & Support',
                      subtitle: 'Contact workshop admin',
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.stackLg),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmLogout(context),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('LOG OUT'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colors.errorContainer,
                      foregroundColor: context.colors.onErrorContainer,
                      minimumSize: const Size.fromHeight(56),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.stackMd),
                Center(
                  child: Text(
                    'Badar Tyres Workshop',
                    style: context.typography.labelSm.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MoreMenuItem {
  const _MoreMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.user});

  final AuthUser user;

  String get _initials {
    final parts = user.name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'U';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String _displayEmployeeId(String id) {
    if (id.length >= 36 && id.contains('-')) {
      return '#${id.substring(0, 8).toUpperCase()}';
    }
    return id;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.stackLg),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: colors.primaryContainer,
              child: Text(
                _initials,
                style: context.typography.headlineMd.copyWith(
                  color: colors.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.stackMd),
            Text(
              user.name.isNotEmpty ? user.name : 'Team Member',
              style: context.typography.titleSm.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.stackSm),
            Chip(
              label: Text(user.role),
              labelStyle: context.typography.labelSm.copyWith(
                color: colors.onPrimaryContainer,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
              backgroundColor: colors.primaryContainer,
              side: BorderSide(color: colors.outlineVariant),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
            const SizedBox(height: AppSpacing.stackLg),
            const Divider(),
            const SizedBox(height: AppSpacing.stackMd),
            _ProfileDetailRow(
              icon: Icons.person_outline,
              label: 'Username',
              value: user.username,
            ),
            const SizedBox(height: AppSpacing.stackMd),
            _ProfileDetailRow(
              icon: Icons.badge_outlined,
              label: 'Employee ID',
              value: _displayEmployeeId(user.id),
              tooltip: user.id,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileDetailRow extends StatelessWidget {
  const _ProfileDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.tooltip,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: context.colors.secondary, size: 20),
        const SizedBox(width: AppSpacing.gutter),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: context.typography.labelSm.copyWith(
                  color: context.colors.secondary,
                ),
              ),
              const SizedBox(height: 2),
              Tooltip(
                message: tooltip ?? value,
                child: Text(
                  value,
                  style: context.typography.bodyMd.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MoreSection extends StatelessWidget {
  const _MoreSection({
    required this.title,
    required this.items,
  });

  final String title;
  final List<_MoreMenuItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.base,
            bottom: AppSpacing.base,
          ),
          child: Text(title, style: context.typography.labelSm),
        ),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < items.length; i++) ...[
                _MoreListTile(item: items[i]),
                if (i < items.length - 1) const Divider(height: 1, indent: 72),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MoreListTile extends StatelessWidget {
  const _MoreListTile({required this.item});

  final _MoreMenuItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return ListTile(
      onTap: item.onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.stackMd,
        vertical: AppSpacing.stackSm,
      ),
      leading: _MenuLeadingIcon(icon: item.icon),
      title: Text(
        item.label,
        style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: item.subtitle == null
          ? null
          : Text(
              item.subtitle!,
              style: textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: colors.onSurfaceVariant,
      ),
    );
  }
}

class _MenuLeadingIcon extends StatelessWidget {
  const _MenuLeadingIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppStatusColors.tint(colors.primary),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: colors.primary, size: 20),
    );
  }
}
