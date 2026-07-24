import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final displayName = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  var registerMode = false;
  var sourceLanguage = 'bn';
  var targetLanguage = 'en';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: ListView(
              padding: const EdgeInsets.all(24),
              shrinkWrap: true,
              children: [
                Text('AI Voice Translator', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                const Text('Voice translation requires consent from every caller. Voice cloning is intentionally not enabled in this MVP.'),
                const SizedBox(height: 24),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('Login')),
                    ButtonSegment(value: true, label: Text('Register')),
                  ],
                  selected: {registerMode},
                  onSelectionChanged: (value) => setState(() => registerMode = value.first),
                ),
                const SizedBox(height: 16),
                if (registerMode)
                  TextField(
                    controller: displayName,
                    decoration: const InputDecoration(labelText: 'Display name', border: OutlineInputBorder()),
                  ),
                if (registerMode) const SizedBox(height: 12),
                TextField(
                  controller: email,
                  decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: password,
                  decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                  obscureText: true,
                ),
                if (registerMode) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _LanguagePicker(label: 'Source', value: sourceLanguage, onChanged: (v) => setState(() => sourceLanguage = v))),
                      const SizedBox(width: 12),
                      Expanded(child: _LanguagePicker(label: 'Target', value: targetLanguage, onChanged: (v) => setState(() => targetLanguage = v))),
                    ],
                  ),
                ],
                if (state.error != null) ...[
                  const SizedBox(height: 12),
                  Text(state.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: state.loading ? null : _submit,
                  child: Text(state.loading ? 'Please wait...' : registerMode ? 'Create account' : 'Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final state = context.read<AppState>();
    if (registerMode) {
      await state.register(displayName.text, email.text, password.text, sourceLanguage, targetLanguage);
    } else {
      await state.login(email.text, password.text);
    }
  }
}

class _LanguagePicker extends StatelessWidget {
  const _LanguagePicker({required this.label, required this.value, required this.onChanged});

  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      items: const [
        DropdownMenuItem(value: 'bn', child: Text('Bangla')),
        DropdownMenuItem(value: 'en', child: Text('English')),
        DropdownMenuItem(value: 'hi', child: Text('Hindi')),
        DropdownMenuItem(value: 'ar', child: Text('Arabic')),
      ],
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}
