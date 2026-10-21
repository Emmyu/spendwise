import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../models/transaction.dart';
import '../../state/app_state.dart';
import '../../theme/colors.dart';
import '../../theme/text.dart';
import '../../utils/format.dart';
import '../widgets/activity.dart';
import '../widgets/basics.dart';

/// Centered confirmation before a transaction is deleted.
class DeleteConfirmDialog extends StatefulWidget {
  const DeleteConfirmDialog({super.key});

  @override
  State<DeleteConfirmDialog> createState() => _DeleteConfirmDialogState();
}

class _DeleteConfirmDialogState extends State<DeleteConfirmDialog> {
  Transaction? _last;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final tx = state.detailTransaction ?? _last;
    if (tx == null) return const SizedBox.shrink();
    _last = tx;

    return ColoredBox(
      color: AppColors.dialogScrim,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Semantics(
            scopesRoute: true,
            namesRoute: true,
            explicitChildNodes: true,
            label: 'Delete transaction',
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(26),
                boxShadow: const [
                  BoxShadow(color: Color(0x73131B17), blurRadius: 60, spreadRadius: -20, offset: Offset(0, 30)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: IconTile(
                      icon: LucideIcons.trash2,
                      size: 48,
                      radius: 16,
                      iconSize: 22,
                      background: AppColors.errorTint,
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Delete this transaction?', style: AppText.style(19, weight: 600)),
                  const SizedBox(height: 12),
                  Text(
                    '${tx.desc} (${money(tx.amount)}) on ${shortDate(tx.date)} will be removed from your '
                    'history and monthly totals. This can’t be undone.',
                    style: AppText.style(14.5, color: AppColors.ink3, height: 1.5),
                  ),
                  const SizedBox(height: 18),
                  AppButton(
                    label: state.deleting ? 'Deleting…' : 'Delete transaction',
                    leading: state.deleting ? const Spinner() : null,
                    style: AppButtonStyle.destructive,
                    height: 52,
                    radius: 16,
                    fontSize: 15,
                    gap: 10,
                    onTap: state.deleteSelected,
                  ),
                  const SizedBox(height: 8),
                  AppButton(
                    label: 'Cancel',
                    style: AppButtonStyle.neutral,
                    height: 52,
                    radius: 16,
                    fontSize: 15,
                    onTap: state.cancelDelete,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
