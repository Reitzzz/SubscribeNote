import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dingxiaoyue/domain.dart';
import 'package:dingxiaoyue/store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const rates = {'CNY': 1000000, 'USD': 7000000};
  test('integer money, conversion, month end and leap year', () {
    expect(parseFixed('0.29', 2), 29);
    expect(money(9999999999999999), '¥99999999999999.99');
    expect(parseFixed('99999999.00', 2), 9999999900);
    expect(() => parseFixed('1.001', 2), throwsFormatException);
    expect(() => parseFixed('-1', 2), throwsFormatException);
    expect(() => parseFixed('NaN', 2), throwsFormatException);
    expect(() => parseFixed('100000000', 2), throwsFormatException);
    expect(convert(29, 'USD', rates), 203);
    expect(convert(100, 'JPY', rates), null);
    expect(addMonths(DateTime.utc(2024, 1, 31), 1), DateTime.utc(2024, 2, 29));
    expect(addMonths(DateTime.utc(2024, 2, 29), 12), DateTime.utc(2025, 2, 28));
    final s = Subscription(
      name: 'Test',
      category: '其他',
      start: DateTime.utc(2025, 1, 31),
      amount: 29,
    );
    final bills = schedule(s, DateTime.utc(2025, 3, 31), rates);
    expect(bills.map((c) => dateText(c.date)), [
      '2025.01.31',
      '2025.02.28',
      '2025.03.31',
    ]);
    expect(bills.fold<int>(0, (s, c) => s + c.amount), 87);
  });
  test('discount ends, upgrades, scheduled changes and stop boundaries', () {
    final start = DateTime.utc(2026, 1, 1);
    final s = Subscription(
      name: 'Test',
      category: 'AI',
      start: start,
      amount: 2000,
      trialCount: 2,
      trialAmount: 500,
    );
    expect(schedule(s, DateTime.utc(2026, 3, 1), rates).map((c) => c.amount), [
      500,
      500,
      2000,
    ]);
    final days = Subscription(
      name: 'Trial',
      category: 'AI',
      start: start,
      amount: 2000,
      trialCount: 7,
      trialDays: true,
      trialAmount: 0,
    );
    expect(
      schedule(
        days,
        DateTime.utc(2026, 2, 8),
        rates,
      ).map((c) => dateText(c.date)),
      ['2026.01.01', '2026.01.08', '2026.02.08'],
    );
    final upgrade = Subscription(
      name: 'Upgrade',
      category: 'AI',
      start: start,
      amount: 1000,
      events: [
        PlanEvent(
          type: 'upgrade',
          date: DateTime.utc(2026, 1, 15),
          amount: 2000,
          difference: 500,
        ),
      ],
    );
    expect(
      schedule(upgrade, DateTime.utc(2026, 2, 1), rates).map((c) => c.amount),
      [1000, 500, 2000],
    );
    final reset = upgrade.copy(
      events: [
        PlanEvent(
          type: 'upgrade',
          date: DateTime.utc(2026, 1, 15),
          amount: 2000,
          difference: 500,
          reset: true,
        ),
      ],
    );
    expect(
      schedule(
        reset,
        DateTime.utc(2026, 2, 15),
        rates,
      ).map((c) => dateText(c.date)),
      ['2026.01.01', '2026.01.15', '2026.02.15'],
    );
    final changed = upgrade.copy(
      events: [
        PlanEvent(
          type: 'change',
          date: DateTime.utc(2026, 2, 1),
          amount: 3000,
          months: 3,
        ),
        PlanEvent(type: 'stop', date: DateTime.utc(2026, 5, 31)),
      ],
    );
    expect(
      schedule(changed, DateTime.utc(2026, 12, 31), rates).map((c) => c.amount),
      [1000, 3000, 3000],
    );
    final manual = Subscription(
      name: 'Manual',
      category: '其他',
      start: start,
      amount: 1200,
      manual: true,
      events: [
        PlanEvent(
          type: 'renew',
          date: DateTime.utc(2026, 1, 20),
          amount: 1000,
          months: 2,
        ),
      ],
    );
    expect(manual.expiry, DateTime.utc(2026, 4, 1));
    expect(manual.monthly(rates, DateTime.utc(2026, 2, 15)), 500);
    expect(schedule(manual, DateTime.utc(2026, 12, 31), rates).length, 2);
  });
  test(
    'SQLite reopen preserves records, settings and booked FX; samples seed once',
    () async {
      final temp = await Directory.systemTemp.createTemp('dingxiaoyue-test-');
      final file = File('${temp.path}/demo.sqlite');
      var db = AppDatabase(NativeDatabase(file));
      var container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      final initial = await container.read(storeProvider.future);
      expect(initial.subscriptions.length, 8);
      final s = Subscription(
        name: 'Persistent',
        category: 'AI',
        start: day(DateTime.now()),
        amount: 101,
        currency: 'USD',
      );
      await container.read(storeProvider.notifier).save(s);
      final old = container
          .read(storeProvider)
          .requireValue
          .charges
          .firstWhere((c) => c.subscriptionId == s.id)
          .cny;
      await container.read(storeProvider.notifier).saveRates({
        'CNY': 1000000,
        'USD': 9000000,
      });
      await container.read(storeProvider.notifier).setting('nickname', '测试用户');
      container.dispose();
      await db.close();
      db = AppDatabase(NativeDatabase(file));
      container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      final reopened = await container.read(storeProvider.future);
      expect(reopened.subscriptions.length, 9);
      expect(reopened.settings['nickname'], '测试用户');
      expect(
        reopened.charges.firstWhere((c) => c.subscriptionId == s.id).cny,
        old,
      );
      expect(reopened.rates['USD'], 9000000);
      container.dispose();
      await db.close();
      await temp.delete(recursive: true);
    },
  );
  test('canceling a future stop preserves the original billing schedule', () {
    final stop = PlanEvent(type: 'stop', date: DateTime.utc(2026, 1, 31));
    final s = Subscription(
      name: 'Cancel',
      category: 'AI',
      start: DateTime.utc(2026, 1, 1),
      amount: 1000,
      events: [
        stop,
        PlanEvent(
          type: 'cancel',
          date: DateTime.utc(2026, 1, 15),
          note: stop.id,
        ),
      ],
    );
    expect(s.stopDate(DateTime.utc(2026, 1, 15)), isNull);
    expect(
      schedule(s, DateTime.utc(2026, 3, 1), rates).map((c) => dateText(c.date)),
      ['2026.01.01', '2026.02.01', '2026.03.01'],
    );
  });
}
