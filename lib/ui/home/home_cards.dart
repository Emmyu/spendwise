import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/colors.dart';
import '../../theme/text.dart';
import '../../utils/format.dart';
import '../widgets/basics.dart';
import '../widgets/pressable.dart';

/// Dark green month-to-date summary.
class SummaryCard extends StatelessWidget {
  const SummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final total = state.monthTotal;
    final before = state.previousPeriodSpend;
    final hasBefore = before > 0; // nothing last month → nothing to compare with
    final diff = total - before;
    final pct = hasBefore ? (diff.abs() / before * 100).round() : 0;
    final down = diff < 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(28)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Spent in ${monthLong(state.today)}',
                  style: AppText.style(14, color: AppColors.onPrimaryMuted),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0x33FFFFFF)),
                ),
                child: Text(monthToDateLabel(state.today), style: AppText.style(12, color: AppColors.onPrimaryMuted)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              state.displayMoney(total),
              style: AppText.style(
                38,
                weight: 600,
                width: 125,
                tracking: -0.02,
                height: 1,
                tabular: true,
                color: AppColors.white,
              ),
            ),
          ),
          if (hasBefore) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(7, 4, 9, 4),
                  decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(999)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(down ? LucideIcons.trendingDown : LucideIcons.trendingUp, size: 13, color: AppColors.deep),
                      const SizedBox(width: 4),
                      Text(
                        '$pct% ${down ? 'less' : 'more'}',
                        style: AppText.style(12, weight: 600, color: AppColors.deep),
                      ),
                    ],
                  ),
                ),
                Text(
                  'than ${previousMonthToDateLabel(state.today)} · ${state.displayMoney(before)}',
                  style: AppText.style(12.5, color: AppColors.onPrimaryMuted),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          const ColoredBox(
            color: Color(0x24FFFFFF),
            child: SizedBox(height: 1, width: double.infinity),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Daily average', style: AppText.style(12, color: AppColors.onPrimaryMuted)),
                    const SizedBox(height: 3),
                    Text(
                      state.displayMoney(state.dailyAverage),
                      style: AppText.style(16, weight: 600, width: 115, tabular: true, color: AppColors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Pressable(
                onTap: state.openNewExpense,
                height: 46,
                padding: const EdgeInsets.fromLTRB(14, 0, 18, 0),
                color: AppColors.white,
                pressedColor: const Color(0xFFEAF5EE),
                borderRadius: BorderRadius.circular(23),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.plus, size: 18, color: AppColors.deep),
                    const SizedBox(width: 8),
                    Text('Add expense', style: AppText.style(14.5, weight: 600, color: AppColors.deep)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "Last 7 days" bar chart.
class WeekChartCard extends StatelessWidget {
  const WeekChartCard({super.key});

  static const _maxBar = 78.0;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final days = state.lastSevenDays;
    final max = days.fold<double>(1, (m, d) => d.amount > m ? d.amount : m);
    final weekTotal = days.fold<double>(0, (s, d) => s + d.amount);

    return AppCard(
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(child: Text('Last 7 days', style: AppText.style(16, weight: 600))),
              Text(state.displayMoney(weekTotal), style: AppText.style(13, color: AppColors.ink4, tabular: true)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 124,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final (i, d) in days.indexed) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                    child: Semantics(
                      label: '${d.isToday ? 'Today' : weekdayShort(d.day)}: ${state.displayMoney(d.amount)}',
                      excludeSemantics: true,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            state.hideAmounts ? '•••' : moneyK(d.amount),
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.visible,
                            style: AppText.style(
                              10.5,
                              weight: 600,
                              tabular: true,
                              color: d.isToday ? AppColors.primary : AppColors.chartLabel,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 30),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                              width: double.infinity,
                              height: (d.amount / max * _maxBar).roundToDouble().clamp(4, _maxBar),
                              decoration: BoxDecoration(
                                color: d.isToday ? AppColors.primary : AppColors.barIdle,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            d.isToday ? 'Today' : weekdayShort(d.day),
                            maxLines: 1,
                            softWrap: false,
                            style: AppText.style(11.5, color: d.isToday ? AppColors.ink : AppColors.ink4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Month spending by category: stacked bar and legend rows.
class CategoryBreakdownCard extends StatelessWidget {
  const CategoryBreakdownCard({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final rows = state.monthBreakdown;
    final total = state.monthTotal;

    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(child: Text('Categories', style: AppText.style(16, weight: 600))),
              Text(monthLong(state.today), style: AppText.style(13, color: AppColors.ink4)),
            ],
          ),
          const SizedBox(height: 14),
          if (rows.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: SizedBox(
                height: 10,
                child: Row(
                  children: [
                    for (final r in rows)
                      Expanded(
                        flex: (r.amount / total * 10000).round().clamp(1, 10000),
                        child: Container(
                          decoration: BoxDecoration(
                            color: r.category.color,
                            border: const Border(right: BorderSide(color: AppColors.white, width: 2)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
          ],
          for (final (i, r) in rows.indexed) ...[
            if (i > 0) const RowDivider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 11),
              child: Row(
                children: [
                  Swatch(r.category.color),
                  const SizedBox(width: 12),
                  Expanded(child: Text(r.category.label, style: AppText.style(14.5))),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${(r.amount / total * 100).round()}%',
                      textAlign: TextAlign.right,
                      style: AppText.style(13, color: AppColors.ink4),
                    ),
                  ),
                  SizedBox(
                    width: 96,
                    child: Text(
                      state.displayMoney(r.amount),
                      textAlign: TextAlign.right,
                      style: AppText.style(14.5, weight: 600, tabular: true),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
