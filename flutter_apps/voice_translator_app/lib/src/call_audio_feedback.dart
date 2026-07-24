import 'dart:async';

import 'package:flutter/services.dart';

class CallAudioFeedback {
  static const _channel = MethodChannel('voice_translator_app/call_audio');
  Timer? _ringingTimer;

  Future<void> startRingingBeeps() async {
    if (_ringingTimer != null) return;

    await _invoke('ringingBeep');
    _ringingTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _invoke('ringingBeep'),
    );
  }

  void stopRingingBeeps() {
    _ringingTimer?.cancel();
    _ringingTimer = null;
  }

  Future<void> playConnected() => _invoke('connected');

  void dispose() {
    stopRingingBeeps();
  }

  static Future<void> _invoke(String method) async {
    try {
      await _channel.invokeMethod<void>(method);
    } on MissingPluginException {
      await SystemSound.play(SystemSoundType.click);
    } on PlatformException {
      await SystemSound.play(SystemSoundType.click);
    }
  }
}
