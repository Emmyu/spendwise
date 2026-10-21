import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../models/category.dart';
import '../../state/app_state.dart';
import '../../theme/colors.dart';
import '../../theme/text.dart';
import '../widgets/activity.dart';
import '../widgets/basics.dart';
import '../widgets/pressable.dart';
import '../widgets/tx_row.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final groups = state.transactionGroups;
    final bottom = ShellMetrics.contentBottom(context);

    final Widget body = switch (state.txLoad) {
      TxLoadState.loading => const _LoadingList(),
      TxLoadState.error => const _ErrorCard(),
      TxLoadState.ready when groups.isEmpty => const _EmptyState(),
      TxLoadState.ready => const _GroupedList(),
    };

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Transactions', style: AppText.style(27, weight: 600, tracking: -0.02)),
                  ),
                  CircleIconButton(
                    icon: LucideIcons.plus,
                    iconSize: 20,
                    label: 'Add expense',
                    filled: true,
                    onTap: state.openNewExpense,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SearchField(value: state.search, onChanged: state.setSearch),
              const SizedBox(height: 12),
              const _CategoryChips(),
              const SizedBox(height: 12),
              const _RangeAndGrouping(),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(20, 0, 20, bottom),
            children: [body],
          ),
        ),
      ],
    );
  }
}

class _SearchField extends StatefulWidget {
  const _SearchField({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final _controller = TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(_SearchField old) {
    super.didUpdateWidget(old);
    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.fromLTRB(14, 0, 12, 0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.search, size: 18, color: AppColors.ink4),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: widget.onChanged,
              textInputAction: TextInputAction.search,
              style: AppText.style(15),
              decoration: InputDecoration(
                hintText: 'Search expenses',
                hintStyle: AppText.style(15, color: AppColors.ink6),
              ),
            ),
          ),
          if (widget.value.isNotEmpty)
            Pressable(
              onTap: () => widget.onChanged(''),
              semanticLabel: 'Clear search',
              width: 24,
              height: 24,
              color: AppColors.clearChip,
              borderRadius: BorderRadius.circular(12),
              alignment: Alignment.center,
              child: const Icon(LucideIcons.x, size: 13, color: AppColors.ink2),
            ),
        ],
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final options = <(ExpenseCategory?, String)>[
      (null, 'All'),
      for (final c in ExpenseCategory.values) (c, c.label),
    ];
    return SizedBox(
      height: 36,
      child: OverflowBox(
        maxWidth: MediaQuery.sizeOf(context).width,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: options.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final (cat, label) = options[i];
            return AppChip(
              label: label,
              selected: state.categoryFilter == cat,
              onTap: () => state.setCategoryFilter(cat),
            );
          },
        ),
      ),
    );
  }
}

