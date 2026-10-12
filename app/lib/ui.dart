import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'domain.dart';

const ink = Color(0xff17172a),
    primary = Color(0xff17162f),
    muted = Color(0xff8b8997),
    danger = Color(0xfff25247);
const pageGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xffedf4ff), Color(0xfff7f4fb), Color(0xfffff3f1)],
  stops: [0, .54, 1],
);
const blueGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xff243858), Color(0xff12264a), Color(0xff18335d)],
  stops: [0, .72, 1],
);
late Map<String, dynamic> reference;
late Map<String, dynamic> svgIcons;
Future<void> loadAssets() async {
  reference = jsonDecode(await rootBundle.loadString('assets/reference.json'));
  svgIcons = jsonDecode(await rootBundle.loadString('assets/icons.json'));
}

Text txt(
  String s, {
  double size = 13,
  Color color = ink,
  FontWeight weight = FontWeight.w400,
  TextAlign? align,
  int? lines,
}) => Text(
  s,
  textAlign: align,
  maxLines: lines,
  overflow: lines == null ? null : TextOverflow.ellipsis,
  style: TextStyle(
    fontFamily: 'Roboto',
    fontSize: size,
    color: color,
    fontWeight: weight,
    height: 1.35,
  ),
);
Widget gap([double height = 10]) => SizedBox(height: height);
Widget symbol(String name, {double size = 22, Color color = primary}) =>
    SvgPicture.string(
      svgIcons[name] as String,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
Widget logo(String icon, String name, {double size = 40}) {
  if (icon == 'claude') {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: size > 44
            ? Colors.transparent
            : Colors.white.withValues(alpha: .33),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            txt('A', size: size > 44 ? 29 : 21, weight: FontWeight.w800),
            SvgPicture.string(
              '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 14 12"><path d="M1 4L7 7L6 4L13 7" fill="none" stroke="#17172a" stroke-width="1.3"/></svg>',
              width: size * .3,
              height: size * .3,
            ),
          ],
        ),
      ),
    );
  }
  if (icon.startsWith('generic:')) {
    return SizedBox(
      width: size,
      height: size,
      child: Icon(
        genericIcons[icon.substring(8)] ?? Icons.apps_outlined,
        size: size * .7,
        color: primary,
      ),
    );
  }
  return ClipRRect(
    borderRadius: BorderRadius.circular(size / 4),
    child: SizedBox(
      width: size,
      height: size,
      child: icon.isEmpty
          ? ColoredBox(
              color: Colors.white54,
              child: Center(
                child: txt(
                  name.isEmpty ? '+' : name.characters.first,
                  size: size * .48,
                  weight: FontWeight.w700,
                ),
              ),
            )
          : Image.asset('assets/recording/$icon.png', fit: BoxFit.contain),
    ),
  );
}

const genericIcons = {
  'calendar': Icons.calendar_month_outlined,
  'wallet': Icons.account_balance_wallet_outlined,
  'camera': Icons.camera_alt_outlined,
  'cloud': Icons.cloud_outlined,
  'bag': Icons.shopping_bag_outlined,
  'heart': Icons.favorite_border,
};

Widget surface(
  Widget child, {
  Color? color,
  Gradient? gradient,
  double radius = 13,
  double minHeight = 0,
  EdgeInsets? padding,
}) => Container(
  width: double.infinity,
  constraints: BoxConstraints(minHeight: minHeight),
  padding: padding,
  clipBehavior: Clip.antiAlias,
  decoration: BoxDecoration(
    color: gradient == null
        ? color ?? Colors.white.withValues(alpha: .82)
        : null,
    gradient: gradient,
    borderRadius: BorderRadius.circular(radius),
  ),
  child: child,
);

Widget action(
  String label,
  VoidCallback? onTap, {
  bool secondary = false,
  bool destructive = false,
}) => SizedBox(
  height: 44,
  child: FilledButton(
    onPressed: onTap,
    style: FilledButton.styleFrom(
      backgroundColor: destructive
          ? danger
          : secondary
          ? const Color(0xfff5f4f6)
          : primary,
      foregroundColor: secondary ? ink : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      textStyle: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    ),
    child: Text(label),
  ),
);

Widget smallButton(
  String label,
  VoidCallback onTap, {
  Color? color,
  double height = 44,
}) => TextButton(
  onPressed: onTap,
  style: TextButton.styleFrom(
    foregroundColor: color ?? muted,
    minimumSize: Size(44, height),
    padding: const EdgeInsets.symmetric(horizontal: 7),
    textStyle: const TextStyle(fontFamily: 'Roboto', fontSize: 11),
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Flexible(child: Text(label.replaceAll('⌄', ''))),
      if (label.contains('⌄')) const Icon(Icons.keyboard_arrow_down, size: 12),
    ],
  ),
);

