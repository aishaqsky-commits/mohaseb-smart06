import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

void main() {
  runApp(const MohasebSmartApp());
}

class MohasebSmartApp extends StatelessWidget {
  const MohasebSmartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Mohaseb Smart',
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
      // تهيئة الـ RTL وإعدادات اللغة العربية كافتراضية
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar', 'YE'),
      ],
      locale: const Locale('ar', 'YE'),
      debugShowCheckedModeBanner: false,
    );
  }
}
