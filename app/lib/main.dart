import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'ui.dart';
import 'pages.dart';
import 'editor.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadAssets();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xfffff3f1),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const ProviderScope(child: DingApp()));
}

final router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomePage()),
    GoRoute(
      path: '/statistics',
      builder: (context, state) => const StatisticsPage(),
    ),
    GoRoute(
      path: '/alternatives',
      builder: (context, state) => const AlternativesPage(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(path: '/library', builder: (context, state) => const LibraryPage()),
    GoRoute(
      path: '/add',
      builder: (context, state) =>
          EditorPage(name: state.uri.queryParameters['name'] ?? ''),
    ),
    GoRoute(
      path: '/detail/:id',
      builder: (context, state) => DetailPage(id: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/orders',
      builder: (context, state) => AppPage(
        title: '订单记录',
        child: Padding(
          padding: const EdgeInsets.only(top: 150),
          child: Center(child: txt('暂无订单记录', color: muted)),
        ),
      ),
    ),
  ],
);

class DingApp extends StatelessWidget {
  const DingApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: '订小阅',
    debugShowCheckedModeBanner: false,
    routerConfig: router,
    locale: const Locale('zh', 'CN'),
    supportedLocales: const [Locale('zh', 'CN')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: Colors.transparent,
      splashFactory: InkRipple.splashFactory,
      textTheme: ThemeData.light().textTheme.apply(
        bodyColor: ink,
        displayColor: ink,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        isDense: true,
        border: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(horizontal: 7, vertical: 7),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    ),
  );
}
