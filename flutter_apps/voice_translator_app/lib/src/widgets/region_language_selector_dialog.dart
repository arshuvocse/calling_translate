import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class RegionLanguageOption {
  final String code;
  final String name;
  final String flag;
  final String nativeName;

  const RegionLanguageOption({
    required this.code,
    required this.name,
    required this.flag,
    required this.nativeName,
  });
}

class RegionLanguageSelectorDialog extends StatefulWidget {
  final String currentSourceLang;
  final String currentTargetLang;
  final Function(String sourceLang, String targetLang) onSave;

  const RegionLanguageSelectorDialog({
    super.key,
    required this.currentSourceLang,
    required this.currentTargetLang,
    required this.onSave,
  });

  @override
  State<RegionLanguageSelectorDialog> createState() => _RegionLanguageSelectorDialogState();
}

class _RegionLanguageSelectorDialogState extends State<RegionLanguageSelectorDialog> {
  late String _selectedSource;
  late String _selectedTarget;

  static const List<RegionLanguageOption> regions = [
    RegionLanguageOption(code: 'bn-BD', name: 'Bengali (BD)', flag: '🇧🇩', nativeName: 'বাংলা (বাংলাদেশ)'),
    RegionLanguageOption(code: 'en-US', name: 'English (US)', flag: '🇺🇸', nativeName: 'English (United States)'),
    RegionLanguageOption(code: 'en-GB', name: 'English (UK)', flag: '🇬🇧', nativeName: 'English (United Kingdom)'),
    RegionLanguageOption(code: 'ar-SA', name: 'Arabic (SA)', flag: '🇸🇦', nativeName: 'العربية (السعودية)'),
    RegionLanguageOption(code: 'es-ES', name: 'Spanish (ES)', flag: '🇪🇸', nativeName: 'Español (España)'),
    RegionLanguageOption(code: 'fr-FR', name: 'French (FR)', flag: '🇫🇷', nativeName: 'Français (France)'),
    RegionLanguageOption(code: 'de-DE', name: 'German (DE)', flag: '🇩🇪', nativeName: 'Deutsch (Deutschland)'),
    RegionLanguageOption(code: 'ja-JP', name: 'Japanese (JP)', flag: '🇯🇵', nativeName: '日本語 (日本)'),
    RegionLanguageOption(code: 'hi-IN', name: 'Hindi (IN)', flag: '🇮🇳', nativeName: 'हिन्दी (भारत)'),
  ];

  @override
  void initState() {
    super.initState();
    _selectedSource = widget.currentSourceLang;
    _selectedTarget = widget.currentTargetLang;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.language, color: Color(0xFF6366F1), size: 24),
                SizedBox(width: 8),
                Text(
                  'Region & Language',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.signalTextPrimary),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Select source & target speech region dialects for AI Voice Translation',
              style: TextStyle(fontSize: 11, color: AppTheme.signalTextSecondary),
            ),
            const SizedBox(height: 16),

            // Source Language Selector
            const Text('My Speaking Language & Region:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 6),
            _buildDropdown(
              value: _selectedSource,
              onChanged: (val) {
                if (val != null) setState(() => _selectedSource = val);
              },
            ),
            const SizedBox(height: 16),

            // Target Language Selector
            const Text('Target Translation Language & Region:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 6),
            _buildDropdown(
              value: _selectedTarget,
              onChanged: (val) {
                if (val != null) setState(() => _selectedTarget = val);
              },
            ),
            const SizedBox(height: 24),

            // Save / Cancel Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    widget.onSave(_selectedSource, _selectedTarget);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Save Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({required String value, required ValueChanged<String?> onChanged}) {
    // Ensure value exists in list or default to first
    final currentValue = regions.any((r) => r.code == value) ? value : 'bn-BD';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentValue,
          isExpanded: true,
          onChanged: onChanged,
          items: regions.map((item) {
            return DropdownMenuItem<String>(
              value: item.code,
              child: Row(
                children: [
                  Text(item.flag, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const Spacer(),
                  Text(item.nativeName, style: const TextStyle(fontSize: 11, color: Colors.black45)),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