Widget fieldRow(
  String label,
  Widget value, {
  double height = 52,
  double fontSize = 11,
}) => Container(
  constraints: BoxConstraints(minHeight: height),
  padding: const EdgeInsets.symmetric(horizontal: 12),
  decoration: const BoxDecoration(
    border: Border(bottom: BorderSide(color: Color(0x131f1e30), width: .5)),
  ),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Flexible(child: txt(label, size: fontSize)),
      const SizedBox(width: 8),
      Flexible(flex: 2, child: value),
    ],
  ),
);

Widget toggle(bool value, ValueChanged<bool>? change, String label) =>
    Semantics(
      label: label,
      toggled: value,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: Transform.scale(
            scale: .76,
            child: Switch(
              value: value,
              onChanged: change,
              activeTrackColor: primary,
              inactiveTrackColor: const Color(0xffdddde2),
              inactiveThumbColor: Colors.white,
              trackOutlineColor: const WidgetStatePropertyAll(
                Colors.transparent,
              ),
            ),
          ),
        ),
      ),
    );

Widget segments(
  List<String> labels,
  int selected,
  ValueChanged<int> onTap, {
  bool wide = false,
}) => Container(
  padding: const EdgeInsets.all(2),
  decoration: BoxDecoration(
    color: const Color(0x0e232134),
    borderRadius: BorderRadius.circular(7),
  ),
  child: Row(
    mainAxisSize: wide ? MainAxisSize.max : MainAxisSize.min,
    children: [
      for (var i = 0; i < labels.length; i++)
        if (wide)
          Expanded(
            child: segment(labels[i], i == selected, () => onTap(i), wide),
          )
        else
          segment(labels[i], i == selected, () => onTap(i), wide),
    ],
  ),
);
Widget segment(String label, bool selected, VoidCallback tap, bool wide) =>
    Semantics(
      selected: selected,
      child: TextButton(
        onPressed: tap,
        style: TextButton.styleFrom(
          minimumSize: Size(wide ? 0 : 64, 33),
          padding: const EdgeInsets.symmetric(horizontal: 9),
          backgroundColor: selected ? primary : Colors.transparent,
          foregroundColor: selected ? Colors.white : muted,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: TextStyle(fontFamily: 'Roboto', fontSize: wide ? 12 : 10),
        ),
        child: Text(label),
      ),
    );

Widget chips(List<String> labels, String selected, ValueChanged<String> tap) =>
    SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final label in labels)
            Padding(
              padding: const EdgeInsets.only(right: 7, bottom: 8),
              child: Semantics(
                selected: label == selected,
                child: TextButton(
                  onPressed: () => tap(label),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: const Size(0, 34),
                    foregroundColor: label == selected ? Colors.white : muted,
                    backgroundColor: label == selected
                        ? primary
                        : Colors.white.withValues(alpha: .45),
                    textStyle: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 11,
                    ),
                  ),
                  child: Text(label),
                ),
              ),
            ),
        ],
      ),
    );

