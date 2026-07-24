import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:signalr_netcore/signalr_client.dart' as signalr;

import '../app_state.dart';
import '../call_audio_feedback.dart';
import '../config.dart';
import '../models.dart';

class CallScreen extends StatefulWidget {
  const CallScreen.outgoing({super.key, required this.remoteUser})
    : incomingCallSessionId = null,
      incomingCallerName = null,
      incomingSourceLanguage = null,
      incomingTargetLanguage = null;

  const CallScreen.incoming({
    super.key,
    required this.remoteUser,
    required this.incomingCallSessionId,
    required this.incomingCallerName,
    required this.incomingSourceLanguage,
    required this.incomingTargetLanguage,
  });

  final AppUser remoteUser;
  final String? incomingCallSessionId;
  final String? incomingCallerName;
  final String? incomingSourceLanguage;
  final String? incomingTargetLanguage;

  bool get isIncoming => incomingCallSessionId != null;

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  static const _sampleRate = 16000;
  static const _channels = 1;
  static const _bytesPerSample = 2;
  static const _chunkMilliseconds = 500;

  final player = AudioPlayer();
  final recorder = AudioRecorder();
  final audioBuffer = BytesBuilder(copy: false);
  final remoteRenderer = RTCVideoRenderer();
  final audioFeedback = CallAudioFeedback();

  signalr.HubConnection? hub;
  RTCPeerConnection? peerConnection;
  MediaStream? localStream;
  MediaStream? remoteStream;
  StreamSubscription<Uint8List>? audioSubscription;

  var sourceLanguage = 'bn-BD';
  var targetLanguage = 'en-US';
  var status = 'ready';
  var translatedText = '';
  String? callSessionId;

  bool get _live =>
      status == 'ringing' || status == 'connecting' || status == 'live';

  @override
  void initState() {
    super.initState();
    sourceLanguage =
        widget.incomingSourceLanguage ??
        widget.remoteUser.preferredSourceLanguage;
    targetLanguage =
        widget.incomingTargetLanguage ??
        widget.remoteUser.preferredTargetLanguage;
    callSessionId = widget.incomingCallSessionId;
    remoteRenderer.initialize();
    if (widget.isIncoming) {
      status = 'incoming';
    }
  }

