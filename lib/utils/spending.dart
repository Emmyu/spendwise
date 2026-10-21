import '../models/category.dart';
import '../models/transaction.dart';

double sumOf(Iterable<Transaction> items) => items.fold(0, (s, t) => s + t.amount);

class CategoryTotal {
  const CategoryTotal(this.category, this.amount);

  final ExpenseCategory category;
  final double amount;
}

/// Totals per category, largest first. Ties keep the category display order.
List<CategoryTotal> categoryBreakdown(Iterable<Transaction> items) {
  final rows = [
    for (final c in ExpenseCategory.values)
      CategoryTotal(c, sumOf(items.where((t) => t.category == c))),
  ].where((r) => r.amount > 0).toList();
  final order = {for (final (i, r) in rows.indexed) r.category: i};
  rows.sort((a, b) {
    final byAmount = b.amount.compareTo(a.amount);
    return byAmount != 0 ? byAmount : order[a.category]!.compareTo(order[b.category]!);
  });
  return rows;
}

/// Newest first, stable for equal timestamps.
List<Transaction> sortNewestFirst(Iterable<Transaction> items) {
  final list = items.indexed.toList();
  list.sort((a, b) {
    final byKey = b.$2.sortKey.compareTo(a.$2.sortKey);
    return byKey != 0 ? byKey : a.$1.compareTo(b.$1);
  });
  return [for (final e in list) e.$2];
}

/// What was spent in the previous month over the same days (1–today's day).
/// "Last month" for the month-to-date comparison.
double previousPeriodTotal(Iterable<Transaction> items, DateTime today) {
  final prev = DateTime(today.year, today.month - 1);
  return sumOf(items.where((t) => t.date.year == prev.year && t.date.month == prev.month && t.date.day <= today.day));
}
