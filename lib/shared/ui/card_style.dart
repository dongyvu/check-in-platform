import 'package:flutter/material.dart';

class AppCardStyle {
  static Color background(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Color.alphaBlend(
      scheme.primary.withValues(alpha: isDark ? 0.12 : 0.08),
      scheme.surface,
    );
  }

  static Color selectedBackground(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Color.alphaBlend(
      scheme.primary.withValues(alpha: isDark ? 0.25 : 0.15),
      scheme.surface,
    );
  }

  static BorderSide border(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return BorderSide(
      color: scheme.outlineVariant.withValues(alpha: 0.85),
      width: 1,
    );
  }

  static RoundedRectangleBorder shape(
    BuildContext context, {
    double radius = 12,
  }) {
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: border(context),
    );
  }
}
