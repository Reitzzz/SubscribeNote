import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dingxiaoyue/main.dart';
import 'package:dingxiaoyue/pages.dart';
import 'package:dingxiaoyue/store.dart';
import 'package:dingxiaoyue/ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await loadAssets();
    final iconFont = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await iconFont.load();
    final font = File('C:/Windows/Fonts/msyh.ttc');
    if (await font.exists()) {
      final loader = FontLoader('Roboto')
        ..addFont(
          font.readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
        );
      await loader.load();
    }
  });
  testWidgets('prototype layouts and add/detail/navigation flow', (
    tester,
  ) async {
    Future<void> capture(String path) async {
      if (const bool.fromEnvironment('CAPTURE_UI')) {
        await expectLater(find.byType(DingApp), matchesGoldenFile(path));
      }
    }

    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    await tester.runAsync(() => container.read(storeProvider.future));
    addTearDown(() async {
      container.dispose();
      await db.close();
    });
    router.go('/');
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const DingApp()),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final context = tester.element(find.byType(DingApp));
      for (final file in Directory(
        'assets/recording',
      ).listSync().whereType<File>()) {
        await precacheImage(
          AssetImage('assets/recording/${file.uri.pathSegments.last}'),
          context,
        );
      }
    });
    await tester.pumpAndSettle();
    expect(find.text('订小阅'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await capture('goldens/home-390.png');
    router.push(
      '/detail/${container.read(storeProvider).requireValue.subscriptions.first.id}',
    );
    await tester.pumpAndSettle();
    expect(find.text('扣费详情'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await capture('goldens/detail-390.png');
    await tester.tap(find.text('订阅更新'));
    await tester.pumpAndSettle();
    expect(find.text('确认更新'), findsOneWidget);
    await capture('goldens/update-390.png');
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    router.go('/library');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await capture('goldens/library-390.png');
    await tester.tap(find.text('手动创建'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('添加订阅').last);
    await tester.pumpAndSettle();
    expect(find.text('请输入订阅名称'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), '离线测试');
    await tester.enterText(find.byType(TextFormField).at(1), '12.34');
    await tester.pumpAndSettle();
    await capture('goldens/add-390.png');
    await tester.tap(find.text('添加订阅').last);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pumpAndSettle();
    expect(find.text('扣费详情'), findsOneWidget);
    expect(
      container
          .read(storeProvider)
          .requireValue
          .subscriptions
          .any((s) => s.name == '离线测试'),
      isTrue,
    );
    expect(
      container
          .read(storeProvider)
          .requireValue
          .subscriptions
          .firstWhere((s) => s.name == '离线测试')
          .amount,
      1234,
    );
    router.go('/statistics');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await capture('goldens/statistics-390.png');
    await tester.tap(find.text('◔ 占比'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await capture('goldens/ratio-390.png');
    router.go('/settings');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await capture('goldens/settings-390.png');
    for (final size in [const Size(375, 812), const Size(812, 375)]) {
      tester.view.physicalSize = size;
      for (final path in [
        '/',
        '/library',
        '/add',
        '/statistics',
        '/settings',
      ]) {
        router.go(path);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$path $size');
      }
    }
    router.go('/');
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);
  });
}
