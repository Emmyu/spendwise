import 'package:flutter/painting.dart';

/// Colour tokens taken from the SpendWise AI HTML prototype.
abstract final class AppColors {
  // Backgrounds
  static const backdrop = Color(0xFFCBDDD3);
  static const bgTop = Color(0xFFD6E8DC);
  static const bgMid = Color(0xFFECF3EE);
  static const bgBase = Color(0xFFF4F5F1);

  // Brand
  static const primary = Color(0xFF1E4D3A);
  static const primaryPressed = Color(0xFF245A44);
  static const primarySaving = Color(0xFF2D6A4F);
  static const deep = Color(0xFF133529);
  static const mint = Color(0xFFA8E6BE);
  static const onPrimaryMuted = Color(0xFFC4DDCD);
  static const avatarText = Color(0xFFCDEFD8);

  // Ink
  static const ink = Color(0xFF18201C);
  static const ink2 = Color(0xFF3D4842);
  static const ink3 = Color(0xFF4F5A54);
  static const ink4 = Color(0xFF66706A);
  static const ink5 = Color(0xFF8A948E);
  static const ink6 = Color(0xFF9AA39D);
  static const chartLabel = Color(0xFF7C8780);

  // Lines
  static const border = Color(0xFFD8E2DA);
  static const borderCard = Color(0xFFE4E9E5);
  static const borderSoft = Color(0xFFE1E7E2);
  static const borderChip = Color(0xFFCFE2D5);
  static const divider = Color(0xFFEEF1EE);
  static const grabber = Color(0xFFD5DBD6);

  // Surfaces
  static const white = Color(0xFFFFFFFF);
  static const surfacePressed = Color(0xFFF3F7F4);
  static const tint = Color(0xFFE8F1EB);
  static const tintStrong = Color(0xFFDCEBE1);
  static const segment = Color(0xFFE3EAE5);
  static const neutral = Color(0xFFEEF2EF);
  static const clearChip = Color(0xFFE6ECE8);
  static const toolChip = Color(0xFFEEF3EF);

  // Navigation and floating elements
  static const nav = Color(0xFF141B17);
  static const navInactive = Color(0xFF8F9A93);
  static const toast = Color(0xFF18201C);
  static const sheetScrim = Color(0x6B131B17); // rgba(19,27,23,.42)
  static const dialogScrim = Color(0x59131B17); // rgba(19,27,23,.35)

  // Status
  static const error = Color(0xFFA3321F);
  static const destructive = Color(0xFFB4382A);
  static const errorTint = Color(0xFFFBE6E2);
  static const errorBorder = Color(0xFFEFCBC3);
  static const proposedTint = Color(0xFFFBF3E2);
  static const proposedText = Color(0xFF7A4F06);
  static const savingTint = Color(0xFFEEF4F0);

  // Controls
  static const barIdle = Color(0xFFCFE3D6);
  static const sendDisabled = Color(0xFFB9C6BE);
  static const toggleOff = Color(0xFFCCD5CF);

  // Skeleton
  static const skeleton1 = Color(0xFFE1E7E3);
  static const skeleton2 = Color(0xFFEBF0EC);
  static const skeleton3 = Color(0xFFE6EBE7);
  static const skeleton4 = Color(0xFFEEF2EF);
}
