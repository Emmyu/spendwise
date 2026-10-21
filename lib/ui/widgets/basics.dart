import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/colors.dart';
import '../../theme/text.dart';
import 'pressable.dart';

/// Layout metrics for the floating bottom navigation.
abstract final class ShellMetrics {
  static const navHeight = 66.0;

  /// Distance from the screen bottom to the nav pill (26 in the prototype).
  static double navBottom(BuildContext context) =>
      math.max(26.0, MediaQuery.paddingOf(context).bottom - 8);

  /// Bottom padding for scrolling tab content so it clears the nav (124).
  static double contentBottom(BuildContext context) => navBottom(context) + navHeight + 32;
}

/// White rounded card with a hairline border.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 24,
    this.borderColor = AppColors.borderCard,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }
}

/// Rounded square holding an icon (category tiles, settings rows, etc.).
class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.icon,
    this.size = 42,
    this.radius = 14,
    this.iconSize = 19,
    this.background = AppColors.tint,
    this.color = AppColors.primary,
  });

  final IconData icon;
  final double size;
  final double radius;
  final double iconSize;
  final Color background;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(radius)),
      alignment: Alignment.center,
      child: Icon(icon, size: iconSize, color: color),
    );
  }
}

/// 44 px round icon button (header actions).
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.size = 44,
    this.iconSize = 19,
    this.filled = false,
    this.background,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;

  /// Dark green filled variant (e.g. the + button on Transactions).
  final bool filled;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      width: size,
      height: size,
      color: background ?? (filled ? AppColors.primary : AppColors.white),
      pressedColor: filled ? AppColors.primaryPressed : AppColors.surfacePressed,
      borderRadius: BorderRadius.circular(size / 2),
      border: filled || background != null ? null : Border.all(color: AppColors.border),
      alignment: Alignment.center,
      child: Icon(icon, size: iconSize, color: filled ? AppColors.white : AppColors.ink),
    );
  }
}

/// Full-width or intrinsic-width rounded button with optional leading icon.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.leading,
    this.style = AppButtonStyle.primary,
    this.height = 46,
    this.radius = 15,
    this.fontSize = 14,
    this.iconSize = 16,
    this.gap = 6,
    this.padding = const EdgeInsets.symmetric(horizontal: 8),
    this.expand = true,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;

  /// Shown before the label instead of [icon], e.g. a spinner.
  final Widget? leading;
  final AppButtonStyle style;
  final double height;
  final double radius;
  final double fontSize;
  final double iconSize;
  final double gap;
  final EdgeInsetsGeometry padding;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final (bg, pressed, fg, border) = switch (style) {
      AppButtonStyle.primary => (AppColors.primary, AppColors.primaryPressed, AppColors.white, null),
      AppButtonStyle.outline => (AppColors.white, AppColors.surfacePressed, AppColors.ink, AppColors.border),
      AppButtonStyle.neutral => (AppColors.neutral, const Color(0xFFE3E9E5), AppColors.ink, null),
      AppButtonStyle.destructive => (AppColors.destructive, const Color(0xFF9E2F22), AppColors.white, null),
      AppButtonStyle.destructiveOutline =>
        (AppColors.white, const Color(0xFFFDF3F1), AppColors.error, AppColors.errorBorder),
    };
    final lead = leading ?? (icon == null ? null : Icon(icon, size: iconSize, color: fg));
    return Pressable(
      onTap: onTap,
      height: height,
      width: expand ? double.infinity : null,
      padding: padding,
      color: bg,
      pressedColor: pressed,
      borderRadius: BorderRadius.circular(radius),
      border: border == null ? null : Border.all(color: border),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (lead != null) ...[lead, SizedBox(width: gap)],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.style(fontSize, weight: 600, color: fg),
            ),
          ),
        ],
      ),
    );
  }
}

enum AppButtonStyle { primary, outline, neutral, destructive, destructiveOutline }

/// Pill-shaped chip (filters, suggestions, date choices).
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
    this.height = 36,
    this.fontSize = 13.5,
    this.horizontalPadding = 15,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final double height;
  final double fontSize;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      height: height,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      color: selected ? AppColors.primary : AppColors.white,
      pressedColor: selected ? AppColors.primaryPressed : AppColors.surfacePressed,
      borderRadius: BorderRadius.circular(height / 2),
      border: Border.all(color: selected ? AppColors.primary : AppColors.border),
      alignment: Alignment.center,
      child: Text(
        label,
        maxLines: 1,
        style: AppText.style(fontSize, weight: 500, color: selected ? AppColors.white : AppColors.ink),
      ),
    );
  }
}

/// Hairline separator between rows inside a card.
class RowDivider extends StatelessWidget {
  const RowDivider({super.key});

  @override
  Widget build(BuildContext context) => const ColoredBox(
        color: AppColors.divider,
        child: SizedBox(height: 1, width: double.infinity),
      );
}

/// Small coloured square used as a legend swatch.
class Swatch extends StatelessWidget {
  const Swatch(this.color, {super.key, this.size = 10, this.radius = 3});

  final Color color;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(radius)),
      );
}

/// Inline red validation message with an alert icon.
class FieldError extends StatelessWidget {
  const FieldError(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(LucideIcons.circleAlert, size: 14, color: AppColors.error),
        const SizedBox(width: 6),
        Expanded(child: Text(message, style: AppText.style(13, color: AppColors.error))),
      ],
    );
  }
}

/// "Section label" above a settings group or form field.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.padding = EdgeInsets.zero});

  final String text;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Padding(
        padding: padding,
        child: Text(text, style: AppText.style(13, weight: 600, color: AppColors.ink2)),
      );
}
