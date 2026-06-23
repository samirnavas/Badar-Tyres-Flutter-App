import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../core/theme/theme_store.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.containerPadding),
        children: [
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
        ],
      ),
    );
  }
}
