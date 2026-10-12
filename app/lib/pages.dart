import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'domain.dart';
import 'store.dart';
import 'ui.dart';
import 'editor.dart';

Widget dataView(AsyncValue<AppData> value, Widget Function(AppData) builder) =>
    value.when(
      data: builder,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: txt('无法读取本地数据\n$e', color: danger)),
    );
int? sumCny(Iterable<Charge> rows) {
  if (rows.any((c) => c.cny == null)) return null;
  return rows.fold<int>(0, (sum, c) => sum + c.cny!);
}

DateTime? nextDate(Subscription s, AppData data, DateTime now) {
  if (s.manual) return s.expiry.subtract(const Duration(days: 1));
  final rows = schedule(
    s,
    addMonths(now, 120),
    data.rates,
  ).where((c) => c.date.isAfter(now));
  return rows.isEmpty ? null : rows.first.date;
}

const brandMap = {
  'FlowUs 息流': 'flowus',
  '腾讯文档': 'docs',
  '语雀': 'yuque',
  '百度文库': 'baidu',
  'Surfshark': 'surfshark',
  'NordVPN': 'nordvpn',
  'Nexitally': 'nexitally',
  '咪咕视频': 'migu',
  '芒果TV': 'mango',
  '爱奇艺': 'iqiyi',
  '优酷': 'youku',
  'SoundCloud Go+': 'soundcloud',
  'Tidal': 'tidal',
  'Deezer': 'deezer',
  'Spotify': 'spotify',
  'Telegram Premium': 'telegram',
  'Kimi': 'kimi',
  '文心一言': 'baidu',
  '通义千问': 'qwen',
  '豆包': 'doubao',
  '智谱清言': 'zhipu',
  '讯飞星火': 'spark',
  '海螺AI': 'hailuo',
  '天工AI': 'tiangong',
  '腾讯元宝': 'yuanbao',
  'DeepSeek': 'deepseek',
  'Trae': 'trae',
  '360智脑': '360',
  '百川智能': 'baichuan',
  'CodeGeeX': 'codegeex',
  '阶跃星辰': 'stepfun',
  '可灵AI': 'kling',
  '即梦AI': 'jimeng',
  'Vidu': 'vidu',
  'ChatGPT': 'chatgpt',
  'Claude': 'claude',
  'Bilibili 大会员': 'bilibili',
  'WPS 会员': 'wps',
  'Apple Music': 'apple',
  'Antigravity': 'anti',
  '腾讯视频': 'tencent',
};

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});
  @override
  ConsumerState<HomePage> createState() => _HomeState();
}

