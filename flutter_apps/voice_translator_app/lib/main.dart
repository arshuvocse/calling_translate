import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'src/app_state.dart';
import 'src/screens/auth_screen.dart';
import 'src/screens/user_list_screen.dart';

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
      title: 'AI Voice Translator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F766E)),
        useMaterial3: true,
      ),
      home: Consumer<AppState>(
        builder: (_, state, __) {
          if (!state.initialized) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return state.isAuthenticated ? const UserListScreen() : const AuthScreen();
        },
      ),
    );
  }
}
