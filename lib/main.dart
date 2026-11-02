import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:th2/core/constants/app_constants.dart';
import 'package:th2/core/services/notification_service.dart';
import 'package:th2/core/theme/app_theme.dart';
import 'package:th2/presentation/providers/curriculum_provider.dart';
import 'package:th2/presentation/providers/practice_provider.dart';
import 'package:th2/presentation/providers/streak_provider.dart';
import 'package:th2/presentation/providers/user_provider.dart';
import 'package:th2/presentation/screens/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Multiplatform SQLite FFI initialization for Web / Desktop / Tests
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Initialize background notification service
  await NotificationService.instance.init();

  runApp(const SpeakAiApp());
}

class SpeakAiApp extends StatelessWidget {
  const SpeakAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<UserProvider>(
          create: (_) => UserProvider()..loadUser(),
        ),
        ChangeNotifierProvider<StreakProvider>(
          create: (_) => StreakProvider()..initStreak(),
        ),
        ChangeNotifierProvider<PracticeProvider>(
          create: (_) => PracticeProvider()..loadSentences(),
        ),
        ChangeNotifierProvider<CurriculumProvider>(
          create: (_) => CurriculumProvider()..loadCurriculum(),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light, // Set light mode as default
        home: const MainNavigationScreen(),
      ),
    );
  }
}