class _HomeState extends ConsumerState<HomePage> {
  int mode = 0;
  @override
  Widget build(BuildContext context) => dataView(ref.watch(storeProvider), (
    data,
  ) {
    final now = day(DateTime.now());
    final entries = data
        .entries(DateTime.utc(now.year, 12, 31), now)
        .where((c) => c.date.year == now.year)
        .toList();
    final values = data.subscriptions.map((s) => data.monthly(s, now)).toList();
    final monthly = values.contains(null)
        ? null
        : values.fold<int>(0, (sum, v) => sum + v!);
    final amount = [
      monthly,
      sumCny(entries),
      sumCny(entries.where((c) => !c.date.isAfter(now))),
    ][mode];
    var subscriptions = data.subscriptions
        .where((s) => data.settings['expired'] != false || s.active(now))
        .toList();
    final sort = data.settings['sort'] ?? '新添加排在上方';
    if (sort == '新添加排在下方') subscriptions = subscriptions.reversed.toList();
    if (sort == '即将到期排在上方') {
      subscriptions.sort(
        (a, b) => (nextDate(a, data, now) ?? DateTime.utc(2200)).compareTo(
          nextDate(b, data, now) ?? DateTime.utc(2200),
        ),
      );
    }
    if (data.settings['separate'] == true) {
      subscriptions.sort(
        (a, b) => (a.active(now) ? 0 : 1).compareTo(b.active(now) ? 0 : 1),
      );
    }
    final compact = data.settings['compact'] == true;
    return AppPage(
      title: '订小阅',
      tab: 0,
      fab: SizedBox(
        width: 52,
        height: 52,
        child: FloatingActionButton(
          heroTag: 'add',
          tooltip: '添加订阅',
          onPressed: () => context.push('/library'),
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: const CircleBorder(),
          child: symbol('plus', color: Colors.white),
        ),
      ),
      child: Column(
        children: [
          surface(
            Stack(
              children: [
                Positioned(
                  right: -90,
                  bottom: -110,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0x1f7896ce),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () =>
                                setState(() => mode = (mode + 1) % 3),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(110, 30),
                            ),
                            child: Row(
                              children: [
                                txt('概览', size: 13, color: Colors.white),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: .07),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      symbol(
                                        'swap',
                                        size: 13,
                                        color: Colors.white70,
                                      ),
                                      txt(
                                        '点击切换',
                                        size: 10,
                                        color: Colors.white70,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0x2e74cfb4),
                              border: Border.all(
                                color: const Color(0x3866deb8),
                              ),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: txt(
                              mode == 0
                                  ? '当前生效 ${data.subscriptions.where((s) => s.active(now)).length} 项'
                                  : '本年${mode == 1 ? '预计' : '已'}支出 ${entries.where((c) => mode == 1 || !c.date.isAfter(now)).length} 笔',
                              size: 10,
                              color: const Color(0xffe8fff7),
                            ),
                          ),
                        ],
                      ),
                      gap(14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Flexible(
                            child: txt(
                              data.format(amount),
                              size: 31,
                              color: Colors.white,
                              weight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: txt(
                              ['月均成本', '预计年支出', '今年已支出'][mode],
                              size: 10,
                              color: Colors.white60,
                            ),
                          ),
                          const Spacer(),
                          InkWell(
                            onTap: () =>
                                notice(context, '分享', '此 Demo 暂未接入分享卡。'),
                            child: Padding(
                              padding: const EdgeInsets.all(7),
                              child: symbol(
                                'share',
                                size: 20,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            gradient: blueGradient,
            radius: 14,
            minHeight: 120,
          ),
          gap(12),
          if (subscriptions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 110),
              child: txt('暂无订阅，点击 + 添加', color: muted),
            ),
          for (final s in subscriptions)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: subscriptionCard(context, s, data, now, compact),
            ),
          gap(50),
        ],
      ),
    );
  });
}

Widget subscriptionCard(
  BuildContext context,
  Subscription s,
  AppData data,
  DateTime now,
  bool compact,
) {
  final next = nextDate(s, data, now), term = s.terms(now);
  final days = next?.difference(now).inDays;
  final backgrounds = <String, List<Color>>{
    'claude': [const Color(0xfff7dddd), const Color(0xfff5e3e9)],
    'wps': [const Color(0xfff8e3e4), const Color(0xfff8e5ea)],
    'xsus': [const Color(0xfff7dfe1), const Color(0xfff5e2e8)],
    'bilibili': [const Color(0xfff7e0e6), const Color(0xfff5e4e7)],
    'apple': [const Color(0xfff8dfe1), const Color(0xfff7e6e8)],
    'anti': [const Color(0xffe9e8f1), const Color(0xffe9e8f1)],
    'tencent': [const Color(0xfffae8dc), const Color(0xfffae8dc)],
    'chatgpt': [const Color(0xffe6eee7), const Color(0xffe6eee7)],
  };
  return Semantics(
    button: true,
    label: '${s.name}，${money(term.amount, term.currency)}',
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/detail/${s.id}'),
        borderRadius: BorderRadius.circular(13),
        child: surface(
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 14,
              vertical: compact ? 7 : 16,
            ),
            child: Row(
              children: [
                logo(s.icon, s.name),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: txt(
                              s.name,
                              size: 14,
                              weight: FontWeight.w600,
                              lines: 1,
                            ),
                          ),
                          if (s.trialEnd != null && now.isBefore(s.trialEnd!))
                            Padding(
                              padding: const EdgeInsets.only(left: 5),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xfff4a83e),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: txt('优惠中', size: 8, color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                      if (!compact) ...[
                        gap(6),
                        txt(
                          '${s.category} · ${dateText(s.start)} 起',
                          size: 9,
                          color: const Color(0xff91858c),
                          lines: 1,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: money(
                              term.amount,
                              term.currency,
                            ).replaceFirst(RegExp(r'\.00$'), ''),
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: ink,
                            ),
                          ),
                          TextSpan(
                            text: s.manual
                                ? ' 手动续费'
                                : term.months == 12
                                ? ' 年付'
                                : term.months == 1
                                ? ' 月付'
                                : ' ${term.months}个月',
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 8,
                              color: muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    gap(6),
                    txt(
                      s.stopDate(now) != null
                          ? '已安排停止'
                          : !s.active(now)
                          ? '已过期'
                          : days == null
                          ? '已停止'
                          : '$days天后',
                      size: 9,
                      color: const Color(0xff938b91),
                    ),
                  ],
                ),
              ],
            ),
          ),
          gradient: LinearGradient(
            colors:
                backgrounds[s.icon] ??
                [
                  Color(s.color).withValues(alpha: .15),
                  const Color(0xfff5e3e9),
                ],
          ),
        ),
      ),
    ),
  );
}

