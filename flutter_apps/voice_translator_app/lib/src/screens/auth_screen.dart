import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../theme/app_theme.dart';

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
  var sourceLanguage = 'bn-BD';
  var targetLanguage = 'en-US';

  @override
  void dispose() {
    displayName.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppTheme.cosmicBackground,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Radial Cosmic Background Glow
          Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.cosmicOrbitalGlow,
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    children: [
                      // Cosmic App Logo & Title
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppTheme.purpleGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.cosmicAccentPurple.withValues(alpha: 0.6),
                              blurRadius: 24,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'CONNECT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'One Universe. All Connections.',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Glassmorphism Card Container
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppTheme.cosmicCardBg.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: AppTheme.cosmicAccentPurple.withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Segmented Switcher (Login / Register)
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0D0A22),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppTheme.cosmicCardBorder),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _buildModeTab(
                                      title: 'Login',
                                      isSelected: !registerMode,
                                      onTap: () => setState(() => registerMode = false),
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildModeTab(
                                      title: 'Register',
                                      isSelected: registerMode,
                                      onTap: () => setState(() => registerMode = true),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Display Name (Register Mode Only)
                            if (registerMode) ...[
                              _buildTextField(
                                controller: displayName,
                                hint: 'Display Name',
                                icon: Icons.person_outline,
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Email Field
                            _buildTextField(
                              controller: email,
                              hint: 'Email Address',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 16),

                            // Password Field
                            _buildTextField(
                              controller: password,
                              hint: 'Password',
                              icon: Icons.lock_outline,
                              isObscure: true,
                            ),

                            // Language & Region Selector (Register Mode Only)
                            if (registerMode) ...[
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildLanguageDropdown(
                                      label: 'My Language',
                                      value: sourceLanguage,
                                      onChanged: (val) => setState(() => sourceLanguage = val),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildLanguageDropdown(
                                      label: 'Target Language',
                                      value: targetLanguage,
                                      onChanged: (val) => setState(() => targetLanguage = val),
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            // Error Message
                            if (state.error != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                                ),
                                child: Text(
                                  state.error!,
                                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),

                            // Glowing Neon Submit Button
                            GestureDetector(
                              onTap: state.loading ? null : _submit,
                              child: Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  gradient: AppTheme.purpleGradient,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.cosmicAccentPurple.withValues(alpha: 0.5),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: state.loading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                        )
                                      : Text(
                                          registerMode ? 'Create Galaxy Account' : 'Connect to Galaxy',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Consent Subtext
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shield_outlined, color: Colors.white38, size: 14),
                          SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'End-to-end encrypted live voice translation',
                              style: TextStyle(color: Colors.white38, fontSize: 11),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTab({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.cosmicAccentPurple : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.cosmicAccentPurple.withValues(alpha: 0.4),
                    blurRadius: 8,
                  ),
                ]
              : [],
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white54,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isObscure = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D0A22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cosmicCardBorder),
      ),
      child: TextField(
        controller: controller,
        obscureText: isObscure,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
          prefixIcon: Icon(icon, color: Colors.white38, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildLanguageDropdown({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0D0A22),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.cosmicCardBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: AppTheme.cosmicCardBg,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              items: const [
                DropdownMenuItem(value: 'bn-BD', child: Text('🇧🇩 Bangla')),
                DropdownMenuItem(value: 'en-US', child: Text('🇺🇸 English')),
                DropdownMenuItem(value: 'ar-SA', child: Text('🇸🇦 Arabic')),
                DropdownMenuItem(value: 'es-ES', child: Text('🇪🇸 Spanish')),
                DropdownMenuItem(value: 'hi-IN', child: Text('🇮🇳 Hindi')),
              ],
              onChanged: (val) {
                if (val != null) onChanged(val);
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final state = context.read<AppState>();
    if (registerMode) {
      await state.register(displayName.text.trim(), email.text.trim(), password.text.trim(), sourceLanguage, targetLanguage);
    } else {
      await state.login(email.text.trim(), password.text.trim());
    }
  }
}
