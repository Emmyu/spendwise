import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../models/chat.dart';
import '../../state/app_state.dart';
import '../../theme/colors.dart';
import '../../theme/text.dart';
import '../../utils/dates.dart';
import '../../utils/format.dart';
import '../widgets/activity.dart';
import '../widgets/basics.dart';
import '../widgets/pressable.dart';

/// Shown before the first message: what the assistant does, and starter prompts.
class IntroPanel extends StatelessWidget {
  const IntroPanel({super.key});

  static const _prompts = [
    ('How much have I spent this week?', LucideIcons.calendarDays),
    ('Record my lunch expense.', LucideIcons.plus),
    ('What is my biggest expense category?', LucideIcons.chartPie),
    ('Compare my spending this month with last month.', LucideIcons.arrowLeftRight),
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(26)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const IconTile(
                  icon: LucideIcons.sparkles,
                  size: 44,
                  radius: 14,
                  iconSize: 22,
                  background: AppColors.mint,
                  color: AppColors.deep,
                ),
                const SizedBox(height: 12),
                Text(
                  'Record expenses and understand your spending in plain language.',
                  style: AppText.style(21, weight: 600, height: 1.25, tracking: -0.01, color: AppColors.white),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Icon(LucideIcons.shieldCheck, size: 16, color: AppColors.onPrimaryMuted),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You review every expense before it’s saved. Totals are calculated from your recorded transactions.',
                        style: AppText.style(13.5, color: AppColors.onPrimaryMuted, height: 1.45),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const SectionLabel('Try asking', padding: EdgeInsets.fromLTRB(4, 4, 4, 0)),
          const SizedBox(height: 16),
          for (final (i, (label, icon)) in _prompts.indexed) ...[
            if (i > 0) const SizedBox(height: 8),
            Pressable(
              onTap: () => state.send(label),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              color: AppColors.white,
              pressedColor: const Color(0xFFF6F9F7),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderSoft),
              child: Row(
                children: [
                  IconTile(icon: icon, size: 34, radius: 11, iconSize: 16),
                  const SizedBox(width: 12),
                  Expanded(child: Text(label, style: AppText.style(14.5, height: 1.35))),
                  const SizedBox(width: 12),
                  const Icon(LucideIcons.arrowUpRight, size: 16, color: AppColors.ink6),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class UserBubble extends StatelessWidget {
  const UserBubble(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: FractionallySizedBox(
        widthFactor: 0.8,
        alignment: Alignment.centerRight,
        child: Align(
          alignment: Alignment.centerRight,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(6),
              ),
            ),
            child: Text(text, style: AppText.style(15, color: AppColors.white, height: 1.4)),
          ),
        ),
      ),
    );
  }
}

class _AiAvatar extends StatelessWidget {
  const _AiAvatar();

  @override
  Widget build(BuildContext context) => const IconTile(
        icon: LucideIcons.sparkles,
        size: 30,
        radius: 10,
        iconSize: 15,
        background: AppColors.primary,
        color: AppColors.mint,
      );
}

class AiMessageView extends StatelessWidget {
  const AiMessageView(this.message, {super.key});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final m = message;
    final parts = <Widget>[
      if (m.text.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(m.text, style: AppText.style(15, height: 1.45)),
        ),
      if (m.proposal != null) ProposalCard(messageId: m.id, data: m.proposal!),
      if (m.summary != null) SummaryCardView(m.summary!),
      if (m.chips.isNotEmpty)
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in m.chips)
              Pressable(
                onTap: () => state.send(c),
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                color: AppColors.tint,
                pressedColor: AppColors.tintStrong,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.borderChip),
                alignment: Alignment.center,
                child: Text(c, style: AppText.style(13.5, weight: 500, color: AppColors.deep)),
              ),
          ],
        ),
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _AiAvatar(),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, p) in parts.indexed) ...[if (i > 0) const SizedBox(height: 10), p],
            ],
          ),
        ),
      ],
    );
  }
}

/// An AI-prepared expense awaiting confirmation (or its saving/saved/failed state).
class ProposalCard extends StatelessWidget {
  const ProposalCard({super.key, required this.messageId, required this.data});

  final String messageId;
  final ProposalCardData data;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final tx = data.tx;
    final cat = tx.category;
    final (label, bg, fg, icon) = switch (data.status) {
      ProposalStatus.proposed => ('Proposed · not saved yet', AppColors.proposedTint, AppColors.proposedText, LucideIcons.clock),
      ProposalStatus.saving => ('Saving…', AppColors.savingTint, AppColors.primary, LucideIcons.loaderCircle),
      ProposalStatus.saved => ('Saved to your transactions', AppColors.tintStrong, AppColors.deep, LucideIcons.circleCheck),
      ProposalStatus.failed => ('Not saved', AppColors.errorTint, AppColors.error, LucideIcons.triangleAlert),
    };
    final recent = !tx.date.isBefore(addDays(state.today, -1));
    final dateText = '${dayLabel(tx.date, today: state.today)}${recent ? ', ${shortDate(tx.date)}' : ''}';