class DetailPage extends ConsumerWidget {
  const DetailPage({super.key, required this.id});
  final String id;
  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) => dataView(ref.watch(storeProvider), (data) {
    final matches = data.subscriptions.where((s) => s.id == id);
    if (matches.isEmpty) return AppPage(title: '扣费详情', child: txt('订阅已删除'));
    final s = matches.first,
        now = day(DateTime.now()),
        term = s.terms(day(DateTime.now()));
    final next = nextDate(s, data, now), stop = s.stopDate(now);
    final entries = data
        .entries(DateTime.utc(now.year, 12, 31), now)
        .where((c) => c.subscriptionId == s.id)
        .toList();
    final history = data.charges.where((c) => c.subscriptionId == id).toList();
    final timeline = [
      PlanEvent(
        id: s.id,
        type: 'start',
        date: s.start,
        amount: s.amount,
        currency: s.currency,
        months: s.months,
        note: s.note,
      ),
      ...s.orderedEvents,
    ];
    if (next != null) {
      timeline.add(
        PlanEvent(
          type: s.manual ? 'expiry' : 'next',
          date: next,
          amount: term.amount,
          currency: term.currency,
          months: term.months,
        ),
      );
    }
    timeline.sort((a, b) => a.date.compareTo(b.date));
    if (s.trialEnd != null) {
      timeline.add(
        PlanEvent(
          type: 'trialEnd',
          date: s.trialEnd!,
          amount: s.amount,
          currency: s.currency,
          months: s.months,
          note: '恢复 ${money(s.amount, s.currency)} · ${cycleName(s.months)}',
        ),
      );
      timeline.sort((a, b) => a.date.compareTo(b.date));
    }
    return AppPage(
      title: '扣费详情',
      topPadding: 1,
      bottom: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (stop != null)
                  SizedBox(
                    width: 230,
                    child: action(
                      '取消停止',
                      () => guarded(
                        context,
                        () => ref
                            .read(storeProvider.notifier)
                            .save(
                              s.copy(
                                events: [
                                  ...s.events,
                                  stop.isBefore(now)
                                      ? PlanEvent(type: 'resume', date: now)
                                      : PlanEvent(
                                          type: 'cancel',
                                          date: now,
                                          note: s.billingEvents
                                              .lastWhere(
                                                (e) => e.type == 'stop',
                                              )
                                              .id,
                                        ),
                                ],
                              ),
                            ),
                      ),
                    ),
                  )
                else if (s.manual)
                  SizedBox(
                    width: 230,
                    child: action(
                      '手动续费',
                      () => showChange(context, ref, s, data, renew: true),
                    ),
                  )
                else ...[
                  Expanded(
                    child: action(
                      '订阅更新',
                      () => showChange(context, ref, s, data),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: action(
                      '停止订阅',
                      () => showStop(context, ref, s, data),
                      secondary: true,
                    ),
                  ),
                ],
              ],
            ),
            TextButton(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: txt('警告：该操作不可撤销', size: 16),
                    content: txt(
                      '删除后，此订阅将不再显示，消费统计也会移除。要暂时暂停，请使用「停止订阅」。',
                      size: 12,
                      color: muted,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('取消'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text(
                          '仍要删除',
                          style: TextStyle(fontFamily: 'Roboto', color: danger),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  await guarded(context, () async {
                    await ref
                        .read(storeProvider.notifier)
                        .save(s.copy(deletedAt: DateTime.now().toUtc()));
                    if (context.mounted) context.go('/');
                  });
                }
              },
              child: txt('删除订阅', size: 12, color: danger),
            ),
          ],
        ),
      ),
      child: Column(
        children: [
          surface(
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () async {
                      final icon = await pickIcon(context, s.icon);
                      if (icon != null && context.mounted) {
                        await guarded(
                          context,
                          () => ref
                              .read(storeProvider.notifier)
                              .save(s.copy(icon: icon)),
                        );
                      }
                    },
                    child: logo(s.icon, s.name, size: 51),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: txt(
                                s.name,
                                size: 16,
                                weight: FontWeight.w600,
                              ),
                            ),
                            smallButton('${s.category} 分类⌄', () async {
                              final v = await pick(
                                context,
                                '选择分类',
                                List<String>.from(reference['categories']),
                                s.category,
                              );
                              if (v != null && context.mounted) {
                                await guarded(
                                  context,
                                  () => ref
                                      .read(storeProvider.notifier)
                                      .save(s.copy(category: v)),
                                );
                              }
                            }),
                          ],
                        ),
                        gap(5),
                        Wrap(
                          spacing: 14,
                          runSpacing: 5,
                          children: [
                            txt(
                              '价格：${money(term.amount, term.currency)} ${term.currency}',
                              size: 10,
                              color: muted,
                            ),
                            txt(
                              '周期：${s.manual ? '手动续费' : '${cycleName(term.months)} · 自动扣费'}',
                              size: 10,
                              color: muted,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            gradient: LinearGradient(
              colors: [
                Color(s.color).withValues(alpha: .125),
                const Color(0xffeee6f1),
              ],
            ),
          ),
          gap(),
          surface(
            Column(
              children: [
                fieldRow(
                  '卡片颜色',
                  smallButton(
                    '● #${s.color.toRadixString(16).substring(2).toUpperCase()}⌄',
                    () async {
                      final v = await pickColor(context, s.color);
                      if (v != null && context.mounted) {
                        await guarded(
                          context,
                          () => ref
                              .read(storeProvider.notifier)
                              .save(s.copy(color: v)),
                        );
                      }
                    },
                  ),
                  height: 56,
                  fontSize: 13,
                ),
                fieldRow(
                  '到期通知',
                  toggle(
                    false,
                    (_) =>
                        notice(context, '到期通知', '此 Demo 尚未接入系统通知，可在详情查看到期日期。'),
                    '到期通知',
                  ),
                  height: 56,
                  fontSize: 13,
                ),
              ],
            ),
          ),
          gap(),
          Row(
            children: [
              Expanded(
                child: metric(
                  '${s.manual ? '到期日' : '下次扣费日'}${next == null ? '' : ' · ${next.difference(now).inDays}天后'}',
                  next == null ? '已停止' : dateText(next),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: metric('月均费', data.format(data.monthly(s, now)))),
            ],
          ),
          gap(8),
          Row(
            children: [
              Expanded(child: metric('累计消费', data.format(sumCny(history)))),
              const SizedBox(width: 8),
              Expanded(
                child: metric(
                  '本年消费（预计）',
                  data.format(
                    sumCny(entries.where((c) => c.date.year == now.year)),
                  ),
                ),
              ),
            ],
          ),
          gap(16),
          for (final e in timeline) ...[
            Padding(
              padding: const EdgeInsets.only(left: 3, bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    height: 52,
                    child: Stack(
                      children: [
                        if (e != timeline.last)
                          Positioned(
                            left: 4,
                            top: 9,
                            bottom: 0,
                            child: Container(
                              width: 1,
                              color: const Color(0x24222033),
                            ),
                          ),
                        Positioned(
                          left: 0,
                          top: 7,
                          child: Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: e.type == 'stop'
                                  ? const Color(0xffed9b9b)
                                  : e.date.isAfter(now)
                                  ? const Color(0xffc8e0f4)
                                  : primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        txt(
                          dateText(e.date),
                          size: 9,
                          color: const Color(0xffb2aeb8),
                        ),
                        gap(3),
                        txt(
                          eventTitle(e.type),
                          size: 13,
                          weight: FontWeight.w600,
                        ),
                        gap(12),
                      ],
                    ),
                  ),
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 17),
                      child: txt(
                        e.type == 'cancel'
                            ? ''
                            : e.note.isNotEmpty
                            ? e.note
                            : ['stop', 'resume', 'expiry'].contains(e.type)
                            ? ''
                            : '${money(e.amount, e.currency)} · ${cycleName(e.months)}',
                        size: 9,
                        color: const Color(0xffaaa5ae),
                        align: TextAlign.right,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (e.type == 'start' && !s.manual)
              Padding(
                padding: const EdgeInsets.only(left: 24, bottom: 12),
                child: Row(
                  children: [
                    const Expanded(child: Divider(color: Color(0x17232135))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: txt(
                        '共 ${history.length} 个计费周期',
                        size: 9,
                        color: muted,
                      ),
                    ),
                    const Expanded(child: Divider(color: Color(0x17232135))),
                  ],
                ),
              ),
          ],
          if (s.note.isNotEmpty)
            surface(
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    txt('备注', size: 11),
                    gap(7),
                    txt(s.note, size: 11, color: muted),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  });
}

String eventTitle(String type) =>
    {
      'start': '开始订阅',
      'next': '下次扣费',
      'expiry': '订阅到期',
      'renew': '手动续费',
      'upgrade': '套餐升级',
      'change': '订阅更新',
      'stop': '停止自动续费',
      'resume': '取消停止',
      'cancel': '取消停止',
      'trialEnd': '优惠结束',
    }[type] ??
    type;
Widget metric(String label, String value) => surface(
  Padding(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 13),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        txt(label, size: 9, color: const Color(0xff9b98a3)),
        gap(6),
        txt(value, size: 17, weight: FontWeight.w600),
      ],
    ),
  ),
  radius: 12,
  minHeight: 73,
);

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});
  @override
  State<LibraryPage> createState() => _LibraryState();
}

