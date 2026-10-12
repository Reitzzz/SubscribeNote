import 'dart:convert';
import 'dart:math';

String newId() {
  final bytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
  bytes[6] = (bytes[6] & 15) | 64;
  bytes[8] = (bytes[8] & 63) | 128;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

DateTime day(DateTime d) => DateTime.utc(d.year, d.month, d.day);
String dateText(DateTime d) =>
    '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
DateTime addMonths(DateTime d, int n) {
  final target = DateTime.utc(d.year, d.month + n);
  return DateTime.utc(
    target.year,
    target.month,
    min(d.day, DateTime.utc(target.year, target.month + 1, 0).day),
  );
}

int parseFixed(String input, int digits, {int maxWhole = 99999999}) {
  final text = input.trim();
  if (!RegExp('^\\d+(?:\\.\\d{1,$digits})?\$').hasMatch(text)) {
    throw FormatException('请输入非负数字，最多 $digits 位小数');
  }
  final parts = text.split('.');
  final scale = BigInt.from(pow(10, digits));
  final value =
      BigInt.parse(parts[0]) * scale +
      BigInt.parse((parts.length == 1 ? '' : parts[1]).padRight(digits, '0'));
  if (value > BigInt.from(maxWhole) * scale) {
    throw FormatException('金额不能超过 $maxWhole');
  }
  return value.toInt();
}

int roundedRatio(int value, int numerator, int denominator) {
  final v = BigInt.from(value) * BigInt.from(numerator);
  return ((v + BigInt.from(denominator ~/ 2)) ~/ BigInt.from(denominator))
      .toInt();
}

const currencySymbols = {
  'CNY': '¥',
  'USD': '\$',
  'JPY': '¥',
  'EUR': '€',
  'GBP': '£',
  'HKD': 'HK\$',
  'TWD': 'NT\$',
  'KRW': '₩',
  'SGD': 'S\$',
  'AUD': 'A\$',
  'CAD': 'C\$',
};
String money(int? cents, [String currency = 'CNY']) => cents == null
    ? '待换算'
    : '${currencySymbols[currency] ?? currency}${cents ~/ 100}.${(cents % 100).toString().padLeft(2, '0')}';
String cycleName(int months) =>
    {1: '每月', 3: '每季', 6: '每半年', 12: '每年'}[months] ?? '$months 个月';

class PlanEvent {
  PlanEvent({
    String? id,
    required this.type,
    required this.date,
    this.amount = 0,
    this.currency = 'CNY',
    this.months = 1,
    this.reset = false,
    this.difference = 0,
    this.end,
    this.note = '',
  }) : id = id ?? newId();
  final String id, type, currency, note;
  final DateTime date;
  final DateTime? end;
  final int amount, months, difference;
  final bool reset;
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'date': date.toIso8601String(),
    'amount': amount,
    'currency': currency,
    'months': months,
    'reset': reset,
    'difference': difference,
    'end': end?.toIso8601String(),
    'note': note,
  };
  factory PlanEvent.fromJson(Map<String, dynamic> j) => PlanEvent(
    id: j['id'],
    type: j['type'],
    date: DateTime.parse(j['date']),
    amount: j['amount'],
    currency: j['currency'],
    months: j['months'],
    reset: j['reset'],
    difference: j['difference'],
    end: j['end'] == null ? null : DateTime.parse(j['end']),
    note: j['note'],
  );
}

