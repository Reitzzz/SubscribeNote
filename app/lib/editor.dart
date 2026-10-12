import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'domain.dart';
import 'store.dart';
import 'ui.dart';
import 'pages.dart';

class EditorPage extends ConsumerStatefulWidget {
  const EditorPage({super.key, this.name = ''});
  final String name;
  @override
  ConsumerState<EditorPage> createState() => _EditorState();
}

class _EditorState extends ConsumerState<EditorPage> {
  final form = GlobalKey<FormState>();
  late TextEditingController name, price;
  final note = TextEditingController(),
      duration = TextEditingController(text: '1'),
      trialCount = TextEditingController(),
      trialPrice = TextEditingController(text: '0');
  String currency = 'CNY', category = '其他', icon = '', error = '';
  int months = 1, color = 0xffd97757;
  bool manual = false, trialDays = false, busy = false;
  DateTime start = day(DateTime.now());
  @override
  void initState() {
    super.initState();
    final templates = reference['subscriptions'] as Map<String, dynamic>;
    final known = templates.values
        .where((j) => j['name'] == widget.name)
        .firstOrNull;
    final template = (reference['library'] as List)
        .where((j) => j['name'] == widget.name)
        .firstOrNull;
    name = TextEditingController(text: widget.name);
    price = TextEditingController(
      text: known == null
          ? (widget.name == 'Telegram Premium' ? '4.99' : '0')
          : RegExp(r'[\d.]+').firstMatch(known['price'])!.group(0),
    );
    currency = known == null
        ? (widget.name == 'Telegram Premium' ? 'USD' : 'CNY')
        : (known['price'] as String).substring(
            (known['price'] as String).length - 3,
          );
    category = known?['category'] ?? template?['category'] ?? '其他';
    icon = brandMap[widget.name] ?? '';
    if (known != null) {
      color =
          0xff000000 |
          int.parse((known['color'] as String).substring(1), radix: 16);
      manual = known['manual'] == true;
    }
    months = widget.name == 'WPS 会员'
        ? 36
        : ['Antigravity', '腾讯视频'].contains(widget.name)
        ? 12
        : 1;
    duration.text = '$months';
  }