class _LibraryState extends State<LibraryPage> {
  String query = '', category = '全部';
  @override
  Widget build(BuildContext context) {
    final items = (reference['library'] as List)
        .where(
          (j) =>
              (category == '全部' || j['category'] == category) &&
              (j['name'] as String).toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
    return AppPage(
      title: '添加订阅',
      topPadding: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          surface(
            TextField(
              onChanged: (v) => setState(() => query = v),
              style: const TextStyle(fontFamily: 'Roboto', fontSize: 11),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search, size: 20),
                prefixIconConstraints: BoxConstraints(
                  minWidth: 34,
                  minHeight: 34,
                ),
                hintText: '搜索服务，如 Netflix、Notion、Spotify',
              ),
            ),
            radius: 10,
          ),
          chips(
            ['全部', ...List<String>.from(reference['categories'])],
            category,
            (v) => setState(() => category = v),
          ),
          Row(
            children: [
              Expanded(child: txt('没有合适的模板？', size: 10, color: muted)),
              FilledButton(
                onPressed: () => context.push('/add'),
                style: FilledButton.styleFrom(
                  backgroundColor: primary,
                  minimumSize: const Size(0, 28),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  textStyle: const TextStyle(fontFamily: 'Roboto', fontSize: 9),
                ),
                child: const Text('手动创建'),
              ),
              const SizedBox(width: 7),
              FilledButton(
                onPressed: () => notice(context, 'AI 识别', '此 Demo 尚未接入截图识别。'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xff7663d7),
                  minimumSize: const Size(0, 28),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  textStyle: const TextStyle(fontFamily: 'Roboto', fontSize: 9),
                ),
                child: const Text('Pro · AI 识别'),
              ),
            ],
          ),
          txt(
            category == '全部' ? '全部服务' : '$category服务',
            size: 11,
            weight: FontWeight.w600,
          ),
          gap(9),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: txt('没有找到服务，可手动创建订阅', size: 12, color: muted),
              ),
            ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 48,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemBuilder: (context, i) {
              final name = items[i]['name'] as String;
              return Material(
                color: [
                  const Color(0xfff1e5f6),
                  const Color(0xffe7eef9),
                  const Color(0xfff9e7e8),
                ][i % 3],
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () =>
                      context.push('/add?name=${Uri.encodeComponent(name)}'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        logo(brandMap[name] ?? '', name, size: 27),
                        const SizedBox(width: 8),
                        Expanded(child: txt(name, size: 10, lines: 1)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class StatisticsPage extends ConsumerStatefulWidget {
  const StatisticsPage({super.key});
  @override
  ConsumerState<StatisticsPage> createState() => _StatisticsState();
}

class _StatisticsState extends ConsumerState<StatisticsPage> {
  int year = DateTime.now().year, view = 0, month = DateTime.now().month;
  String category = '全部';
  @override
  Widget build(BuildContext context) => dataView(ref.watch(storeProvider), (
    data,
  ) {
    final now = day(DateTime.now()),
        byId = {for (final s in data.subscriptions) s.id: s};
    final all = data
        .entries(DateTime.utc(year, 12, 31), now)
        .where((c) => c.date.year == year)
        .toList();
    final filtered = all
        .where(
          (c) =>
              category == '全部' || byId[c.subscriptionId]?.category == category,
        )
        .toList();
    final categories = data.subscriptions
        .map((s) => s.category)
        .toSet()
        .toList();
    final months = List.generate(
      12,
      (i) => sumCny(filtered.where((c) => c.date.month == i + 1)) ?? 0,
    );
    final actual = sumCny(filtered.where((c) => !c.date.isAfter(now)));
    final total = sumCny(filtered);
    final annual = {
      for (final y in [year - 1, year])
        y: sumCny(
          data
              .entries(DateTime.utc(y, 12, 31), now)
              .where(
                (c) =>
                    c.date.year == y &&
                    (category == '全部' ||
                        byId[c.subscriptionId]?.category == category),
              ),
        ),
    };
    final annualMax = math.max(
      1,
      annual.values.fold<int>(0, (a, b) => math.max(a, b ?? 0)),
    );
    return AppPage(
      title: '统计',
      topPadding: 0,
      tab: 1,
      child: Column(
        children: [
          chips(
            [
              for (
                var y = math.min(
                  now.year - 1,
                  data.subscriptions.fold<int>(
                    now.year,
                    (y, s) => math.min(y, s.start.year),
                  ),
                );
                y <= now.year + 1;
                y++
              )
                '$y',
            ],
            '$year',
            (v) => setState(() => year = int.parse(v)),
          ),
          segments(
            ['⌁ 趋势', '◔ 占比'],
            view,
            (v) => setState(() => view = v),
            wide: true,
          ),
          gap(9),
          if (view == 0) ...[
            chips(
              ['全部', ...categories],
              category,
              (v) => setState(() => category = v),
            ),
            Row(
              children: [
                Expanded(
                  child: statMetric('本年已支出', data.format(actual), '按实际账单'),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: statMetric('全年预计', data.format(total), '含未来预计'),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: statMetric(
                    '月均成本',
                    data.format(
                      total == null ? null : roundedRatio(total, 1, 12),
                    ),
                    '全年金额 / 12',
                  ),
                ),
              ],
            ),
            gap(9),
            surface(
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    chartHeading(
                      '年度支出趋势',
                      '${data.displayCurrency} · $category',
                      dark: true,
                    ),
                    gap(5),
                    txt('按实际订阅付款日期统计，未来月份为预测', size: 10, color: Colors.white60),
                    gap(20),
                    SizedBox(
                      height: 145,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (final y in [year - 1, year])
                            Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                txt(
                                  data.format(
                                    sumCny(
                                      data
                                          .entries(DateTime.utc(y, 12, 31), now)
                                          .where(
                                            (c) =>
                                                c.date.year == y &&
                                                (category == '全部' ||
                                                    byId[c.subscriptionId]
                                                            ?.category ==
                                                        category),
                                          ),
                                    ),
                                  ),
                                  size: 11,
                                  color: Colors.white,
                                ),
                                gap(6),
                                Container(
                                  width: 44,
                                  height: math.max(
                                    2.0,
                                    (annual[y] ?? 0) / annualMax * 95,
                                  ),
                                  decoration: BoxDecoration(
                                    color: y == year
                                        ? const Color(0xffaabde2)
                                        : const Color(0xff7482a1),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                                gap(7),
                                txt('$y', size: 10, color: Colors.white70),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              gradient: blueGradient,
            ),
            gap(9),
            surface(
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    chartHeading(
                      '$year年 月度支出',
                      '${data.displayCurrency} · $category',
                    ),
                    gap(5),
                    txt('按实际订阅付款日期统计，未来月份为预测', size: 10, color: muted),
                    gap(14),
                    SizedBox(
                      height: 170,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: TrendPainter(
                          months
                              .map((v) => (data.display(v) ?? 0) / 100)
                              .toList(),
                        ),
                      ),
                    ),
                    if (filtered.any((c) => c.cny == null))
                      txt('存在缺失汇率的账单，图表仅显示已换算部分', size: 10, color: danger),
                  ],
                ),
              ),
            ),
            gap(9),
            surface(
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    txt('Top 订阅', weight: FontWeight.w600),
                    gap(12),
                    ...topRows(filtered, byId, data),
                  ],
                ),
              ),
            ),
          ] else ...[
            ratioCard(data, all, byId, '$year年 分类占比', dark: true),
            gap(9),
            surface(
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    txt('月度分类占比', size: 14, weight: FontWeight.w600),
                    gap(12),
                    chips(
                      List.generate(12, (i) => '${i + 1}月'),
                      '$month月',
                      (v) => setState(
                        () => month = int.parse(v.replaceAll('月', '')),
                      ),
                    ),
                    ratioCard(
                      data,
                      all.where((c) => c.date.month == month).toList(),
                      byId,
                      '$month月',
                      nested: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  });
}

Widget statMetric(String label, String value, String help) => surface(
  Padding(
    padding: const EdgeInsets.all(10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        txt(label, size: 9, color: muted),
        gap(5),
        FittedBox(child: txt(value, size: 16, weight: FontWeight.w700)),
        gap(3),
        txt(help, size: 9, color: const Color(0xffb7b3bc)),
      ],
    ),
  ),
  radius: 9,
);
Widget chartHeading(String title, String suffix, {bool dark = false}) => Row(
  children: [
    Expanded(
      child: txt(
        title,
        size: 14,
        weight: FontWeight.w600,
        color: dark ? Colors.white : ink,
      ),
    ),
    txt(suffix, size: 10, color: dark ? Colors.white60 : muted),
  ],
);
List<Widget> topRows(
  List<Charge> rows,
  Map<String, Subscription> byId,
  AppData data,
) {
  final sums = <String, int>{};
  for (final c in rows) {
    sums.update(
      c.subscriptionId,
      (v) => v + (c.cny ?? 0),
      ifAbsent: () => c.cny ?? 0,
    );
  }
  final sorted = sums.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return [
    for (final e in sorted.take(5))
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            logo(byId[e.key]!.icon, byId[e.key]!.name, size: 24),
            const SizedBox(width: 8),
            Expanded(child: txt(byId[e.key]!.name, size: 11)),
            txt(data.format(e.value), size: 12, weight: FontWeight.w600),
          ],
        ),
      ),
    if (sorted.isEmpty) txt('暂无消费', size: 12, color: muted),
  ];
}

const categoryColors = {
  'AI': Color(0xff695dff),
  '影音': Color(0xffff696c),
  '云服务': Color(0xff48b4d0),
  '其他': Color(0xffa5a5a5),
};
Widget ratioCard(
  AppData data,
  List<Charge> rows,
  Map<String, Subscription> byId,
  String title, {
  bool dark = false,
  bool nested = false,
}) {
  final sums = <String, int>{}, counts = <String, Set<String>>{};
  for (final c in rows) {
    final cat = byId[c.subscriptionId]!.category;
    sums.update(cat, (v) => v + (c.cny ?? 0), ifAbsent: () => c.cny ?? 0);
    (counts[cat] ??= {}).add(c.subscriptionId);
  }
  sums.removeWhere((k, v) => v == 0);
  final total = sums.values.fold<int>(0, (a, b) => a + b);
  final child = Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      chartHeading(title, '总计 ${data.format(sumCny(rows))}', dark: dark),
      gap(7),
      txt(
        '* 按实际扣费/付款日期统计，未来月份为预测',
        size: 11,
        color: dark ? Colors.white60 : muted,
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 34),
        child: Center(
          child: SizedBox(
            width: 140,
            height: 140,
            child: CustomPaint(
              painter: DonutPainter(
                sums.values.toList(),
                sums.keys
                    .map((k) => categoryColors[k] ?? const Color(0xffa5a5a5))
                    .toList(),
              ),
              child: total == 0
                  ? Center(child: txt('暂无消费', size: 11, color: muted))
                  : null,
            ),
          ),
        ),
      ),
      for (final e in sums.entries)
        Padding(
          padding: const EdgeInsets.only(bottom: 13),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: categoryColors[e.key] ?? muted,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: txt(e.key, size: 11, color: dark ? Colors.white : ink),
              ),
              txt(
                '${counts[e.key]!.length}项',
                size: 10,
                color: dark ? Colors.white60 : muted,
              ),
              const SizedBox(width: 12),
              txt(
                '${(e.value / total * 100).toStringAsFixed(1)}%',
                size: 10,
                color: dark ? Colors.white60 : muted,
              ),
              const SizedBox(width: 14),
              txt(
                data.format(e.value),
                size: 11,
                color: dark ? Colors.white : ink,
                weight: FontWeight.w600,
              ),
            ],
          ),
        ),
    ],
  );
  return nested
      ? child
      : surface(
          Padding(padding: const EdgeInsets.all(16), child: child),
          gradient: dark ? blueGradient : null,
        );
}

