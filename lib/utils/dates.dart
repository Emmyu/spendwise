DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime addDays(DateTime d, int days) => DateTime(d.year, d.month, d.day + days);

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

bool isSameMonth(DateTime a, DateTime b) => a.year == b.year && a.month == b.month;

/// Monday of the week containing [d].
DateTime startOfWeek(DateTime d) => addDays(dateOnly(d), -(d.weekday - 1));

String _two(int n) => n.toString().padLeft(2, '0');

/// "2026-10-13"
String isoDate(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';

/// "2026-10"
String isoMonth(DateTime d) => '${d.year}-${_two(d.month)}';