class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    required this.title,
    required this.child,
    this.tab,
    this.bottom,
    this.fab,
    this.trailing,
    this.scroll = true,
    this.topPadding = 4,
  });
  final String title;
  final Widget child;
  final int? tab;
  final Widget? bottom, fab, trailing;
  final bool scroll;
  final double topPadding;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(gradient: pageGradient),
    child: Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SizedBox(
              height: 52,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 68,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: tab != null
                            ? IconButton(
                                tooltip: '打开设置',
                                onPressed: () => context.push('/settings'),
                                icon: ClipOval(
                                  child: Image.asset(
                                    'assets/recording/avatar.png',
                                    width: 34,
                                    height: 34,
                                  ),
                                ),
                              )
                            : IconButton(
                                tooltip: '返回',
                                onPressed: () => context.canPop()
                                    ? context.pop()
                                    : context.go('/'),
                                icon: symbol('arrow'),
                              ),
                      ),
                    ),
                    Expanded(
                      child: txt(
                        title,
                        size: 17,
                        weight: FontWeight.w600,
                        align: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 68, child: trailing),
                  ],
                ),
              ),
            ),
            Expanded(
              child: scroll
                  ? SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(12, topPadding, 12, 28),
                      child: child,
                    )
                  : child,
            ),
          ],
        ),
      ),
      bottomNavigationBar: bottom == null && tab == null
          ? null
          : SafeArea(
              top: false,
              child:
                  bottom ??
                  Container(
                    height: 64,
                    decoration: const BoxDecoration(
                      color: Color(0xc2ffffff),
                      border: Border(top: BorderSide(color: Color(0x0d232137))),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 44),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (var i = 0; i < 3; i++)
                          Semantics(
                            selected: tab == i,
                            child: TextButton(
                              onPressed: () => context.go(
                                ['/', '/statistics', '/alternatives'][i],
                              ),
                              style: TextButton.styleFrom(
                                minimumSize: const Size(60, 54),
                                padding: EdgeInsets.zero,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  symbol(
                                    ['home', 'chart', 'bulb'][i],
                                    color: tab == i
                                        ? primary
                                        : const Color(0xffa5a1ab),
                                  ),
                                  gap(2),
                                  txt(
                                    ['首页', '统计', '平替'][i],
                                    size: 9,
                                    color: tab == i
                                        ? primary
                                        : const Color(0xffa5a1ab),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
            ),
      floatingActionButton: fab,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    ),
  );
}

Future<void> notice(BuildContext context, String title, String message) =>
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: txt(title, size: 17, weight: FontWeight.w600),
        content: txt(message, size: 12, color: muted),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
        ],
      ),
    );

Future<T?> sheet<T>(BuildContext context, String title, Widget child) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                txt(title, size: 17, weight: FontWeight.w600),
                gap(13),
                child,
              ],
            ),
          ),
        ),
      ),
    );

Future<String?> pick(
  BuildContext context,
  String title,
  List<String> options,
  String current,
) async {
  var selected = current;
  return sheet<String>(
    context,
    title,
    StatefulBuilder(
      builder: (context, setState) => Column(
        children: [
          SizedBox(
            height: 210,
            child: ListView(
              children: [
                for (final item in options)
                  TextButton(
                    onPressed: () => setState(() => selected = item),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(double.infinity, 44),
                      backgroundColor: selected == item
                          ? const Color(0xfff4f4f7)
                          : null,
                    ),
                    child: txt(
                      item,
                      size: 14,
                      color: selected == item ? ink : muted,
                      weight: selected == item
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
              ],
            ),
          ),
          gap(),
          Row(
            children: [
              Expanded(
                child: action(
                  '取消',
                  () => Navigator.pop(context),
                  secondary: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: action('确定', () => Navigator.pop(context, selected)),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Future<DateTime?> pickDate(
  BuildContext context,
  DateTime current, {
  DateTime? first,
}) async {
  final picked = await showDatePicker(
    context: context,
    initialDate: current,
    firstDate: first ?? DateTime(1900),
    lastDate: DateTime(2100, 12, 31),
    locale: const Locale('zh', 'CN'),
  );
  return picked == null ? null : day(picked);
}

Future<int?> pickColor(BuildContext context, int current) async {
  final colors = [
    0xffd97757,
    0xffd4252b,
    0xffd64453,
    0xff19a9d2,
    0xffef4055,
    0xff4f7ee9,
    0xffffae35,
    0xff10a37f,
    0xff695dff,
    0xff999999,
    0xff48b4d0,
    0xff17162f,
  ];
  return sheet<int>(
    context,
    '卡片颜色',
    Wrap(
      spacing: 14,
      runSpacing: 14,
      children: [
        for (final c in colors)
          Semantics(
            label: '#${c.toRadixString(16).substring(2).toUpperCase()}',
            selected: c == current,
            child: InkWell(
              onTap: () => Navigator.pop(context, c),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Color(c),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: c == current ? primary : Colors.white,
                    width: 3,
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

Future<String?> pickIcon(BuildContext context, String current) => sheet<String>(
  context,
  '选择订阅图标',
  Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final id in [
        'claude',
        'wps',
        'xsus',
        'bilibili',
        'apple',
        'anti',
        'tencent',
        'chatgpt',
        'telegram',
        'spotify',
        ...genericIcons.keys.map((k) => 'generic:$k'),
      ])
        IconButton(
          tooltip: id,
          onPressed: () => Navigator.pop(context, id),
          icon: logo(id, id, size: 32),
        ),
    ],
  ),
);

Future<void> guarded(
  BuildContext context,
  Future<void> Function() operation,
) async {
  try {
    await operation();
  } catch (e) {
    if (context.mounted) await notice(context, '未能保存', '数据未保存，请重试。\n$e');
  }
}