class TrendPainter extends CustomPainter {
  TrendPainter(this.values);
  final List<double> values;
  @override
  void paint(Canvas canvas, Size size) {
    final max = math.max(1.0, values.fold<double>(0, math.max)),
        left = 32.0,
        w = size.width - left - 8,
        h = size.height - 28;
    final p = Paint()
      ..color = const Color(0x2e9e9cab)
      ..strokeWidth = .7;
    void label(String text, Offset at) {
      final t = TextPainter(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 9,
            color: muted,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      t.paint(canvas, at);
    }

    for (var i = 0; i <= 4; i++) {
      final y = h * i / 4;
      canvas.drawLine(Offset(left, y), Offset(size.width, y), p);
      label((max * (4 - i) / 4).toStringAsFixed(0), Offset(0, y - 4));
    }
    final path = Path();
    for (var i = 0; i < 12; i++) {
      final x = left + w * i / 11, y = h - values[i] / max * h;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      label('${i + 1}', Offset(x - 3, h + 12));
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xff8571cb)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    for (var i = 0; i < 12; i++) {
      canvas.drawCircle(
        Offset(left + w * i / 11, h - values[i] / max * h),
        3,
        Paint()..color = const Color(0xff8571cb),
      );
    }
  }

  @override
  bool shouldRepaint(TrendPainter old) => true;
}

class DonutPainter extends CustomPainter {
  DonutPainter(this.values, this.colors);
  final List<int> values;
  final List<Color> colors;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(12, 12, size.width - 24, size.height - 24),
        p = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 25;
    final total = values.fold<int>(0, (a, b) => a + b);
    if (total == 0) {
      canvas.drawArc(
        rect,
        0,
        2 * math.pi,
        false,
        p..color = const Color(0xffe0e2df),
      );
      return;
    }
    var start = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      final sweep = values[i] / total * 2 * math.pi;
      canvas.drawArc(rect, start, sweep, false, p..color = colors[i]);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(DonutPainter old) => true;
}

class AlternativesPage extends StatefulWidget {
  const AlternativesPage({super.key});
  @override
  State<AlternativesPage> createState() => _AlternativesState();
}

class _AlternativesState extends State<AlternativesPage> {
  String selected = 'wps';
  bool hint = true;
  @override
  Widget build(BuildContext context) {
    const names = {
      'wps': 'WPS 会员',
      'xsus': 'XSUS',
      'bilibili': 'Bilibili 大会员',
      'apple': 'Apple Music',
    };
    final rows = reference['altData'][selected] as List;
    return AppPage(
      title: '平替',
      tab: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          chips(
            names.values.toList(),
            names[selected]!,
            (v) => setState(
              () =>
                  selected = names.entries.firstWhere((e) => e.value == v).key,
            ),
          ),
          if (hint) ...[
            surface(
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 4, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: txt('订阅灵感', size: 12, weight: FontWeight.w600),
                        ),
                        IconButton(
                          tooltip: '关闭提示',
                          onPressed: () => setState(() => hint = false),
                          icon: const Icon(Icons.close, size: 16, color: muted),
                        ),
                      ],
                    ),
                    txt(
                      '以下为录屏中的服务介绍与参考价格，实际套餐和价格请以服务方为准。',
                      size: 10,
                      color: muted,
                    ),
                  ],
                ),
              ),
              color: const Color(0xffe8eaf7),
            ),
            gap(12),
          ],
          txt('「${names[selected]}」的替代方案', size: 13, weight: FontWeight.w600),
          gap(10),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: InkWell(
                onTap: () => notice(
                  context,
                  row[0],
                  '${row[2]}\n\n参考价格：${row[1]}\n此 Demo 未接入服务购买或跳转。',
                ),
                borderRadius: BorderRadius.circular(12),
                child: surface(
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 13,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        logo(brandMap[row[0]] ?? '', row[0], size: 34),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: txt(
                                      row[0],
                                      size: 13,
                                      weight: FontWeight.w600,
                                    ),
                                  ),
                                  txt(row[1], size: 10),
                                ],
                              ),
                              gap(5),
                              txt(row[2], size: 10, color: muted),
                              gap(5),
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: [
                                  for (final tag in (row[3] as String).split(
                                    '|',
                                  ))
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xfff0eff5),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: txt(tag, size: 8, color: muted),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});
  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) => dataView(ref.watch(storeProvider), (data) {
    Future<void> save(String key, Object value) => guarded(
      context,
      () => ref.read(storeProvider.notifier).setting(key, value),
    );
    Widget row(String name, String value, VoidCallback tap) => InkWell(
      onTap: tap,
      child: fieldRow(
        name,
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: txt(
                value,
                size: 10,
                color: const Color(0xffaaa7b0),
                align: TextAlign.right,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 16, color: muted),
          ],
        ),
        height: 55,
        fontSize: 13,
      ),
    );
    return AppPage(
      title: '设置',
      child: Column(
        children: [
          surface(
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  ClipOval(
                    child: Image.asset(
                      'assets/recording/avatar.png',
                      width: 51,
                      height: 51,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () async {
                            final c = TextEditingController(
                              text: data.settings['nickname'] ?? '',
                            );
                            final value = await showDialog<String>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: txt('设置昵称', size: 17),
                                content: TextField(
                                  controller: c,
                                  maxLength: 30,
                                  autofocus: true,
                                  decoration: const InputDecoration(
                                    hintText: '昵称',
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('取消'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(ctx, c.text.trim()),
                                    child: const Text('保存'),
                                  ),
                                ],
                              ),
                            );
                            if (value != null) await save('nickname', value);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: txt(
                              (data.settings['nickname'] as String?)
                                          ?.isNotEmpty ==
                                      true
                                  ? data.settings['nickname']
                                  : '点击设置昵称',
                              size: 16,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ),
                        txt('免费版', size: 10, color: muted),
                      ],
                    ),
                  ),
                  smallButton(
                    '· 解锁 Pro ›',
                    () => notice(context, 'Pro', '此 Demo 不提供 Pro 购买。'),
                    color: const Color(0xffc57d24),
                  ),
                ],
              ),
            ),
            radius: 14,
          ),
          gap(),
          surface(
            Column(
              children: [
                row(
                  '显示货币种类',
                  reference['currencyNames'][data.displayCurrency] ??
                      data.displayCurrency,
                  () async {
                    final options = currencySymbols.keys.toList();
                    final v = await pick(
                      context,
                      '选择货币',
                      options,
                      data.displayCurrency,
                    );
                    if (v != null) await save('currency', v);
                  },
                ),
                fieldRow(
                  '显示已过期订阅',
                  toggle(
                    data.settings['expired'] != false,
                    (v) => save('expired', v),
                    '显示已过期订阅',
                  ),
                  height: 55,
                  fontSize: 13,
                ),
                fieldRow(
                  '单独显示已过期',
                  toggle(
                    data.settings['separate'] == true,
                    (v) => save('separate', v),
                    '单独显示已过期',
                  ),
                  height: 55,
                  fontSize: 13,
                ),
                row('订阅列表排序', data.settings['sort'] ?? '新添加排在上方', () async {
                  final v = await pick(context, '订阅列表排序', [
                    '新添加排在上方',
                    '新添加排在下方',
                    '即将到期排在上方',
                  ], data.settings['sort'] ?? '新添加排在上方');
                  if (v != null) await save('sort', v);
                }),
                fieldRow(
                  '订阅列表布局方式',
                  segments(
                    ['正常', '紧凑'],
                    data.settings['compact'] == true ? 1 : 0,
                    (v) => save('compact', v == 1),
                  ),
                  height: 55,
                  fontSize: 13,
                ),
              ],
            ),
          ),
          gap(),
          surface(
            fieldRow(
              '订阅到期通知',
              toggle(
                false,
                (_) => notice(context, '到期通知', '此 Demo 尚未接入系统通知。'),
                '订阅到期通知',
              ),
              height: 55,
              fontSize: 13,
            ),
          ),
          gap(),
          surface(
            Column(
              children: [
                row('订单记录', '查看支付与退款', () => context.push('/orders')),
                row(
                  '用户反馈',
                  '建议采纳送 Pro',
                  () => notice(context, '用户反馈', '此 Demo 未接入反馈服务。'),
                ),
                row(
                  '导出订阅列表',
                  '发送 JSON 附件到邮箱',
                  () => notice(
                    context,
                    '导出订阅列表',
                    '此 Demo 的数据已保存在设备本地；邮件导出和完整备份暂未接入。',
                  ),
                ),
                row(
                  '产品逻辑说明',
                  '首页概览的计算方式',
                  () => notice(
                    context,
                    '首页概览说明',
                    '「月均成本」：正在生效的订阅按周期折算。\n\n「预计年支出」：本年已产生的账单加未来账单预测。\n\n「今年已支出」：截至今天已产生的账单。手动续费按付款日期入账。',
                  ),
                ),
                row(
                  '汇率更新与折算规则',
                  '手动维护 / 联网同步',
                  () => showRates(context, ref, data),
                ),
              ],
            ),
          ),
          gap(20),
          txt(
            '当前版本 0.1.0 · Android Demo\n本地保存 · 离线可用',
            size: 9,
            color: const Color(0xffb1adb5),
            align: TextAlign.center,
          ),
        ],
      ),
    );
  });
}

