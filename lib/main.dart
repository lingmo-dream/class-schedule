// 应用入口：配置主题、Provider 和根页面。
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'pages/home_page.dart';
import 'state/app_state.dart';
import 'state/time_settings.dart';
import 'storage/storage.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState(Storage())),
        ChangeNotifierProvider(create: (_) => TimeSettings()),
      ],
      child: const ScheduleApp(),
    ),
  );
}

class ScheduleApp extends StatelessWidget {
  const ScheduleApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: '外事课程表',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff155e75)),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xfff6f8fa),
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: Color(0xfff6f8fa),
        minWidth: 82,
      ),
      navigationBarTheme: const NavigationBarThemeData(height: 70),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        isDense: true,
      ),
    ),
    home: const HomePage(),
  );
}