  @override
  void dispose() {
    for (final c in [name, price, note, duration, trialCount, trialPrice]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> save(bool continuing) async {
    if (busy || !form.currentState!.validate()) return;
    try {
      final amount = parseFixed(price.text, 2);
      final count = manual ? int.tryParse(duration.text) : months;
      if (count == null || count < 1 || count > 1200) {
        throw const FormatException('购买时长需为 1–1200 个月');
      }
      final trial = manual || trialCount.text.trim().isEmpty
          ? 0
          : int.tryParse(trialCount.text);
      if (trial == null || trial < 0 || trial > 1200) {
        throw const FormatException('优惠时长需为 0–1200 的整数');
      }
      final discount = trial > 0 ? parseFixed(trialPrice.text, 2) : 0;
      final s = Subscription(
        name: name.text.trim(),
        category: category,
        start: start,
        amount: amount,
        currency: currency,
        months: count,
        manual: manual,
        icon: icon,
        color: color,
        note: note.text.trim(),
        trialCount: trial,
        trialDays: trialDays,
        trialAmount: discount,
      );
      setState(() {
        busy = true;
        error = '';
      });
      await ref.read(storeProvider.notifier).save(s);
      if (!mounted) return;
      if (continuing) {
        name.clear();
        price.text = '0';
        note.clear();
        trialCount.clear();
        setState(() => busy = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('已保存，可继续添加')));
      } else {
        context.go('/');
        context.push('/detail/${s.id}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e is FormatException ? e.message : '保存失败，请重试：$e';
          busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => AppPage(
    title: '添加订阅',
    topPadding: 0,
    child: Form(
      key: form,
      child: Column(
        children: [
          surface(
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  color: Color(color).withValues(alpha: .125),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () async {
                          final v = await pickIcon(context, icon);
                          if (v != null) setState(() => icon = v);
                        },
                        child: logo(icon, name.text, size: 44),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          children: [
                            TextFormField(
                              controller: name,
                              maxLength: 60,
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: const InputDecoration(
                                hintText: '订阅名称',
                                counterText: '',
                                filled: true,
                                fillColor: Color(0x73ffffff),
                              ),
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? '请输入订阅名称'
                                  : null,
                            ),
                            gap(4),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: price,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    style: const TextStyle(
                                      fontFamily: 'Roboto',
                                      fontSize: 12,
                                    ),
                                    decoration: const InputDecoration(
                                      hintText: '价格',
                                      filled: true,
                                      fillColor: Color(0x73ffffff),
                                    ),
                                    validator: (v) {
                                      try {
                                        parseFixed(v ?? '', 2);
                                        return null;
                                      } catch (_) {
                                        return '金额格式错误';
                                      }
                                    },
                                  ),
                                ),
                                smallButton('$currency⌄', () async {
                                  final v = await pick(
                                    context,
                                    '选择货币',
                                    currencySymbols.keys.toList(),
                                    currency,
                                  );
                                  if (v != null) setState(() => currency = v);
                                }, height: 28),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 7),
                      Column(
                        children: [
                          smallButton('$category分类⌄', () async {
                            final v = await pick(
                              context,
                              '选择分类',
                              List<String>.from(reference['categories']),
                              category,
                            );
                            if (v != null) setState(() => category = v);
                          }, height: 28),
                          smallButton(
                            '#${color.toRadixString(16).substring(2).toUpperCase()}⌄',
                            () async {
                              final v = await pickColor(context, color);
                              if (v != null) setState(() => color = v);
                            },
                            height: 28,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                fieldRow(
                  '续费方式',
                  segments(
                    ['自动扣费', '手动续费'],
                    manual ? 1 : 0,
                    (v) => setState(() => manual = v == 1),
                  ),
                ),
                if (manual)
                  fieldRow(
                    '购买时长',
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 60,
                          child: TextField(
                            controller: duration,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 11,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        txt('月', size: 11, color: muted),
                      ],
                    ),
                  )
                else ...[
                  fieldRow(
                    '扣费周期',
                    smallButton('${cycleName(months)}⌄', () async {
                      final v = await pick(
                        context,
                        '扣费周期',
                        [1, 3, 6, 12].map(cycleName).toList(),
                        cycleName(months),
                      );
                      if (v != null) {
                        setState(
                          () => months = [
                            1,
                            3,
                            6,
                            12,
                          ].firstWhere((m) => cycleName(m) == v),
                        );
                      }
                    }),
                  ),
                  fieldRow(
                    '试用优惠',
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        txt('前', size: 10, color: muted),
                        SizedBox(
                          width: 34,
                          child: TextField(
                            controller: trialCount,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 10,
                            ),
                            decoration: const InputDecoration(hintText: 'n'),
                          ),
                        ),
                        InkWell(
                          onTap: () => setState(() => trialDays = !trialDays),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: txt(
                              trialDays ? '天⌄' : '月⌄',
                              size: 10,
                              color: muted,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 62,
                          child: TextField(
                            controller: trialPrice,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 10,
                            ),
                            decoration: const InputDecoration(hintText: '0.00'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                fieldRow(
                  '开始时间',
                  smallButton(dateText(start), () async {
                    final v = await pickDate(context, start);
                    if (v != null) setState(() => start = v);
                  }),
                ),
                fieldRow(
                  '到期通知',
                  toggle(
                    false,
                    (_) => notice(context, '到期通知', '此 Demo 暂未接入系统通知。'),
                    '到期通知',
                  ),
                ),
              ],
            ),
          ),
          gap(9),
          surface(
            Column(
              children: [
                fieldRow('备注', const SizedBox()),
                TextField(
                  controller: note,
                  minLines: 3,
                  maxLines: 6,
                  maxLength: 2000,
                  style: const TextStyle(fontFamily: 'Roboto', fontSize: 10),
                  decoration: const InputDecoration(
                    hintText: '添加备注信息...',
                    counterText: '',
                    contentPadding: EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
          if (error.isNotEmpty) ...[
            gap(8),
            Align(
              alignment: Alignment.centerLeft,
              child: txt(error, size: 11, color: danger),
            ),
          ],
          gap(18),
          Row(
            children: [
              Expanded(
                child: action(
                  busy ? '保存中…' : '添加订阅',
                  busy ? null : () => save(false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: action(
                  '保存并继续添加',
                  busy ? null : () => save(true),
                  secondary: true,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Future<void> showChange(
  BuildContext context,
  WidgetRef ref,
  Subscription s,
  AppData data, {
  bool renew = false,
}) async {
  final now = day(DateTime.now()), term = s.terms(day(DateTime.now()));
  final price = TextEditingController(
    text: (term.amount / 100).toStringAsFixed(2),
  );
  final difference = TextEditingController(text: '0.00'),
      duration = TextEditingController(text: '${s.months}');
  var currency = term.currency, months = term.months, mode = 0, reset = 0;
  var date = renew ? now : nextDate(s, data, now) ?? addMonths(now, 1);
  String error = '';
  bool busy = false;
  await sheet<void>(
    context,
    renew ? '手动续费' : '订阅更新',
    StatefulBuilder(
      builder: (ctx, setState) => Column(
        children: [
          if (!renew)
            fieldRow(
              '原价格',
              txt(
                '${money(term.amount, term.currency)} · ${cycleName(term.months)}',
                size: 12,
                color: muted,
              ),
              height: 50,
              fontSize: 13,
            ),
          if (!renew)
            fieldRow(
              '生效方式',
              segments(
                ['下个账期起', '立即生效（补差价）'],
                mode,
                (v) => setState(() {
                  mode = v;
                  date = v == 1
                      ? now
                      : nextDate(s, data, now) ?? addMonths(now, 1);
                }),
              ),
              height: 50,
              fontSize: 13,
            ),
          fieldRow(
            renew ? '续费金额' : '新价格',
            SizedBox(
              width: 110,
              child: TextField(
                controller: price,
                textAlign: TextAlign.right,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(fontFamily: 'Roboto', fontSize: 14),
                decoration: InputDecoration(
                  suffixText: currencySymbols[currency],
                ),
              ),
            ),
            height: 50,
            fontSize: 13,
          ),
          fieldRow(
            '货币',
            smallButton(
              '${reference['currencyNames'][currency] ?? currency}⌄',
              () async {
                final v = await pick(
                  ctx,
                  '选择货币',
                  currencySymbols.keys.toList(),
                  currency,
                );
                if (v != null) setState(() => currency = v);
              },
            ),
            height: 50,
            fontSize: 13,
          ),
          if (renew)
            fieldRow(
              '续费时长',
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 65,
                    child: TextField(
                      controller: duration,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12,
                      ),
                    ),
                  ),
                  txt('个月', size: 12, color: muted),
                ],
              ),
              height: 50,
              fontSize: 13,
            )
          else
            fieldRow(
              '扣费周期',
              mode == 1
                  ? txt(cycleName(months), size: 11, color: muted)
                  : smallButton('${cycleName(months)}⌄', () async {
                      final v = await pick(
                        ctx,
                        '扣费周期',
                        [1, 3, 6, 12].map(cycleName).toList(),
                        cycleName(months),
                      );
                      if (v != null) {
                        setState(
                          () => months = [
                            1,
                            3,
                            6,
                            12,
                          ].firstWhere((m) => cycleName(m) == v),
                        );
                      }
                    }),
              height: 50,
              fontSize: 13,
            ),
          if (!renew && mode == 0)
            fieldRow(
              '生效周期',
              smallButton('${date.year}年${date.month}月⌄', () async {
                final due = schedule(
                  s,
                  addMonths(now, 120),
                  data.rates,
                ).where((c) => c.date.isAfter(now)).map((c) => c.date).toList();
                final value = await pick(
                  ctx,
                  '生效周期',
                  due.map((d) => '${d.year}年${d.month}月').toList(),
                  '${date.year}年${date.month}月',
                );
                if (value != null) {
                  setState(
                    () => date = due.firstWhere(
                      (d) => '${d.year}年${d.month}月' == value,
                    ),
                  );
                }
              }),
              height: 50,
              fontSize: 13,
            ),
          fieldRow(
            renew
                ? '付款日期'
                : mode == 0
                ? '生效日'
                : '升级日期',
            smallButton(dateText(date), () async {
              final v = await pickDate(ctx, date, first: renew ? s.start : now);
              if (v != null) setState(() => date = v);
            }),
            height: 50,
            fontSize: 13,
          ),
          if (!renew && mode == 1) ...[
            fieldRow(
              '扣费日',
              segments(
                ['保持原扣费日', '重新计算'],
                reset,
                (v) => setState(() => reset = v),
              ),
              height: 50,
              fontSize: 13,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: txt(
                reset == 0
                    ? '保持原扣费日，下次扣费 ${dateText(nextDate(s, data, now) ?? addMonths(now, months))}'
                    : '升级日起重新计费，下次扣费 ${dateText(addMonths(date, months))}',
                size: 9,
                color: muted,
              ),
            ),
            fieldRow(
              '补差价',
              SizedBox(
                width: 110,
                child: TextField(
                  controller: difference,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontFamily: 'Roboto', fontSize: 13),
                ),
              ),
              height: 50,
              fontSize: 13,
            ),
          ],
          if (renew)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: txt('续费从当前到期日与付款日期中较晚的一天开始计算。', size: 10, color: muted),
            ),
          if (error.isNotEmpty) ...[
            gap(8),
            Align(
              alignment: Alignment.centerLeft,
              child: txt(error, size: 11, color: danger),
            ),
          ],
          gap(14),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: action(
                  '取消',
                  busy ? null : () => Navigator.pop(ctx),
                  secondary: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 6,
                child: action(
                  busy
                      ? '保存中…'
                      : renew
                      ? '确认续费'
                      : '确认更新',
                  busy
                      ? null
                      : () async {
                          try {
                            final amount = parseFixed(price.text, 2),
                                count = renew
                                    ? int.tryParse(duration.text)
                                    : months;
                            if (count == null || count < 1 || count > 1200) {
                              throw const FormatException('续费时长需为 1–1200 个月');
                            }
                            if (date.isBefore(s.start)) {
                              throw const FormatException('日期不能早于订阅开始日期');
                            }
                            if (!renew && date.isBefore(now)) {
                              throw const FormatException('不能修改已入账的历史日期');
                            }
                            if (renew && date.isAfter(now)) {
                              throw const FormatException('付款日期不能晚于今天');
                            }
                            if (!renew && mode == 0) {
                              final due =
                                  schedule(s, addMonths(now, 120), data.rates)
                                      .where((c) => c.date.isAfter(now))
                                      .map((c) => c.date);
                              if (!due.contains(date)) {
                                throw const FormatException('生效日需要选择未来的实际扣费日');
                              }
                            }
                            final diff = mode == 1
                                ? parseFixed(difference.text, 2)
                                : 0;
                            if (!renew && mode == 1) {
                              if (date != now) {
                                throw const FormatException('立即升级日期需为今天');
                              }
                              if (schedule(
                                s,
                                date,
                                data.rates,
                              ).any((c) => c.date == date)) {
                                throw const FormatException(
                                  '该日期是扣费日，请用「下个账期起」记录',
                                );
                              }
                            }
                            if (!renew &&
                                s.events.any(
                                  (e) =>
                                      (e.type == 'change' ||
                                          e.type == 'upgrade') &&
                                      !e.date.isBefore(date),
                                )) {
                              throw const FormatException(
                                '已存在该日期或更晚的更新，请选择其后的账期',
                              );
                            }
                            setState(() => busy = true);
                            final e = PlanEvent(
                              type: renew
                                  ? 'renew'
                                  : mode == 0
                                  ? 'change'
                                  : 'upgrade',
                              date: date,
                              amount: amount,
                              currency: currency,
                              months: count,
                              reset: reset == 1,
                              difference: diff,
                            );
                            await ref
                                .read(storeProvider.notifier)
                                .save(s.copy(events: [...s.events, e]));
                            if (ctx.mounted) Navigator.pop(ctx);
                          } catch (e) {
                            if (ctx.mounted) {
                              setState(() {
                                error = e is FormatException
                                    ? e.message
                                    : '保存失败，请重试：$e';
                                busy = false;
                              });
                            }
                          }
                        },
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Future<void> showStop(
  BuildContext context,
  WidgetRef ref,
  Subscription s,
  AppData data,
) async {
  final now = day(DateTime.now());
  var month = DateTime.utc(now.year, now.month);
  String error = '';
  bool busy = false;
  await sheet<void>(
    context,
    '停止订阅',
    StatefulBuilder(
      builder: (ctx, setState) => Column(
        children: [
          txt('选择最后一个付费账期，到期后将不再自动续费', size: 10, color: muted),
          gap(8),
          fieldRow(
            '最后付费账期',
            smallButton('${month.year}年${month.month}月⌄', () async {
              final options = List.generate(
                36,
                (i) => addMonths(DateTime.utc(now.year, now.month), i),
              );
              final v = await pick(
                ctx,
                '最后付费账期',
                options.map((d) => '${d.year}年${d.month}月').toList(),
                '${month.year}年${month.month}月',
              );
              if (v != null) {
                setState(
                  () => month = options.firstWhere(
                    (d) => '${d.year}年${d.month}月' == v,
                  ),
                );
              }
            }),
            height: 50,
            fontSize: 13,
          ),
          fieldRow(
            '到期日',
            txt(
              dateText(DateTime.utc(month.year, month.month + 1, 0)),
              size: 12,
            ),
            height: 50,
            fontSize: 13,
          ),
          if (error.isNotEmpty) ...[
            gap(8),
            txt(error, size: 11, color: danger),
          ],
          gap(14),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: action(
                  '取消',
                  busy ? null : () => Navigator.pop(ctx),
                  secondary: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 6,
                child: action(
                  busy ? '保存中…' : '确认停止',
                  busy
                      ? null
                      : () async {
                          final end = DateTime.utc(
                            month.year,
                            month.month + 1,
                            0,
                          );
                          if (end.isBefore(s.start) ||
                              s.events.any(
                                (e) =>
                                    (e.type == 'change' ||
                                        e.type == 'upgrade') &&
                                    e.date.isAfter(end),
                              )) {
                            setState(() => error = '停止日期不能早于订阅开始日或已安排的订阅变更');
                            return;
                          }
                          try {
                            setState(() => busy = true);
                            await ref
                                .read(storeProvider.notifier)
                                .save(
                                  s.copy(
                                    events: [
                                      ...s.events,
                                      PlanEvent(type: 'stop', date: end),
                                    ],
                                  ),
                                );
                            if (ctx.mounted) Navigator.pop(ctx);
                          } catch (e) {
                            if (ctx.mounted) {
                              setState(() {
                                error = '保存失败，请重试';
                                busy = false;
                              });
                            }
                          }
                        },
                  destructive: true,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
