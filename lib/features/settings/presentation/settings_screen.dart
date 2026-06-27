import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../core/theme/theme_store.dart';
import '../../../core/auth/session_store.dart';

import '../../auth/presentation/login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
    final user = SessionStore.currentUser;
    final isTech = user?.role == 'Technician';

    return Scaffold(
      appBar: isTech ? null : AppBar(title: const Text('Profile & Settings')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.containerPadding),
        children: [
          if (user != null) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.stackLg),
              decoration: BoxDecoration(
                color: context.colors.surfaceContainerLow,
                borderRadius: AppRadius.brLg,
                border: Border.all(color: context.colors.outlineVariant),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: context.colors.primaryContainer,
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: context.typography.headlineMd.copyWith(
                        color: context.colors.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.stackMd),
                  Text(
                    user.name,
                    style: context.typography.titleSm.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.role,
                    style: context.typography.bodyMd.copyWith(
                      color: context.colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.stackLg),
                  Divider(color: context.colors.outlineVariant.withValues(alpha: 0.5)),
                  const SizedBox(height: AppSpacing.stackMd),
                  _buildProfileRow(context, Icons.person_outline, 'Username', user.username),
                  const SizedBox(height: AppSpacing.stackMd),
                  _buildProfileRow(
                    context,
                    Icons.badge_outlined,
                    'Employee ID',
                    _displayEmployeeId(user.id),
                    tooltip: user.id,
                  ),
                ],
              ),
            ),

          ],
          const Text('Appearance', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.stackMd),
          ListenableBuilder(
            listenable: ThemeStore.instance,
            builder: (context, _) {
              final isDark = ThemeStore.instance.isDarkMode;
              return SwitchListTile(
                title: const Text('Dark Mode'),
                value: isDark,
                onChanged: (value) {
                  ThemeStore.instance.setDarkMode(value);
                },
              );
            },
          ),
          const SizedBox(height: AppSpacing.stackLg),
          ElevatedButton.icon(
            onPressed: () => _confirmLogout(context),
            icon: const Icon(Icons.logout),
            label: const Text('LOG OUT'),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.errorContainer,
              foregroundColor: context.colors.onErrorContainer,
              minimumSize: const Size.fromHeight(56),
            ),
          )
        ],
      ),
    );
  }

  String _displayEmployeeId(String id) {
    if (id.length >= 36 && id.contains('-')) {
      return '#${id.substring(0, 8).toUpperCase()}';
    }
    return id;
  }

  Widget _buildProfileRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    String? tooltip,
  }) {
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
                  maxLines: 2,
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
