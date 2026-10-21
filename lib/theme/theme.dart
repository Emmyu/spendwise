import 'package:flutter/material.dart';

import 'colors.dart';
import 'text.dart';

ThemeData buildAppTheme() {
  final body = AppText.style(14);
  return ThemeData(
    useMaterial3: true,
    fontFamily: AppText.family,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      surface: AppColors.bgBase,
      error: AppColors.error,
    ),
    scaffoldBackgroundColor: AppColors.bgBase,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    hoverColor: Colors.transparent,
    textTheme: TextTheme(
      bodySmall: body.copyWith(fontSize: 12),
      bodyMedium: body,
      bodyLarge: body.copyWith(fontSize: 15),
      titleMedium: body.copyWith(fontSize: 15),
      labelLarge: AppText.style(14, weight: 600),
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.primary,
      selectionColor: AppColors.mint,
      selectionHandleColor: AppColors.primary,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      isDense: true,
      contentPadding: EdgeInsets.zero,
    ),
  );
}
