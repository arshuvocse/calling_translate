import 'package:flutter/services.dart';

class IncomingRingtone {
  static const _channel = MethodChannel('voice_translator_app/ringtone');

  static Future<void> start() => _invoke('start');

  static Future<void> stop() => _invoke('stop');

  static Future<void> _invoke(String method) async {
    try {
      await _channel.invokeMethod<void>(method);
    } on MissingPluginException {
      // Non-Android platforms can still show the incoming call UI.
    } on PlatformException {
      // Ringtone availability depends on device settings; call flow should continue.
    }
  }
}