class Subscription {
  Subscription({
    String? id,
    required this.name,
    required this.category,
    required this.start,
    required this.amount,
    this.currency = 'CNY',
    this.months = 1,
    this.manual = false,
    this.icon = '',
    this.color = 0xffd97757,
    this.note = '',
    this.trialCount = 0,
    this.trialDays = false,
    this.trialAmount = 0,
    this.events = const [],
    this.version = 1,
    DateTime? updatedAt,
    this.deletedAt,
  }) : id = id ?? newId(),
       updatedAt = updatedAt ?? DateTime.now().toUtc();
  final String id, name, category, currency, icon, note;
  final DateTime start, updatedAt;
  final DateTime? deletedAt;
  final int amount, months, color, trialCount, trialAmount, version;
  final bool manual, trialDays;
  final List<PlanEvent> events;
  DateTime? get trialEnd => trialCount == 0
      ? null
      : trialDays
      ? start.add(Duration(days: trialCount))
      : addMonths(start, trialCount);
  List<PlanEvent> get orderedEvents =>
      [...events]..sort((a, b) => a.date.compareTo(b.date));
  List<PlanEvent> get billingEvents {
    final canceled = events
        .where((e) => e.type == 'cancel')
        .map((e) => e.note)
        .toSet();
    return orderedEvents.where((e) => !canceled.contains(e.id)).toList();
  }

  DateTime? stopDate(DateTime asOf) {
    DateTime? stop;
    for (final e in billingEvents) {
      if (e.type == 'stop') stop = e.date;
      if (e.type == 'resume' && !e.date.isAfter(asOf)) stop = null;
    }
    return stop;
  }

  DateTime get expiry {
    var value = addMonths(start, months);
    for (final e in orderedEvents.where((e) => e.type == 'renew')) {
      final base = value.isAfter(e.date) ? value : e.date;
      value = e.end ?? addMonths(base, e.months);
    }
    return value;
  }

  bool active(DateTime now) =>
      !start.isAfter(now) &&
      (manual
          ? now.isBefore(expiry)
          : stopDate(now) == null || !now.isAfter(stopDate(now)!));
  PlanEvent terms(DateTime at) {
    var term = PlanEvent(
      id: id,
      type: 'start',
      date: start,
      amount: amount,
      currency: currency,
      months: months,
    );
    var coverageEnd = addMonths(start, months);
    for (final e in billingEvents) {
      if (e.date.isAfter(at)) break;
      if (e.type == 'change' || e.type == 'upgrade') term = e;
      if (manual && e.type == 'renew') {
        final begin = coverageEnd.isAfter(e.date) ? coverageEnd : e.date;
        coverageEnd = e.end ?? addMonths(begin, e.months);
        if (!at.isBefore(begin)) term = e;
      }
    }
    return term;
  }

  int monthly(Map<String, int> rates, DateTime now) {
    if (!active(now)) return 0;
    final t = terms(now);
    final amountNow =
        t.type == 'start' && trialEnd != null && now.isBefore(trialEnd!)
        ? trialAmount
        : t.amount;
    return roundedRatio(amountNow, 1, t.months);
  }

  Subscription copy({
    String? name,
    String? category,
    String? icon,
    int? color,
    String? note,
    List<PlanEvent>? events,
    DateTime? deletedAt,
  }) => Subscription(
    id: id,
    name: name ?? this.name,
    category: category ?? this.category,
    start: start,
    amount: amount,
    currency: currency,
    months: months,
    manual: manual,
    icon: icon ?? this.icon,
    color: color ?? this.color,
    note: note ?? this.note,
    trialCount: trialCount,
    trialDays: trialDays,
    trialAmount: trialAmount,
    events: events ?? this.events,
    version: version + 1,
    deletedAt: deletedAt ?? this.deletedAt,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'start': start.toIso8601String(),
    'amount': amount,
    'currency': currency,
    'months': months,
    'manual': manual,
    'icon': icon,
    'color': color,
    'note': note,
    'trialCount': trialCount,
    'trialDays': trialDays,
    'trialAmount': trialAmount,
    'version': version,
    'updatedAt': updatedAt.toIso8601String(),
    'deletedAt': deletedAt?.toIso8601String(),
  };
  factory Subscription.fromJson(
    Map<String, dynamic> j,
    List<PlanEvent> events,
  ) => Subscription(
    id: j['id'],
    name: j['name'],
    category: j['category'],
    start: DateTime.parse(j['start']),
    amount: j['amount'],
    currency: j['currency'],
    months: j['months'],
    manual: j['manual'],
    icon: j['icon'],
    color: j['color'],
    note: j['note'],
    trialCount: j['trialCount'],
    trialDays: j['trialDays'],
    trialAmount: j['trialAmount'],
    version: j['version'],
    updatedAt: DateTime.parse(j['updatedAt']),
    deletedAt: j['deletedAt'] == null ? null : DateTime.parse(j['deletedAt']),
    events: events,
  );
}

