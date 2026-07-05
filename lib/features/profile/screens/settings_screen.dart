import 'package:flutter/material.dart';

import 'package:sign/shared/settings/settings_controller.dart';
import 'package:sign/shared/ui/responsive_layout.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _colors = [
    Colors.teal,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.pink,
    Colors.deepPurple,
    Colors.brown,
    Colors.blueGrey,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: AnimatedBuilder(
        animation: appSettingsController,
        builder: (context, _) {
          return MaxWidthContainer(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  '主题色',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final color in _colors)
                      _ColorSwatchButton(
                        color: color,
                        selected:
                            color.toARGB32() ==
                            appSettingsController.seedColor.toARGB32(),
                        onTap: () => appSettingsController.setSeedColor(color),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.palette_outlined),
                  title: const Text('启用动态取色'),
                  value: appSettingsController.useDynamicColor,
                  onChanged: appSettingsController.setUseDynamicColor,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.dark_mode_outlined),
                  title: const Text('启用深色模式'),
                  value: appSettingsController.useDarkMode,
                  onChanged: appSettingsController.setUseDarkMode,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ColorSwatchButton extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ColorSwatchButton({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            width: selected ? 4 : 1,
            color: selected
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: selected ? const Icon(Icons.check, color: Colors.white) : null,
      ),
    );
  }
}
