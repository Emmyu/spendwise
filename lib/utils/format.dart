import '../data/mock_data.dart';
import 'dates.dart';

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _monthsLong = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

/// Text shown instead of an amount when amounts are hidden.
const maskedMoney = '₦ ••••';

String _groupThousands(int value) {
  final digits = value.abs().toString();
  final buf = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  return buf.toString();
}

/// "₦12,500"
String money(num n) => '₦${_groupThousands(n.round())}';

/// "12,500", the amount without the currency sign (used to prefill the form).
String plainAmount(num n) => _groupThousands(n.round());

/// Compact chart label: "₦12.5k", "₦800" or "–" for zero.
String moneyK(num n) {
  if (n == 0) return '–';
  if (n >= 1000) {
    final k = (n / 1000).toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');
    return '₦${k}k';
  }
  return '₦${n.round()}';
}

String weekdayShort(DateTime d) => _weekdays[d.weekday - 1];
String monthShort(DateTime d) => _months[d.month - 1];
String monthLong(DateTime d) => _monthsLong[d.month - 1];

/// "13 Oct"
String shortDate(DateTime d) => '${d.day} ${monthShort(d)}';

/// "Tue, 13 Oct 2026"
String longDate(DateTime d) => '${weekdayShort(d)}, ${d.day} ${monthShort(d)} ${d.year}';

/// "Today", "Yesterday" or "Sat, 10 Oct", relative to [today].
String dayLabel(DateTime d, {DateTime? today}) {
  final t = today ?? kToday;
  if (isSameDay(d, t)) return 'Today';
  if (isSameDay(d, addDays(t, -1))) return 'Yesterday';
  return '${weekdayShort(d)}, ${d.day} ${monthShort(d)}';
}

/// "October 2026"
String monthLabel(DateTime d) => '${monthLong(d)} ${d.year}';

/// "13:20" → "1:20 PM"
String time12(String hhmm) {
  if (hhmm.isEmpty) return '';
  final parts = hhmm.split(':');
  final h = int.parse(parts[0]);
  final m = int.parse(parts[1]);
  final ap = h >= 12 ? 'PM' : 'AM';
  final h12 = h % 12 == 0 ? 12 : h % 12;
  return '$h12:${m.toString().padLeft(2, '0')} $ap';
}

/// Current wall-clock time as "HH:mm".
String nowTime() {
  final n = DateTime.now();
  return '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}';
}

/// Month-to-date label: "1–13 Oct".
String monthToDateLabel(DateTime today) => '1–${today.day} ${monthShort(today)}';

/// Same span in the previous month: "1–13 Sep".
String previousMonthToDateLabel(DateTime today) =>
    '1–${today.day} ${monthShort(DateTime(today.year, today.month - 1))}';

/// "Mon 12 – Tue 13 Oct" for the current week up to [today].
String weekToDateLabel(DateTime today) {
  final start = startOfWeek(today);
  final end = '${weekdayShort(today)} ${today.day} ${monthShort(today)}';
  if (isSameDay(start, today)) return end;
  final startMonth = start.month == today.month ? '' : ' ${monthShort(start)}';
  return '${weekdayShort(start)} ${start.day}$startMonth – $end';
}

/// Mimics JavaScript's `parseFloat`: reads the leading number, ignoring the rest.
double? parseLeadingNumber(String s) {
  final m = RegExp(r'^\s*([-+]?(\d+\.?\d*|\.\d+))').firstMatch(s);
  return m == null ? null : double.tryParse(m.group(1)!);
}

/// "Good morning" / "Good afternoon" / "Good evening".
String greeting(DateTime now) {
  if (now.hour < 12) return 'Good morning';
  if (now.hour < 17) return 'Good afternoon';
  return 'Good evening';
}
