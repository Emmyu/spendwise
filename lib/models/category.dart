import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Expense categories, in the prototype's display order.
enum ExpenseCategory {
  food('Food', LucideIcons.utensils, Color(0xFF1E4D3A), Color(0xFFDCEBE1)),
  transport('Transport', LucideIcons.carFront, Color(0xFF3F7D5C), Color(0xFFE1EEE5)),
  shopping('Shopping', LucideIcons.shoppingBag, Color(0xFF7DB394), Color(0xFFE8F2EB)),
  bills('Bills', LucideIcons.receiptText, Color(0xFFB3D5BF), Color(0xFFEDF4EF)),
  other('Other', LucideIcons.circleEllipsis, Color(0xFFD3DAD5), Color(0xFFF0F2F0));

  const ExpenseCategory(this.label, this.icon, this.color, this.tint);

  final String label;
  final IconData icon;

  /// Chart and legend colour.
  final Color color;

  /// Background of the category icon tile.
  final Color tint;
}