  @override
  void dispose() {
    _closeMedia();
    audioFeedback.dispose();
    remoteRenderer.dispose();
    recorder.dispose();
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isIncoming
        ? (widget.incomingCallerName ?? widget.remoteUser.displayName)
        : widget.remoteUser.displayName;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF123A5C), Color(0xFF0A7C86), Color(0xFFF4F8FB)],
            stops: [0, 0.48, 1],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 96, 16, 24),
          children: [
            _GlossPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF13B7A8), Color(0xFF276EF1)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF13B7A8,
                              ).withValues(alpha: 0.26),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.graphic_eq,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Live translated call',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'WebRTC carries the live call audio. SignalR carries call signaling and translated AI audio.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _GlossPanel(
              child: Row(
                children: [
                  Expanded(
                    child: _LanguagePicker(
                      label: 'You speak',
                      value: sourceLanguage,
                      onChanged: _live
                          ? null
                          : (v) => setState(() => sourceLanguage = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _LanguagePicker(
                      label: 'You hear translation',
                      value: targetLanguage,
                      onChanged: _live
                          ? null
                          : (v) => setState(() => targetLanguage = v),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Container(
                width: 172,
                height: 172,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.92),
                      Colors.white.withValues(alpha: 0.58),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.82),
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 28,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _live ? Icons.graphic_eq : Icons.call,
                      size: 64,
                      color: _live
                          ? const Color(0xFF008D7F)
                          : const Color(0xFF506272),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      status,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: const Color(0xFF153246),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _GlossPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Translated text from remote speaker',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(minHeight: 80),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7FBFC),
                      border: Border.all(color: const Color(0xFFDDE9EC)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      translatedText.isEmpty
                          ? 'Waiting for translated speech...'
                          : translatedText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (widget.isIncoming && status == 'incoming') ...[
              FilledButton.icon(
                onPressed: () => _runCallAction(_acceptIncomingCall),
                icon: const Icon(Icons.call),
                label: const Text('Accept call'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: const Color(0xFF0C766F),
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _runCallAction(_rejectIncomingCall),
                icon: const Icon(Icons.call_end),
                label: const Text('Reject'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                ),
              ),
            ] else
              FilledButton.icon(
                onPressed: _live
                    ? () => _runCallAction(_endCall)
                    : () => _runCallAction(_startOutgoingCall),
                icon: Icon(_live ? Icons.call_end : Icons.call),
                label: Text(_live ? 'End call' : 'Start call'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: _live
                      ? const Color(0xFFE94747)
                      : const Color(0xFF0C766F),
                  foregroundColor: Colors.white,
                ),
              ),
            SizedBox(
              width: 1,
              height: 1,
              child: Opacity(opacity: 0, child: RTCVideoView(remoteRenderer)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runCallAction(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      await _closeMedia();
      if (mounted) _setStatus(_friendlyError(error));
    }
  }

  Future<void> _startOutgoingCall() async {
    final state = context.read<AppState>();
    final auth = state.currentUser!;
    _setStatus('connecting');

    await _connectHub(auth.token);
    await _preparePeerConnection();
    await _startAudioStream(auth.userId);

    final response = _asMap(
      await hub!.invoke(
        'StartCall',
        args: [
          {
            'calleeUserId': widget.remoteUser.id,
            'callerDisplayName': auth.displayName,
            'sourceLanguage': sourceLanguage,
            'targetLanguage': targetLanguage,
            'calleeSourceLanguage': targetLanguage,
            'calleeTargetLanguage': sourceLanguage,
          },
        ],
      ),
    );

    callSessionId = _stringValue(response, 'callSessionId');
    _setStatus(_stringValue(response, 'status') ?? 'ringing');
  }

  Future<void> _acceptIncomingCall() async {
    final id = callSessionId;
    if (id == null) return;
    final state = context.read<AppState>();
    final auth = state.currentUser!;
    _setStatus('connecting');

    await _connectHub(auth.token);
    await _preparePeerConnection();
    await hub!.invoke('AcceptCall', args: [id]);
    await _startAudioStream(auth.userId);
  }

  Future<void> _rejectIncomingCall() async {
    final id = callSessionId;
    if (id == null) return;
    await _connectHub(context.read<AppState>().currentUser!.token);
    await hub!.invoke('RejectCall', args: [id]);
    if (mounted) Navigator.of(context).pop();
  }

  String _friendlyError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    if (message.contains('ModSecurity')) {
      return 'Request blocked by hosting security (403 ModSecurity Action).';
    }
    return message.isEmpty ? 'Call failed.' : message;
  }

  Future<void> _connectHub(String token) async {
    if (hub != null) return;

    final connection = signalr.HubConnectionBuilder()
        .withUrl(
          AppConfig.hub('/hubs/calls'),
          options: signalr.HttpConnectionOptions(
            accessTokenFactory: () async => token,
            transport: signalr.HttpTransportType.WebSockets,
            skipNegotiation: true,
          ),
        )
        .withAutomaticReconnect()
        .build();

    connection.on('CallAccepted', (args) async {
      if (!_matchesCall(args)) return;
      _setStatus('live');
      if (!widget.isIncoming) await _sendOffer();
    });

    connection.on('CallRejected', (args) {
      if (_matchesCall(args)) _finishAsEnded('rejected');
    });

    connection.on('CallEnded', (args) {
      if (_matchesCall(args)) _finishAsEnded('ended');
    });

    connection.on('ReceiveOffer', (args) async {
      final map = _firstMap(args);
      if (!_isCurrentCall(map)) return;
      await _handleOffer(map);
    });

    connection.on('ReceiveAnswer', (args) async {
      final map = _firstMap(args);
      if (!_isCurrentCall(map)) return;
      await peerConnection?.setRemoteDescription(
        RTCSessionDescription(
          _stringValue(map, 'sdp'),
          _stringValue(map, 'type'),
        ),
      );
    });

    connection.on('ReceiveIceCandidate', (args) async {
      final map = _firstMap(args);
      if (!_isCurrentCall(map)) return;
      await peerConnection?.addCandidate(
        RTCIceCandidate(
          _stringValue(map, 'candidate'),
          _stringValue(map, 'sdpMid'),
          _toInt(_value(map, 'sdpMLineIndex')),
        ),
      );
    });

    connection.on('TranslationReceived', (args) async {
      final map = _firstMap(args);
      if (!_isCurrentCall(map)) return;
      setState(
        () => translatedText = _stringValue(map, 'translatedText') ?? '',
      );
      final audioBase64 = _stringValue(map, 'translatedAudioBase64');
      if (audioBase64 != null && audioBase64.isNotEmpty) {
        await player.play(BytesSource(base64Decode(audioBase64)));
      }
    });

    connection.onclose(({error}) => _finishAsEnded('ended'));
    hub = connection;
    await connection.start();
  }

  Future<void> _preparePeerConnection() async {
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) throw Exception('Microphone permission is required.');

    localStream = await navigator.mediaDevices.getUserMedia({
      'audio': {'echoCancellation': true, 'noiseSuppression': true},
      'video': false,
    });

    final peer = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    });

    peer.onIceCandidate = (candidate) {
      final id = callSessionId;
      if (id == null || candidate.candidate == null) return;
      hub?.invoke(
        'SendIceCandidate',
        args: [
          {
            'callSessionId': id,
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          },
        ],
      );
    };

    peer.onTrack = (event) async {
      remoteStream ??= await createLocalMediaStream('remote-audio');
      for (final track in event.streams.expand(
        (stream) => stream.getTracks(),
      )) {
        await remoteStream!.addTrack(track);
      }
      remoteRenderer.srcObject = remoteStream;
    };

    for (final track in localStream!.getAudioTracks()) {
      await peer.addTrack(track, localStream!);
    }

    peerConnection = peer;
  }

  Future<void> _sendOffer() async {
    final offer = await peerConnection!.createOffer({'offerToReceiveAudio': 1});
    await peerConnection!.setLocalDescription(offer);
    await hub!.invoke(
      'SendOffer',
      args: [
        {'callSessionId': callSessionId, 'type': offer.type, 'sdp': offer.sdp},
      ],
    );
  }

  Future<void> _handleOffer(Map<Object?, Object?> map) async {
    await peerConnection!.setRemoteDescription(
      RTCSessionDescription(
        _stringValue(map, 'sdp'),
        _stringValue(map, 'type'),
      ),
    );
    final answer = await peerConnection!.createAnswer({
      'offerToReceiveAudio': 1,
    });
    await peerConnection!.setLocalDescription(answer);
    await hub!.invoke(
      'SendAnswer',
      args: [
        {
          'callSessionId': callSessionId,
          'type': answer.type,
          'sdp': answer.sdp,
        },
      ],
    );
    _setStatus('live');
  }

  Future<void> _startAudioStream(String userId) async {
    final stream = await recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: _sampleRate,
        numChannels: _channels,
        echoCancel: true,
        noiseSuppress: true,
        streamBufferSize: 4096,
      ),
    );

    audioSubscription = stream.listen((bytes) {
      audioBuffer.add(bytes);
      final targetSize =
          (_sampleRate *
                  _channels *
                  _bytesPerSample *
                  _chunkMilliseconds /
                  1000)
              .round();
      while (audioBuffer.length >= targetSize) {
        final allBytes = audioBuffer.takeBytes();
        _sendAudioChunk(userId, Uint8List.sublistView(allBytes, 0, targetSize));
        if (allBytes.length > targetSize) {
          audioBuffer.add(Uint8List.sublistView(allBytes, targetSize));
        }
      }
    });
  }

  void _sendAudioChunk(String userId, Uint8List chunk) {
    final id = callSessionId;
    if (id == null) return;

    hub?.invoke(
      'SendAudioChunk',
      args: [
        {
          'callSessionId': id,
          'senderUserId': userId,
          'sourceLanguage': sourceLanguage,
          'targetLanguage': targetLanguage,
          'audioBase64': base64Encode(chunk),
        },
      ],
    );
  }

  Future<void> _endCall() async {
    final id = callSessionId;
    if (id != null) {
      await hub?.invoke('EndCall', args: [id]);
    }
    await _closeMedia();
    if (mounted) _setStatus('ended');
  }

  Future<void> _closeMedia() async {
    await audioSubscription?.cancel();
    audioSubscription = null;
    audioBuffer.clear();
    if (await recorder.isRecording()) {
      await recorder.stop();
    }
    localStream?.getTracks().forEach((track) => track.stop());
    remoteStream?.getTracks().forEach((track) => track.stop());
    await peerConnection?.close();
    await hub?.stop();
    audioFeedback.stopRingingBeeps();
    localStream = null;
    remoteStream = null;
    peerConnection = null;
    hub = null;
  }

  void _finishAsEnded(String nextStatus) {
    _closeMedia();
    if (mounted) _setStatus(nextStatus);
  }

  void _setStatus(String nextStatus) {
    final wasLive = status == 'live';
    setState(() => status = nextStatus);

    if (nextStatus == 'ringing') {
      unawaited(audioFeedback.startRingingBeeps());
    } else {
      audioFeedback.stopRingingBeeps();
    }

    if (!wasLive && nextStatus == 'live') {
      unawaited(audioFeedback.playConnected());
    }
  }

  bool _matchesCall(List<Object?>? args) => _isCurrentCall(_firstMap(args));

  bool _isCurrentCall(Map<Object?, Object?> map) =>
      _stringValue(map, 'callSessionId') == callSessionId;

  Map<Object?, Object?> _firstMap(List<Object?>? args) =>
      _asMap(args?.firstOrNull);

  Map<Object?, Object?> _asMap(Object? value) {
    if (value is Map) return Map<Object?, Object?>.from(value);
    return {};
  }

  String? _stringValue(Map<Object?, Object?> map, String key) {
    final value = _value(map, key);
    return value?.toString();
  }

  Object? _value(Map<Object?, Object?> map, String key) {
    final exact = map[key];
    if (exact != null) return exact;

    final pascalKey = key[0].toUpperCase() + key.substring(1);
    final pascal = map[pascalKey];
    if (pascal != null) return pascal;

    final lowerKey = key.toLowerCase();
    for (final entry in map.entries) {
      if (entry.key?.toString().toLowerCase() == lowerKey) {
        return entry.value;
      }
    }

    return null;
  }

  int? _toInt(Object? value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }
}

class _GlossPanel extends StatelessWidget {
  const _GlossPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _LanguagePicker extends StatelessWidget {
  const _LanguagePicker({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String value;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: 'bn-BD', child: Text('🇧🇩 Bangla (BD)')),
        DropdownMenuItem(value: 'en-US', child: Text('🇺🇸 English (US)')),
        DropdownMenuItem(value: 'en-GB', child: Text('🇬🇧 English (UK)')),
        DropdownMenuItem(value: 'ar-SA', child: Text('🇸🇦 Arabic (SA)')),
        DropdownMenuItem(value: 'es-ES', child: Text('🇪🇸 Spanish (ES)')),
        DropdownMenuItem(value: 'fr-FR', child: Text('🇫🇷 French (FR)')),
        DropdownMenuItem(value: 'de-DE', child: Text('🇩🇪 German (DE)')),
        DropdownMenuItem(value: 'ja-JP', child: Text('🇯🇵 Japanese (JP)')),
        DropdownMenuItem(value: 'hi-IN', child: Text('🇮🇳 Hindi (IN)')),
      ],
      onChanged: (value) {
        if (value != null) onChanged?.call(value);
      },
    );
  }
}
