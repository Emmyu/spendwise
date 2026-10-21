import 'package:flutter/painting.dart';

import 'colors.dart';

/// Text styles for the Archivo variable font.
///
/// The bundled font defaults to wght 600, so the weight is always set through
/// the `wght` axis rather than [FontWeight] (which would trigger faux bold).
/// `width` maps to CSS `font-stretch` (62–125); large amounts use 125.
abstract final class AppText {
  static const family = 'Archivo';

  static TextStyle style(
    double size, {
    double weight = 400,
    double width = 100,
    Color color = AppColors.ink,
    double? height,
    double tracking = 0,
    bool tabular = false,
  }) {
    return TextStyle(
      fontFamily: family,
      fontSize: size,
      fontVariations: [FontVariation('wght', weight), FontVariation('wdth', width)],
      color: color,
      height: height,
      letterSpacing: tracking == 0 ? null : tracking * size,
      fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
    );
  }

  /// Monospace labels for tool names such as `add_expense`.
  static TextStyle mono(double size, {Color color = AppColors.ink3}) {
    return TextStyle(
      fontFamily: 'monospace',
      fontFamilyFallback: const ['Menlo', 'Consolas', 'Roboto Mono', 'Courier New'],
      fontSize: size,
      color: color,
    );
  }
}