class _RangeAndGrouping extends StatelessWidget {
  const _RangeAndGrouping();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Row(
      children: [
        Pressable(
          onTap: state.cycleRange,
          semanticLabel: 'Date range: ${state.range.label}. Tap to change',
          excludeSemantics: true,
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          color: AppColors.white,
          pressedColor: AppColors.surfacePressed,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.calendar, size: 15, color: AppColors.ink),
              const SizedBox(width: 7),
              Text(state.range.label, style: AppText.style(13.5, weight: 500)),
              const SizedBox(width: 7),
              const Icon(LucideIcons.chevronDown, size: 14, color: AppColors.ink4),
            ],
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(color: AppColors.segment, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              for (final (g, label) in const [(TxGrouping.day, 'Daily'), (TxGrouping.month, 'Monthly')]) ...[
                if (g == TxGrouping.month) const SizedBox(width: 2),
                Semantics(
                  selected: state.grouping == g,
                  child: Pressable(
                    onTap: () => state.setGrouping(g),
                    height: 30,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    color: state.grouping == g ? AppColors.white : const Color(0x00FFFFFF),
                    borderRadius: BorderRadius.circular(9),
                    alignment: Alignment.center,
                    child: Text(label, style: AppText.style(13, weight: 500)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _GroupedList extends StatelessWidget {
  const _GroupedList();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final list = state.filteredTransactions;
    final total = list.fold<double>(0, (s, t) => s + t.amount);
    final byMonth = state.grouping == TxGrouping.month;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 2, 4, 12),
          child: Text(
            '${list.length} transaction${list.length == 1 ? '' : 's'} · ${state.displayMoney(total)}',
            style: AppText.style(13, color: AppColors.ink3, tabular: true),
          ),
        ),
        for (final g in state.transactionGroups)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(g.label, style: AppText.style(13, weight: 600, color: AppColors.ink2)),
                      ),
                      Text(
                        state.displayMoney(g.total),
                        style: AppText.style(13, color: AppColors.ink4, tabular: true),
                      ),
                    ],
                  ),
                ),
                AppCard(
                  radius: 20,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      for (final (i, tx) in g.items.indexed)
                        TxRow(tx: tx, showDate: byMonth, showDivider: i > 0),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final q = state.search.trim();
    final title = q.isNotEmpty
        ? 'No results for “$q”'
        : state.isFiltered
            ? 'Nothing in this category'
            : 'No transactions yet';
    final body = state.isFiltered
        ? 'Try another word or date range, or clear your search and filters.'
        : 'Expenses you add manually or with Ask SpendWise will appear here.';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
      child: Column(
        children: [
          const IconTile(
            icon: LucideIcons.searchX,
            size: 60,
            radius: 20,
            iconSize: 26,
            background: AppColors.segment,
            color: AppColors.ink2,
          ),
          const SizedBox(height: 16),
          Text(title, textAlign: TextAlign.center, style: AppText.style(18, weight: 600)),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Text(
              body,
              textAlign: TextAlign.center,
              style: AppText.style(14.5, color: AppColors.ink3, height: 1.5),
            ),
          ),
          const SizedBox(height: 18),
          AppButton(
            label: 'Clear search and filters',
            style: AppButtonStyle.outline,
            radius: 23,
            fontSize: 14.5,
            expand: false,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            onTap: state.clearFilters,
          ),
        ],
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    Widget group(List<double> widths) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SkeletonBox(width: 90, height: 12, color: AppColors.skeleton1),
              ),
            ),
            const SizedBox(height: 10),
            AppCard(
              radius: 20,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: [
                  for (final w in widths)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          const SkeletonBox(width: 42, height: 42, radius: 14, color: AppColors.skeleton2),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FractionallySizedBox(widthFactor: w, child: const SkeletonBox(height: 12)),
                                const SizedBox(height: 7),
                                const SkeletonBox(width: 70, height: 10, color: AppColors.skeleton4),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          const SkeletonBox(width: 64, height: 12),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        );

    return Semantics(
      label: 'Loading transactions',
      child: SkeletonPulse(
        child: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            children: [group(const [0.6, 0.45, 0.7]), const SizedBox(height: 16), group(const [0.5, 0.65])],
          ),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard();

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: AppCard(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const IconTile(
              icon: LucideIcons.wifiOff,
              size: 48,
              radius: 16,
              iconSize: 22,
              background: AppColors.errorTint,
              color: AppColors.error,
            ),
            const SizedBox(height: 14),
            Text('Couldn’t load transactions', style: AppText.style(18, weight: 600)),
            const SizedBox(height: 10),
            Text(
              'Check your connection and try again. Your saved expenses are safe.',
              style: AppText.style(14.5, color: AppColors.ink3, height: 1.5),
            ),
            const SizedBox(height: 18),
            AppButton(
              label: 'Try again',
              icon: LucideIcons.refreshCw,
              iconSize: 17,
              gap: 8,
              radius: 23,
              fontSize: 14.5,
              expand: false,
              padding: const EdgeInsets.fromLTRB(14, 0, 18, 0),
              onTap: state.retryLoad,
            ),
          ],
        ),
      ),
    );
  }
}