Future<void> showRates(
  BuildContext context,
  WidgetRef ref,
  AppData data,
) async {
  final controllers = {
    for (final code in currencySymbols.keys.where((k) => k != 'CNY'))
      code: TextEditingController(
        text: data.rates[code] == null
            ? ''
            : (data.rates[code]! / 1000000)
                  .toStringAsFixed(6)
                  .replaceFirst(RegExp(r'0+$'), '')
                  .replaceFirst(RegExp(r'\.$'), ''),
      ),
  };
  String error = '';
  bool busy = false;
  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 30),
        title: Row(
          children: [
            Expanded(
              child: txt('汇率更新与折算规则', size: 17, weight: FontWeight.w600),
            ),
            IconButton(
              tooltip: '关闭汇率设置',
              onPressed: () => Navigator.pop(ctx),
              icon: const Icon(Icons.close, size: 18),
            ),
          ],
        ),
        content: SizedBox(
          width: 320,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                txt('更新模式：初期手动维护 · 后期联网同步', size: 11, color: muted),
                gap(12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final entry in controllers.entries)
                      SizedBox(
                        width: 128,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            txt('1 ${entry.key} = 人民币', size: 11),
                            gap(4),
                            TextField(
                              controller: entry.value,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 12,
                              ),
                              decoration: const InputDecoration(
                                hintText: '待换算',
                                filled: true,
                                fillColor: Color(0xfff5f5f7),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                gap(14),
                txt(
                  '来源：${data.settings['rateSource']}\n时间：${data.settings['rateUpdatedAt']}',
                  size: 10,
                  color: muted,
                ),
                gap(12),
                surface(
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: txt(
                      '每 1 单位外币可兑换多少人民币。最多 6 位小数，必须大于 0。留空代表缺失汇率，显示待换算。\n修改汇率只重算未来账期，历史入账保留原值。',
                      size: 11,
                      color: muted,
                    ),
                  ),
                  color: const Color(0xfff5f5f7),
                ),
                if (error.isNotEmpty) ...[
                  gap(8),
                  txt(error, size: 11, color: danger),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: busy ? null : () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: busy
                ? null
                : () async {
                    final rates = <String, int>{'CNY': 1000000};
                    try {
                      for (final e in controllers.entries) {
                        if (e.value.text.trim().isNotEmpty) {
                          final value = parseFixed(
                            e.value.text,
                            6,
                            maxWhole: 1000000,
                          );
                          if (value == 0) {
                            throw const FormatException('汇率必须大于 0');
                          }
                          rates[e.key] = value;
                        }
                      }
                      setState(() => busy = true);
                      await ref.read(storeProvider.notifier).saveRates(rates);
                      if (ctx.mounted) Navigator.pop(ctx);
                    } catch (e) {
                      if (ctx.mounted) {
                        setState(() {
                          error = e is FormatException ? e.message : '保存失败，请重试';
                          busy = false;
                        });
                      }
                    }
                  },
            child: Text(busy ? '保存中…' : '保存并应用'),
          ),
        ],
      ),
    ),
  );
}
