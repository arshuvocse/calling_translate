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
  const CallScreen.outgoing({
    super.key,
    required this.remoteUser,
    this.isVideo = false,
  })  : incomingCallSessionId = null,
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
    this.isVideo = false,
  });

  final AppUser remoteUser;
  final String? incomingCallSessionId;
  final String? incomingCallerName;
  final String? incomingSourceLanguage;
  final String? incomingTargetLanguage;
  final bool isVideo;

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
  final localRenderer = RTCVideoRenderer();
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

  bool isMuted = false;
  bool isCameraOn = true;
  bool isFrontCamera = true;

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
    _initRenderers();
    if (widget.isIncoming) {
      status = 'incoming';
    }
  }

  Future<void> _initRenderers() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
  }

  @override
  void dispose() {
    _closeMedia();
    audioFeedback.dispose();
    localRenderer.dispose();
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
        title: Row(
          children: [
            Icon(
              widget.isVideo ? Icons.videocam : Icons.phone,
              size: 20,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Background / Fullscreen Video for Video Call
          if (widget.isVideo && status == 'live' && remoteStream != null)
            Positioned.fill(
              child: RTCVideoView(
                remoteRenderer,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              ),
            )
          else
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF123A5C),
                    Color(0xFF0A7C86),
                    Color(0xFFF4F8FB),
                  ],
                  stops: [0, 0.48, 1],
                ),
              ),
            ),

          // Main Call Overlay & Content
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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
                                      colors: [
                                        Color(0xFF13B7A8),
                                        Color(0xFF276EF1),
                                      ],
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
                                    widget.isVideo
                                        ? 'Live Translated Video Call'
                                        : 'Live Translated Audio Call',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.isVideo
                                  ? 'WebRTC streams video & audio. SignalR handles signaling and live speech translation.'
                                  : 'WebRTC carries call audio. SignalR handles signaling and translated AI audio.',
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
                          width: 160,
                          height: 160,
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
                                _live
                                    ? (widget.isVideo
                                        ? Icons.videocam
                                        : Icons.graphic_eq)
                                    : Icons.call,
                                size: 56,
                                color: _live
                                    ? const Color(0xFF008D7F)
                                    : const Color(0xFF506272),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                status.toUpperCase(),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
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
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              constraints: const BoxConstraints(minHeight: 70),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7FBFC),
                                border: Border.all(
                                  color: const Color(0xFFDDE9EC),
                                ),
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
                    ],
                  ),
                ),

                // Local Camera Floating Preview Tile (PIP) for Video Calls
                if (widget.isVideo && localStream != null && isCameraOn)
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      width: 110,
                      height: 150,
                      margin: const EdgeInsets.only(right: 16, bottom: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 10),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: RTCVideoView(
                          localRenderer,
                          mirror: isFrontCamera,
                          objectFit:
                              RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                        ),
                      ),
                    ),
                  ),

                // Bottom Call Controls Bar
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Mute Microphone Button
                      if (_live)
                        IconButton.filled(
                          onPressed: _toggleMute,
                          icon: Icon(isMuted ? Icons.mic_off : Icons.mic),
                          style: IconButton.styleFrom(
                            backgroundColor: isMuted
                                ? Colors.redAccent
                                : Colors.white24,
                            foregroundColor: Colors.white,
                          ),
                        ),

                      // Video Camera On/Off Toggle
                      if (_live && widget.isVideo)
                        IconButton.filled(
                          onPressed: _toggleCamera,
                          icon: Icon(
                            isCameraOn ? Icons.videocam : Icons.videocam_off,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: isCameraOn
                                ? Colors.white24
                                : Colors.redAccent,
                            foregroundColor: Colors.white,
                          ),
                        ),

                      // Switch Camera Front/Rear Toggle
                      if (_live && widget.isVideo)
                        IconButton.filled(
                          onPressed: _switchCamera,
                          icon: const Icon(Icons.cameraswitch),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white24,
                            foregroundColor: Colors.white,
                          ),
                        ),

                      // Call Main Action Button (Start / Accept / End)
                      if (widget.isIncoming && status == 'incoming') ...[
                        FloatingActionButton.extended(
                          heroTag: 'acceptCall',
                          onPressed: () => _runCallAction(_acceptIncomingCall),
                          icon: const Icon(Icons.call),
                          label: const Text('Accept'),
                          backgroundColor: const Color(0xFF0C766F),
                        ),
                        FloatingActionButton.extended(
                          heroTag: 'rejectCall',
                          onPressed: () => _runCallAction(_rejectIncomingCall),
                          icon: const Icon(Icons.call_end),
                          label: const Text('Reject'),
                          backgroundColor: Colors.redAccent,
                        ),
                      ] else ...[
                        FloatingActionButton(
                          heroTag: 'callAction',
                          onPressed: _live
                              ? () => _runCallAction(_endCall)
                              : () => _runCallAction(_startOutgoingCall),
                          backgroundColor: _live
                              ? const Color(0xFFE94747)
                              : const Color(0xFF0C766F),
                          child: Icon(_live ? Icons.call_end : Icons.call),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
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

    if (widget.isVideo) {
      final cam = await Permission.camera.request();
      if (!cam.isGranted) throw Exception('Camera permission is required.');
    }

    final mediaConstraints = {
      'audio': {'echoCancellation': true, 'noiseSuppression': true},
      'video': widget.isVideo
          ? {
              'facingMode': isFrontCamera ? 'user' : 'environment',
              'mandatory': {
                'minWidth': '640',
                'minHeight': '480',
                'minFrameRate': '30',
              },
            }
          : false,
    };

    localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    if (widget.isVideo) {
      localRenderer.srcObject = localStream;
    }

    final peer = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
        {'urls': 'stun:stun2.l.google.com:19302'},
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

    peer.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        remoteStream = event.streams[0];
        remoteRenderer.srcObject = remoteStream;
        if (mounted) setState(() {});
      }
    };

    for (final track in localStream!.getTracks()) {
      await peer.addTrack(track, localStream!);
    }

    peerConnection = peer;
  }

  Future<void> _sendOffer() async {
    final offerConstraints = {
      'offerToReceiveAudio': 1,
      'offerToReceiveVideo': widget.isVideo ? 1 : 0,
    };
    final offer = await peerConnection!.createOffer(offerConstraints);
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
    final answerConstraints = {
      'offerToReceiveAudio': 1,
      'offerToReceiveVideo': widget.isVideo ? 1 : 0,
    };
    final answer = await peerConnection!.createAnswer(answerConstraints);
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
    try {
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
          _sendAudioChunk(
            userId,
            Uint8List.sublistView(allBytes, 0, targetSize),
          );
          if (allBytes.length > targetSize) {
            audioBuffer.add(Uint8List.sublistView(allBytes, targetSize));
          }
        }
      });
    } catch (e) {
      debugPrint('Audio translation recorder stream notice: $e');
    }
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

  void _toggleMute() {
    if (localStream == null) return;
    final newMuteState = !isMuted;
    for (final track in localStream!.getAudioTracks()) {
      track.enabled = !newMuteState;
    }
    setState(() => isMuted = newMuteState);
  }

  void _toggleCamera() {
    if (localStream == null || !widget.isVideo) return;
    final newCamState = !isCameraOn;
    for (final track in localStream!.getVideoTracks()) {
      track.enabled = newCamState;
    }
    setState(() => isCameraOn = newCamState);
  }

  Future<void> _switchCamera() async {
    if (localStream == null || !widget.isVideo) return;
    final videoTracks = localStream!.getVideoTracks();
    if (videoTracks.isNotEmpty) {
      await Helper.switchCamera(videoTracks.first);
      setState(() => isFrontCamera = !isFrontCamera);
    }
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
    try {
      if (await recorder.isRecording()) {
        await recorder.stop();
      }
    } catch (_) {}
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
