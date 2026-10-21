import 'package:flutter/foundation.dart';

import '../utils/dates.dart';
import 'category.dart';

enum TxSource { manual, ai }

@immutable
class Transaction {
  const Transaction({
    required this.id,
    required this.desc,
    required this.category,
    required this.amount,
    required this.date,
    required this.time,
    this.note = '',
    this.source = TxSource.manual,
  });

  final String id;
  final String desc;
  final ExpenseCategory category;
  final double amount;

  /// Calendar day (time component is always midnight).
  final DateTime date;

  /// 24-hour "HH:mm".
  final String time;
  final String note;
  final TxSource source;

  bool get isAi => source == TxSource.ai;

  /// Sort key matching the prototype's `date + time` string comparison.
  String get sortKey => '${isoDate(date)}$time';

  Transaction copyWith({
    String? id,
    String? desc,
    ExpenseCategory? category,
    double? amount,
    DateTime? date,
    String? time,
    String? note,
    TxSource? source,
  }) {
    return Transaction(
      id: id ?? this.id,
      desc: desc ?? this.desc,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      time: time ?? this.time,
      note: note ?? this.note,
      source: source ?? this.source,
    );
  }
}

/// Fields a user can change when editing an expense.
@immutable
class TransactionEdit {
  const TransactionEdit({
    required this.desc,
    required this.category,
    required this.amount,
    required this.date,
    required this.note,
  });

  final String desc;
  final ExpenseCategory category;
  final double amount;
  final DateTime date;
  final String note;

  Transaction applyTo(Transaction tx) =>
      tx.copyWith(desc: desc, category: category, amount: amount, date: date, note: note);
}