    Widget detailRow(String name, Widget value) => Column(
          children: [
            const RowDivider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 11),
              child: Row(
                children: [
                  Text(name, style: AppText.style(14, color: AppColors.ink4)),
                  const SizedBox(width: 12),
                  Expanded(child: Align(alignment: Alignment.centerRight, child: value)),
                ],
              ),
            ),
          ],
        );

    final Widget footer = switch (data.status) {
      ProposalStatus.proposed => Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
          child: Row(
            children: [
              Expanded(
                flex: 13,
                child: AppButton(
                  label: 'Confirm expense',
                  icon: LucideIcons.check,
                  onTap: () => state.confirmProposal(messageId),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 10,
                child: AppButton(
                  label: 'Edit details',
                  style: AppButtonStyle.outline,
                  onTap: () => state.editProposal(messageId),
                ),
              ),
            ],
          ),
        ),
      ProposalStatus.saving => Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
          child: Container(
            height: 46,
            decoration: BoxDecoration(color: AppColors.primarySaving, borderRadius: BorderRadius.circular(15)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spinner(),
                const SizedBox(width: 10),
                Text('Saving to your account…', style: AppText.style(14, weight: 600, color: AppColors.white)),
              ],
            ),
          ),
        ),
      ProposalStatus.saved => Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
          child: Pressable(
            onTap: () => state.openDetail(tx.id, showInTransactions: true),
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            color: AppColors.white,
            pressedColor: AppColors.surfacePressed,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.border),
            child: Row(
              children: [
                Expanded(
                  child: Text('View in Transactions', style: AppText.style(14, weight: 600, color: AppColors.primary)),
                ),
                const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.primary),
              ],
            ),
          ),
        ),
      ProposalStatus.failed => Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'The server didn’t respond, so nothing was saved.',
                style: AppText.style(13.5, color: AppColors.error, height: 1.45),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Try again',
                      icon: LucideIcons.refreshCw,
                      iconSize: 15,
                      onTap: () => state.confirmProposal(messageId),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppButton(
                      label: 'Edit details',
                      style: AppButtonStyle.outline,
                      onTap: () => state.editProposal(messageId),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
    };

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: bg,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                if (data.status == ProposalStatus.saving)
                  Spinner(size: 13, color: fg, trackColor: fg.withValues(alpha: 0.2))
                else
                  Icon(icon, size: 14, color: fg),
                const SizedBox(width: 7),
                Expanded(child: Text(label, style: AppText.style(12.5, weight: 600, color: fg))),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 110),
                  child: Text('add_expense', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.mono(11)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Amount', style: AppText.style(12.5, color: AppColors.ink4)),
                const SizedBox(height: 2),
                Text(
                  state.displayMoney(tx.amount),
                  style: AppText.style(30, weight: 600, width: 125, tracking: -0.02, tabular: true),
                ),
                const SizedBox(height: 8),
                detailRow('Description', Text(tx.desc, style: AppText.style(14, weight: 500))),
                detailRow(
                  'Category',
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(cat.icon, size: 15, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(cat.label, style: AppText.style(14, weight: 500)),
                    ],
                  ),
                ),
                detailRow('Date', Text(dateText, style: AppText.style(14, weight: 500))),
              ],
            ),
          ),
          footer,
        ],
      ),
    );
  }
}

/// A spending answer: total, optional trend chip, per-row bars and provenance.
class SummaryCardView extends StatelessWidget {
  const SummaryCardView(this.data, {super.key});

  final SummaryCardData data;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final base = data.total == 0 ? 1.0 : data.total;
    return AppCard(
      radius: 22,
      padding: const EdgeInsets.all(16),
      borderColor: AppColors.borderSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(data.title, style: AppText.style(12.5, weight: 600, color: AppColors.ink2))),
              const SizedBox(width: 8),
              Text(data.range, style: AppText.style(12.5, color: AppColors.ink4)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            state.displayMoney(data.total),
            style: AppText.style(30, weight: 600, width: 125, tracking: -0.02, height: 1, tabular: true),
          ),
          if (data.sub != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
              decoration: BoxDecoration(color: AppColors.tintStrong, borderRadius: BorderRadius.circular(999)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(data.subDown ? LucideIcons.trendingDown : LucideIcons.trendingUp, size: 13, color: AppColors.deep),
                  const SizedBox(width: 5),
                  Text(data.sub!, style: AppText.style(12, weight: 600, color: AppColors.deep)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          for (final (i, r) in data.rows.indexed) ...[
            if (i > 0) const SizedBox(height: 11),
            Row(
              children: [
                Expanded(child: Text(r.label, style: AppText.style(13.5, color: AppColors.ink2))),
                const SizedBox(width: 8),
                Text(state.displayMoney(r.amount), style: AppText.style(13.5, weight: 600, tabular: true)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: SizedBox(
                height: 6,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const ColoredBox(color: AppColors.divider),
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: (r.amount / base).clamp(0.0, 1.0),
                      child: DecoratedBox(
                        decoration: BoxDecoration(color: r.color, borderRadius: BorderRadius.circular(3)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          const RowDivider(),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(LucideIcons.database, size: 13, color: AppColors.ink3),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Calculated from ${data.count} recorded transaction${data.count == 1 ? '' : 's'}',
                  style: AppText.style(11.5, color: AppColors.ink3),
                ),
              ),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 150),
                child: Text(
                  data.tool,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.mono(10.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "Thinking" row: bouncing dots, what the assistant is doing, and the tool.
class BusyRow extends StatelessWidget {
  const BusyRow(this.busy, {super.key});

  final BusyState busy;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _AiAvatar(),
        const SizedBox(width: 10),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderSoft),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const TypingDots(),
                    const SizedBox(width: 10),
                    Flexible(child: Text(busy.label, style: AppText.style(13.5, color: AppColors.ink2))),
                  ],
                ),
                if (busy.tool != null) ...[
                  const SizedBox(height: 7),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.toolChip, borderRadius: BorderRadius.circular(6)),
                    child: Text(busy.tool!, style: AppText.mono(11, color: AppColors.ink2)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
