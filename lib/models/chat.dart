import 'package:flutter/painting.dart';
import 'package:flutter/foundation.dart';

import 'transaction.dart';

enum ChatRole { user, ai }

enum ProposalStatus { proposed, saving, saved, failed }

@immutable
class ProposalCardData {
  const ProposalCardData({required this.status, required this.tx});

  final ProposalStatus status;
  final Transaction tx;

  ProposalCardData copyWith({ProposalStatus? status, Transaction? tx}) =>
      ProposalCardData(status: status ?? this.status, tx: tx ?? this.tx);
}

@immutable
class SummaryRow {
  const SummaryRow({required this.label, required this.amount, required this.color});

  final String label;
  final double amount;
  final Color color;
}

@immutable
class SummaryCardData {
  const SummaryCardData({
    required this.title,
    required this.range,
    required this.total,
    required this.rows,
    required this.count,
    required this.tool,
    this.sub,
    this.subDown = false,
  });

  final String title;
  final String range;
  final double total;
  final List<SummaryRow> rows;

  /// Number of transactions the figures were calculated from.
  final int count;

  /// Name of the backend tool that would produce this, e.g. `get_spending_summary`.
  final String tool;

  /// Optional trend chip text, e.g. "8% less than ₦139,200".
  final String? sub;
  final bool subDown;
}

@immutable
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    this.text = '',
    this.chips = const [],
    this.proposal,
    this.summary,
  });

  const ChatMessage.user(this.id, this.text)
      : role = ChatRole.user,
        chips = const [],
        proposal = null,
        summary = null;

  final String id;
  final ChatRole role;
  final String text;
  final List<String> chips;
  final ProposalCardData? proposal;
  final SummaryCardData? summary;

  bool get isUser => role == ChatRole.user;

  ChatMessage withProposal(ProposalCardData proposal) => ChatMessage(
        id: id,
        role: role,
        text: text,
        chips: chips,
        proposal: proposal,
        summary: summary,
      );
}

/// The "thinking" row shown while the assistant works.
@immutable
class BusyState {
  const BusyState(this.label, {this.tool, this.frozen = false});

  final String label;
  final String? tool;

  /// Design-state only: a frozen busy row never resolves and doesn't block sending.
  final bool frozen;
}
