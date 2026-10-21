import 'package:flutter_test/flutter_test.dart';
import 'package:spendwise/state/app_state.dart';
import 'package:spendwise/utils/format.dart';

void main() {
  final today = DateTime(2026, 10, 13);

  test('money groups thousands with the naira sign', () {
    expect(money(12500), '₦12,500');
    expect(money(128000), '₦128,000');
    expect(money(1234567), '₦1,234,567');
    expect(money(800), '₦800');
    expect(money(9846.15), '₦9,846');
  });

  test('moneyK compacts chart labels', () {
    expect(moneyK(12500), '₦12.5k');
    expect(moneyK(15000), '₦15k');
    expect(moneyK(800), '₦800');
    expect(moneyK(0), '–');
  });

  test('dayLabel is relative to today', () {
    expect(dayLabel(today, today: today), 'Today');
    expect(dayLabel(DateTime(2026, 10, 12), today: today), 'Yesterday');
    expect(dayLabel(DateTime(2026, 10, 10), today: today), 'Sat, 10 Oct');
  });

  test('date labels', () {
    expect(shortDate(today), '13 Oct');
    expect(longDate(today), 'Tue, 13 Oct 2026');
    expect(monthLabel(today), 'October 2026');
    expect(monthToDateLabel(today), '1–13 Oct');
    expect(previousMonthToDateLabel(today), '1–13 Sep');
    expect(weekToDateLabel(today), 'Mon 12 – Tue 13 Oct');
  });

  test('time12 converts 24-hour times', () {
    expect(time12('13:20'), '1:20 PM');
    expect(time12('08:12'), '8:12 AM');
    expect(time12('00:05'), '12:05 AM');
    expect(time12('12:00'), '12:00 PM');
  });

  test('parseLeadingNumber behaves like parseFloat', () {
    expect(parseLeadingNumber('4500'), 4500);
    expect(parseLeadingNumber('12.5'), 12.5);
    expect(parseLeadingNumber('1.2.3'), 1.2);
    expect(parseLeadingNumber('abc'), isNull);
  });

  test('amountInputText prefills the form', () {
    expect(amountInputText(4500), '4,500');
    expect(amountInputText(12.5), '12.5');
  });
}
