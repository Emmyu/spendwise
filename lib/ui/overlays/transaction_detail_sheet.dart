import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../models/transaction.dart';
import '../../state/app_state.dart';
import '../../theme/colors.dart';
import '../../theme/text.dart';
import '../../utils/format.dart';
import '../widgets/basics.dart';

/// Bottom sheet with a transaction's details and Edit / Delete actions.
class TransactionDetailSheet extends StatefulWidget {
  const TransactionDetailSheet({super.key});

  @override
  State<TransactionDetailSheet> createState() => _TransactionDetailSheetState();
}

class _TransactionDetailSheetState extends State<TransactionDetailSheet> {
  /// Keeps the last transaction so the sheet can animate out after deletion.
  Transaction? _last;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final tx = state.detailTransaction ?? _last;
    if (tx == null) return const SizedBox.shrink();
    _last = tx;
    final cat = tx.category;
    final bottom = math.max(40.0, MediaQuery.paddingOf(context).bottom + 16);

    Widget infoRow(String name, Widget value, {bool divider = true}) => Column(
          children: [
            if (divider) const RowDivider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 13),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppText.style(14.5, color: AppColors.ink4)),
                  const SizedBox(width: 12),
                  Expanded(child: Align(alignment: Alignment.centerRight, child: value)),
                ],
              ),
            ),
          ],
        );

    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: 'Transaction details',
      child: Container(
        padding: EdgeInsets.fromLTRB(22, 10, 22, bottom),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(color: AppColors.grabber, borderRadius: BorderRadius.circular(3)),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                IconTile(icon: cat.icon, size: 48, radius: 16, iconSize: 22, background: cat.tint),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tx.desc, style: AppText.style(18, weight: 600)),
                      const SizedBox(height: 2),
                      Text(cat.label, style: AppText.style(13.5, color: AppColors.ink4)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                CircleIconButton(
                  icon: LucideIcons.x,
                  label: 'Close',
                  size: 38,
                  iconSize: 16,
                  background: AppColors.neutral,
                  onTap: state.closeOverlay,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              state.displayMoney(tx.amount),
              style: AppText.style(36, weight: 600, width: 125, tracking: -0.02, tabular: true),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.borderCard),
              ),
              child: Column(
                children: [
                  infoRow('Date', Text(longDate(tx.date), style: AppText.style(14.5)), divider: false),
                  infoRow('Time', Text(time12(tx.time), style: AppText.style(14.5))),
                  infoRow(
                    'Added',
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(tx.isAi ? LucideIcons.sparkles : LucideIcons.pencil, size: 14, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(tx.isAi ? 'Ask SpendWise' : 'Manually', style: AppText.style(14.5)),
                      ],
                    ),
                  ),
                  infoRow(
                    'Note',
                    Text(
                      tx.note.isEmpty ? 'No note' : tx.note,
                      textAlign: TextAlign.right,
                      style: AppText.style(14.5, color: tx.note.isEmpty ? AppColors.ink6 : AppColors.ink),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Edit',
                    icon: LucideIcons.pencil,
                    style: AppButtonStyle.outline,
                    height: 52,
                    radius: 16,
                    fontSize: 15,
                    gap: 8,
                    onTap: state.openEditExpense,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppButton(
                    label: 'Delete',
                    icon: LucideIcons.trash2,
                    style: AppButtonStyle.destructiveOutline,
                    height: 52,
                    radius: 16,
                    fontSize: 15,
                    gap: 8,
                    onTap: state.askDelete,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
