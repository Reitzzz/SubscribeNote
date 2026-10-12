import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'domain.dart';

class AppDatabase extends GeneratedDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'dingxiaoyue'));
  @override
  int get schemaVersion => 1;
  @override
  Iterable<TableInfo<Table, Object?>> get allTables => const [];
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => const [];
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await customStatement(
        'CREATE TABLE subscriptions (id TEXT PRIMARY KEY, payload TEXT NOT NULL, device_id TEXT NOT NULL)',
      );
      await customStatement(
        'CREATE TABLE events (id TEXT PRIMARY KEY, subscription_id TEXT NOT NULL REFERENCES subscriptions(id), payload TEXT NOT NULL)',
      );
      await customStatement(
        'CREATE TABLE charges (id TEXT PRIMARY KEY, subscription_id TEXT NOT NULL REFERENCES subscriptions(id), payload TEXT NOT NULL)',
      );
      await customStatement(
        'CREATE TABLE settings (id TEXT PRIMARY KEY, payload TEXT NOT NULL)',
      );
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

class AppData {
  AppData(this.subscriptions, this.charges, this.settings);
  final List<Subscription> subscriptions;
  final List<Charge> charges;
  final Map<String, dynamic> settings;
  Map<String, int> get rates => Map<String, int>.from(settings['rates'] as Map);
  String get displayCurrency => settings['currency'] as String? ?? 'CNY';
  int? display(int? cny) => cny == null || rates[displayCurrency] == null
      ? null
      : roundedRatio(cny, 1000000, rates[displayCurrency]!);
  String format(int? cny) => money(display(cny), displayCurrency);
  List<Charge> entries(DateTime through, DateTime now) {
    final ids = subscriptions.map((s) => s.id).toSet();
    return [
      ...charges.where(
        (c) => ids.contains(c.subscriptionId) && !c.date.isAfter(through),
      ),
      for (final s in subscriptions)
        ...schedule(s, through, rates).where((c) => c.date.isAfter(now)),
    ];
  }

  int? monthly(Subscription s, DateTime now) => s.active(now)
      ? convert(s.monthly(rates, now), s.terms(now).currency, rates)
      : 0;
}

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
final storeProvider = AsyncNotifierProvider<Store, AppData>(Store.new);

class Store extends AsyncNotifier<AppData> {
  AppDatabase get db => ref.read(databaseProvider);
  DateTime get today => day(DateTime.now());
  @override
  Future<AppData> build() async {
    await seed();
    await bookDue(await read());
    return read();
  }

  Future<AppData> read() async {
    final eventRows = await db
        .customSelect('SELECT payload FROM events ORDER BY rowid')
        .get();
    final grouped = <String, List<PlanEvent>>{};
    for (final row in eventRows) {
      final j = jsonDecode(row.read<String>('payload')) as Map<String, dynamic>;
      (grouped[j['subscriptionId']] ??= []).add(PlanEvent.fromJson(j));
    }
    final rows = await db
        .customSelect('SELECT payload FROM subscriptions ORDER BY rowid DESC')
        .get();
    final subscriptions = rows
        .map((r) {
          final j =
              jsonDecode(r.read<String>('payload')) as Map<String, dynamic>;
          return Subscription.fromJson(j, grouped[j['id']] ?? []);
        })
        .where((s) => s.deletedAt == null)
        .toList();
    final charges = await db.customSelect('SELECT payload FROM charges').get();
    final settings = await db
        .customSelect('SELECT id,payload FROM settings')
        .get();
    return AppData(
      subscriptions,
      charges
          .map((r) => Charge.fromJson(jsonDecode(r.read<String>('payload'))))
          .toList(),
      {
        for (final r in settings)
          r.read<String>('id'): jsonDecode(r.read<String>('payload')),
      },
    );
  }

