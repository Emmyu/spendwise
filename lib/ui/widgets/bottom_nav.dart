import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/colors.dart';
import '../../theme/text.dart';
import 'basics.dart';
import 'pressable.dart';

/// Floating dark pill navigation.
class BottomNavPill extends StatelessWidget {
  const BottomNavPill({super.key});

  static const _items = [
    (AppTab.home, LucideIcons.house, 'Home'),
    (AppTab.ai, LucideIcons.sparkles, 'Ask AI'),
    (AppTab.transactions, LucideIcons.arrowLeftRight, 'Transactions'),
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Container(
      height: ShellMetrics.navHeight,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.nav,
        borderRadius: BorderRadius.circular(33),
        boxShadow: const [
          BoxShadow(color: Color(0x80131B17), blurRadius: 32, spreadRadius: -12, offset: Offset(0, 16)),
        ],
      ),
      child: Row(
        children: [
          for (final (tab, icon, label) in _items)
            Expanded(
              child: Semantics(
                selected: state.tab == tab,
                child: Pressable(
                  onTap: () => state.goTo(tab),
                  semanticLabel: label,
                  excludeSemantics: true,
                  height: 54,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 21, color: _color(state.tab == tab)),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        maxLines: 1,
                        style: AppText.style(11, weight: 500, color: _color(state.tab == tab)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _color(bool active) => active ? AppColors.mint : AppColors.navInactive;
}