class Charge {
  Charge(
    this.id,
    this.subscriptionId,
    this.date,
    this.amount,
    this.currency,
    this.cny,
    this.rate,
  );
  final String id, subscriptionId, currency;
  final DateTime date;
  final int amount;
  final int? cny, rate;
  Map<String, dynamic> toJson() => {
    'id': id,
    'subscriptionId': subscriptionId,
    'date': date.toIso8601String(),
    'amount': amount,
    'currency': currency,
    'cny': cny,
    'rate': rate,
  };
  factory Charge.fromJson(Map<String, dynamic> j) => Charge(
    j['id'],
    j['subscriptionId'],
    DateTime.parse(j['date']),
    j['amount'],
    j['currency'],
    j['cny'],
    j['rate'],
  );
}

int? convert(int amount, String currency, Map<String, int> rates) {
  final rate = rates[currency];
  return rate == null ? null : roundedRatio(amount, rate, 1000000);
}

// One deterministic schedule is shared by home, detail, booking and forecasts.
List<Charge> schedule(
  Subscription s,
  DateTime through,
  Map<String, int> rates,
) {
  final result = <Charge>[];
  void add(DateTime date, int amount, String currency, String key) {
    if (date.isAfter(through)) return;
    result.add(
      Charge(
        '${s.id}:$key',
        s.id,
        date,
        amount,
        currency,
        convert(amount, currency, rates),
        rates[currency],
      ),
    );
  }

  if (s.manual) {
    add(s.start, s.amount, s.currency, 'start');
    for (final e in s.orderedEvents.where((e) => e.type == 'renew')) {
      add(e.date, e.amount, e.currency, e.id);
    }
    return result;
  }
  var anchor = s.start;
  var months = s.months;
  var amount = s.amount;
  var currency = s.currency;
  var index = 0;
  var due = anchor;
  var stopped = false;
  final actions = s.billingEvents;
  var actionIndex = 0;
  while (!due.isAfter(through)) {
    while (actionIndex < actions.length &&
        !actions[actionIndex].date.isAfter(due)) {
      final e = actions[actionIndex++];
      if (e.type == 'stop') {
        if (due.isAfter(e.date)) stopped = true;
      }
      if (e.type == 'resume') {
        stopped = false;
        anchor = e.date;
        index = 0;
        due = anchor;
      }
      if (e.type == 'change' || e.type == 'upgrade') {
        amount = e.amount;
        currency = e.currency;
        if (e.type == 'upgrade') add(e.date, e.difference, e.currency, e.id);
        if (e.type == 'change' || e.reset) {
          anchor = e.date;
          index = e.type == 'upgrade' ? 1 : 0;
          months = e.months;
          due = addMonths(anchor, index * months);
        }
      }
    }
    if (due.isAfter(through)) break;
    final stop = s.stopDate(due);
    if (!stopped && (stop == null || !due.isAfter(stop))) {
      final discounted =
          s.terms(due).type == 'start' &&
          s.trialEnd != null &&
          due.isBefore(s.trialEnd!);
      add(due, discounted ? s.trialAmount : amount, currency, dateText(due));
    }
    // Preserve the original day anchor: Jan 31 → Feb 28 → Mar 31.
    index++;
    due = addMonths(anchor, index * months);
    if (s.trialDays &&
        anchor == s.start &&
        s.trialEnd != null &&
        s.trialEnd!.isBefore(due)) {
      anchor = s.trialEnd!;
      index = 0;
      due = anchor;
    }
  }
  for (final e
      in actions
          .skip(actionIndex)
          .where((e) => e.type == 'upgrade' && !e.date.isAfter(through))) {
    add(e.date, e.difference, e.currency, e.id);
  }
  return result..sort((a, b) => a.date.compareTo(b.date));
}

String encode(Object? object) => jsonEncode(object);