  Future<void> writeSetting(String key, Object? value) => db.customStatement(
    'INSERT INTO settings(id,payload) VALUES (?,?) ON CONFLICT(id) DO UPDATE SET payload=excluded.payload',
    [key, encode(value)],
  );
  Future<void> writeSubscription(Subscription s, String deviceId) async {
    await db.customStatement(
      'INSERT INTO subscriptions(id,payload,device_id) VALUES (?,?,?) ON CONFLICT(id) DO UPDATE SET payload=excluded.payload,device_id=excluded.device_id',
      [s.id, encode(s.toJson()), deviceId],
    );
    for (final e in s.events) {
      await db.customStatement(
        'INSERT OR IGNORE INTO events(id,subscription_id,payload) VALUES (?,?,?)',
        [
          e.id,
          s.id,
          encode({
            ...e.toJson(),
            'subscriptionId': s.id,
            'updatedAt': s.updatedAt.toIso8601String(),
            'deletedAt': null,
            'version': 1,
            'deviceId': deviceId,
          }),
        ],
      );
    }
  }

  Future<void> bookDue(AppData data) async {
    for (final s in data.subscriptions) {
      for (final c in schedule(s, today, data.rates)) {
        await db.customStatement(
          'INSERT OR IGNORE INTO charges(id,subscription_id,payload) VALUES (?,?,?)',
          [c.id, s.id, encode(c.toJson())],
        );
      }
    }
  }

  Future<void> save(Subscription s) async {
    await db.transaction(() async {
      await writeSubscription(s, state.requireValue.settings['deviceId']);
      await bookDue(await read());
    });
    state = AsyncData(await read());
  }

  Future<void> setting(String key, Object? value) async {
    await writeSetting(key, value);
    state = AsyncData(await read());
  }

  Future<void> saveRates(Map<String, int> rates) async {
    await db.transaction(() async {
      await bookDue(await read());
      await writeSetting('rates', rates);
      await writeSetting('rateSource', '手动维护');
      await writeSetting('rateUpdatedAt', DateTime.now().toIso8601String());
    });
    state = AsyncData(await read());
  }

  Future<void> seed() async {
    if ((await db
            .customSelect("SELECT id FROM settings WHERE id='initialized'")
            .get())
        .isNotEmpty) {
      return;
    }
    final fixtures =
        jsonDecode(await rootBundle.loadString('assets/reference.json'))
            as Map<String, dynamic>;
    final samples = fixtures['subscriptions'] as Map<String, dynamic>;
    final device = newId();
    await db.transaction(() async {
      await writeSetting('deviceId', device);
      await writeSetting('rates', {
        'CNY': 1000000,
        'USD': 6782900,
        'JPY': 42200,
        'EUR': 7826700,
        'GBP': 9127800,
        'HKD': 865000,
      });
      await writeSetting('rateSource', '原型示例（非实时汇率）');
      await writeSetting('rateUpdatedAt', '2026-09-03T00:00:00Z');
      for (final entry in samples.entries.toList().reversed) {
        final j = entry.value as Map<String, dynamic>;
        final price = j['price'] as String;
        final s = Subscription(
          name: j['name'],
          category: j['category'],
          start: DateTime.parse((j['start'] as String).replaceAll('.', '-')),
          amount: parseFixed(RegExp(r'[\d.]+').firstMatch(price)!.group(0)!, 2),
          currency: price.substring(price.length - 3),
          months: entry.key == 'wps'
              ? 36
              : entry.key == 'anti' || entry.key == 'tencent'
              ? 12
              : entry.key == 'bilibili'
              ? 2
              : 1,
          manual: j['manual'] == true,
          icon: entry.key,
          color:
              0xff000000 |
              int.parse((j['color'] as String).substring(1), radix: 16),
          note: '',
          trialCount: entry.key == 'claude' ? 3 : 0,
          trialAmount: entry.key == 'claude' ? 2000 : 0,
        );
        await writeSubscription(s, device);
      }
      await writeSetting('initialized', true);
    });
  }
}
