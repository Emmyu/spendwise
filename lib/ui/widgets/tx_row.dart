import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/transaction.dart';
import '../../state/app_state.dart';
import '../../theme/colors.dart';
import '../../theme/text.dart';
import '../../utils/format.dart';
import 'basics.dart';
import 'pressable.dart';

/// A transaction in a list: category tile, description, meta line, amount, time.
class TxRow extends StatelessWidget {
  const TxRow({
    super.key,
    required this.tx,
    this.showDate = false,
    this.showDivider = false,
  });

  final Transaction tx;

  /// Meta shows "Category · Day" instead of "Category · via Ask SpendWise".
  final bool showDate;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cat = tx.category;
    final meta = showDate
        ? '${cat.label} · ${dayLabel(tx.date, today: state.today)}'
        : '${cat.label}${tx.isAi ? ' · via Ask SpendWise' : ''}';
    final amount = '−${state.displayMoney(tx.amount)}';

    return Column(
      children: [
        if (showDivider) const RowDivider(),
        Pressable(
          onTap: () => state.openDetail(tx.id),
          semanticLabel: '${tx.desc}, ${cat.label}, $amount, ${time12(tx.time)}',
          excludeSemantics: true,
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              IconTile(icon: cat.icon, background: cat.tint),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.desc,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.style(15, weight: 500),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.style(12.5, color: AppColors.ink4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(amount, style: AppText.style(15, weight: 600, tabular: true)),
                  const SizedBox(height: 3),
                  Text(time12(tx.time), style: AppText.style(12, color: AppColors.ink5)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
