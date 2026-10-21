import '../models/category.dart';
import '../models/transaction.dart';

/// "Today" for the mock data set. Kept fixed so the seeded history, week chart
/// and month comparison stay coherent. Swap for `DateTime.now()` once real
/// data is wired in.
final kToday = DateTime(2026, 10, 13);

const kUserFirstName = 'Adaeze';
const kUserInitials = 'AO';
const kAppVersion = 'SpendWise AI · version 0.9 (workshop build)';

Transaction _tx(
  String id,
  String desc,
  ExpenseCategory category,
  double amount,
  int month,
  int day,
  String time, {
  String note = '',
  TxSource source = TxSource.manual,
}) {
  return Transaction(
    id: id,
    desc: desc,
    category: category,
    amount: amount,
    date: DateTime(2026, month, day),
    time: time,
    note: note,
    source: source,
  );
}

final List<Transaction> baseTransactions = [
  _tx('b1', 'Bolt ride', ExpenseCategory.transport, 2000, 10, 13, '08:12', note: 'Home to Victoria Island'),
  _tx('b2', 'Groceries', ExpenseCategory.food, 12500, 10, 12, '18:40', note: 'Shoprite, Lekki'),
  _tx('b3', 'Internet subscription', ExpenseCategory.bills, 5000, 10, 11, '09:00', note: 'Home Wi-Fi, monthly'),
  _tx('b4', 'Suya', ExpenseCategory.food, 3000, 10, 10, '20:15'),
  _tx('b5', 'Lunch', ExpenseCategory.food, 3500, 10, 10, '13:05', note: 'Amala spot near the office', source: TxSource.ai),
  _tx('b6', 'BRT bus', ExpenseCategory.transport, 1200, 10, 10, '07:50'),
  _tx('b7', 'Electricity token', ExpenseCategory.bills, 15000, 10, 9, '19:30'),
  _tx('b8', 'Sneakers', ExpenseCategory.shopping, 28000, 10, 8, '16:20'),
  _tx('b9', 'Uber to Lekki', ExpenseCategory.transport, 4800, 10, 7, '21:10', source: TxSource.ai),
  _tx('b10', 'Market groceries', ExpenseCategory.food, 9800, 10, 6, '10:30'),
  _tx('b11', 'Cinema tickets', ExpenseCategory.other, 6000, 10, 5, '17:45'),
  _tx('b12', 'Fuel', ExpenseCategory.transport, 10000, 10, 4, '11:15'),
  _tx('b13', 'DStv subscription', ExpenseCategory.bills, 12000, 10, 3, '08:00'),
  _tx('b14', 'Airtime & data', ExpenseCategory.bills, 3000, 10, 2, '12:00'),
  _tx('b15', 'Chicken Republic', ExpenseCategory.food, 4200, 10, 1, '13:30'),
  _tx('b16', 'Haircut', ExpenseCategory.other, 3500, 10, 1, '15:00'),
  // 1–13 Sep: together ₦139,200, the figure the prototype compares October against.
  _tx('p1', 'DStv subscription', ExpenseCategory.bills, 12000, 9, 1, '08:00'),
  _tx('p2', 'Groceries', ExpenseCategory.food, 14200, 9, 2, '18:10'),
  _tx('p3', 'Fuel', ExpenseCategory.transport, 10000, 9, 3, '09:15'),
  _tx('p4', 'Electricity token', ExpenseCategory.bills, 15000, 9, 4, '19:20'),
  _tx('p5', 'Dinner out', ExpenseCategory.food, 8500, 9, 5, '20:00'),
  _tx('p6', 'Uber rides', ExpenseCategory.transport, 7000, 9, 6, '21:30'),
  _tx('p7', 'Weekend groceries', ExpenseCategory.food, 14500, 9, 7, '11:00'),
  _tx('p8', 'Shoes', ExpenseCategory.shopping, 32000, 9, 8, '15:45'),
  _tx('p9', 'Airtime & data', ExpenseCategory.bills, 3000, 9, 9, '12:00'),
  _tx('p10', 'Market groceries', ExpenseCategory.food, 9500, 9, 10, '10:30'),
  _tx('p11', 'Cinema tickets', ExpenseCategory.other, 5000, 9, 11, '17:45'),
  _tx('p12', 'Internet subscription', ExpenseCategory.bills, 5000, 9, 12, '09:00'),
  _tx('p13', 'Haircut', ExpenseCategory.other, 3500, 9, 13, '15:00'),
  _tx('s1', 'Groceries', ExpenseCategory.food, 11000, 9, 28, '17:20', note: 'Spar, Ikeja'),
  _tx('s2', 'Fuel', ExpenseCategory.transport, 10000, 9, 25, '09:40'),
  _tx('s3', 'Jeans', ExpenseCategory.shopping, 18500, 9, 20, '14:10'),
  _tx('s4', 'Electricity token', ExpenseCategory.bills, 15000, 9, 15, '19:05'),
];

/// The lunch expense recorded through Ask SpendWise in most design states.
final lunchTransaction = _tx('ai-lunch', 'Lunch', ExpenseCategory.food, 4500, 10, 13, '13:20', source: TxSource.ai);

/// The seed data moved so it makes sense on [today] (used when seeding a real
/// database): recent October rows keep their distance from "today", earlier
/// rows stay in the previous month, and nothing lands before the 1st.
List<Transaction> demoTransactionsFor(DateTime today) {
  final firstOfMonth = DateTime(today.year, today.month, 1);
  final daysInPrevMonth = DateTime(today.year, today.month, 0).day;

  DateTime place(DateTime original) {
    if (original.month == kToday.month) {
      final moved = DateTime(today.year, today.month, today.day + (original.day - kToday.day));
      return moved.isBefore(firstOfMonth) ? firstOfMonth : moved;
    }
    final day = original.day < daysInPrevMonth ? original.day : daysInPrevMonth;
    return DateTime(today.year, today.month - 1, day);
  }

  return [for (final t in [...baseTransactions, lunchTransaction]) t.copyWith(date: place(t.date))];
}
