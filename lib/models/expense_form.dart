import 'package:flutter/foundation.dart';

import 'category.dart';

enum FormMode {
  /// Manually adding a new expense.
  create,

  /// Editing a saved transaction.
  edit,

  /// Editing an AI-prepared proposal before it is confirmed in the chat.
  ai,
}

const _unset = Object();

@immutable
class ExpenseFormData {
  const ExpenseFormData({
    required this.mode,
    required this.amount,
    required this.desc,
    required this.category,
    required this.date,
    required this.note,
    this.target,
    this.amountError,
    this.descError,
    this.saving = false,
  });

  final FormMode mode;

  /// Raw text from the amount field, e.g. "4,500".
  final String amount;
  final String desc;
  final ExpenseCategory category;
  final DateTime date;
  final String note;

  /// Transaction id (edit) or chat message id (ai).
  final String? target;
  final String? amountError;
  final String? descError;
  final bool saving;

  ExpenseFormData copyWith({
    String? amount,
    String? desc,
    ExpenseCategory? category,
    DateTime? date,
    String? note,
    Object? amountError = _unset,
    Object? descError = _unset,
    bool? saving,
  }) {
    return ExpenseFormData(
      mode: mode,
      target: target,
      amount: amount ?? this.amount,
      desc: desc ?? this.desc,
      category: category ?? this.category,
      date: date ?? this.date,
      note: note ?? this.note,
      amountError: identical(amountError, _unset) ? this.amountError : amountError as String?,
      descError: identical(descError, _unset) ? this.descError : descError as String?,
      saving: saving ?? this.saving,
    );
  }
}
