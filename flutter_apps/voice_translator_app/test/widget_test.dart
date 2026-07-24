// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:voice_translator_app/src/app_state.dart';
import 'package:voice_translator_app/main.dart';

void main() {
  testWidgets('Shows auth screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState()..restoreSession(),
        child: const VoiceTranslatorApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('AI Voice Translator'), findsOneWidget);
    expect(find.text('Login'), findsWidgets);
  });
}
