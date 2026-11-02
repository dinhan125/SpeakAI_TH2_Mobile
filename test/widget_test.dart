import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:th2/core/services/study_time_tracker.dart';
import 'package:th2/main.dart';
import 'package:th2/presentation/screens/main_navigation_screen.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() {
    StudyTimeTracker.instance.stopAndReset();
  });

  testWidgets('SpeakAI App Smoke Test: boots and renders MainNavigationScreen with 5 tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const SpeakAiApp());
    await tester.pump();

    // Verify main navigation is rendered with 5 destinations
    expect(find.byType(MainNavigationScreen), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(5));
    expect(find.text('Trang chủ'), findsOneWidget);
    expect(find.text('Lộ trình'), findsWidgets);
    expect(find.text('Luyện tập'), findsOneWidget);
    expect(find.text('Thống kê'), findsOneWidget);
    expect(find.text('Cá nhân'), findsOneWidget);
  });
}
