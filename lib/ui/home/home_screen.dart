import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/colors.dart';
import '../../theme/text.dart';
import '../../utils/format.dart';
import '../widgets/basics.dart';
import '../widgets/pressable.dart';
import '../widgets/tx_row.dart';
import 'home_cards.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final recent = state.recentTransactions;
    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.fromLTRB(20, 8, 20, ShellMetrics.contentBottom(context)),
          children: [
            const _Header(),
            const SizedBox(height: 16),
            const SummaryCard(),
            const SizedBox(height: 16),
            const WeekChartCard(),
            const SizedBox(height: 16),
            const CategoryBreakdownCard(),
            const SizedBox(height: 16),
            AppCard(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 4),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('Recent transactions', style: AppText.style(16, weight: 600))),
                      Pressable(
                        onTap: () => state.goTo(AppTab.transactions),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text('See all', style: AppText.style(13.5, weight: 600, color: AppColors.primary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (recent.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, bottom: 14),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'No expenses yet.',
                          style: AppText.style(13.5, color: AppColors.ink4),
                        ),
                      ),
                    ),
                  for (final (i, tx) in recent.indexed)
                    TxRow(tx: tx, showDate: true, showDivider: i > 0),
                ],
              ),
            ),
          ],
        ),
        Positioned(
          right: 20,
          bottom: ShellMetrics.navBottom(context) + 78,
          child: Pressable(
            onTap: () => state.goTo(AppTab.ai),
            height: 50,
            padding: const EdgeInsets.fromLTRB(16, 0, 20, 0),
            color: AppColors.primary,
            pressedColor: AppColors.primaryPressed,
            borderRadius: BorderRadius.circular(25),
            boxShadow: const [
              BoxShadow(color: Color(0x99133529), blurRadius: 28, spreadRadius: -10, offset: Offset(0, 12)),
            ],
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.sparkles, size: 19, color: AppColors.mint),
                const SizedBox(width: 8),
                Text('Ask AI', style: AppText.style(15, weight: 600, color: AppColors.white)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
          child: const Icon(LucideIcons.user, size: 20, color: AppColors.avatarText),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greeting(DateTime.now()), style: AppText.style(13, color: AppColors.ink3)),
              Text('SpendWise', style: AppText.style(19, weight: 600, tracking: -0.01)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        CircleIconButton(
          icon: state.hideAmounts ? LucideIcons.eyeOff : LucideIcons.eye,
          label: state.hideAmounts ? 'Show amounts' : 'Hide amounts',
          onTap: state.toggleHideAmounts,
        ),
        const SizedBox(width: 12),
        CircleIconButton(
          icon: LucideIcons.bell,
          label: 'Notifications',
          onTap: () => state.showToast('No new notifications'),
        ),
      ],
    );
  }
}
