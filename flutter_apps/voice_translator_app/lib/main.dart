import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'src/app_state.dart';
import 'src/screens/auth_screen.dart';
import 'src/screens/main_shell_screen.dart';
import 'src/theme/app_theme.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState()..restoreSession(),
      child: const VoiceTranslatorApp(),
    ),
  );
}

class VoiceTranslatorApp extends StatelessWidget {
  const VoiceTranslatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CONNECT - One Universe',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: Consumer<AppState>(
        builder: (_, state, __) {
          if (!state.initialized) {
            return const Scaffold(
              backgroundColor: AppTheme.cosmicBackground,
              body: Center(
                child: CircularProgressIndicator(color: AppTheme.cosmicAccentPurple),
              ),
            );
          }
          return state.isAuthenticated ? const MainShellScreen() : const AuthScreen();
        },
      ),
    );
  }
}
