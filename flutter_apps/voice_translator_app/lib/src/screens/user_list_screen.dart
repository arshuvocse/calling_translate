import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:signalr_netcore/signalr_client.dart' as signalr;

import '../app_state.dart';
import '../config.dart';
import '../incoming_ringtone.dart';
import '../models.dart';
import 'call_screen.dart';
import 'chat_screen.dart';

import '../widgets/region_language_selector_dialog.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  signalr.HubConnection? hub;
  String? connectedToken;
  Timer? incomingPollTimer;
  final handledIncomingCallSessionIds = <String>{};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final token = context.watch<AppState>().currentUser?.token;
    if (token == null) {
      _disconnectIncomingCalls();
      return;
    }
    if (token != connectedToken) {
      _connectIncomingCalls(token);
      _startIncomingPoll(token);
    }
  }

  @override
  void dispose() {
    _disconnectIncomingCalls();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final currentUser = state.currentUser;
    final currentUserId = currentUser?.userId;
    final contacts = state.users.where((x) => x.id != currentUserId).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        actions: [
          IconButton(
            onPressed: () {
              if (currentUser == null) return;
              showDialog(
                context: context,
                builder: (context) => RegionLanguageSelectorDialog(
                  currentSourceLang: currentUser.preferredSourceLanguage,
                  currentTargetLang: currentUser.preferredTargetLanguage,
                  onSave: (source, target) {
                    state.updateLanguagesAndRegion(source, target);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Region updated: $source -> $target')),
                    );
                  },
                ),
              );
            },
            icon: const Icon(Icons.language),
            tooltip: 'Region & Language',
          ),
          IconButton(
            onPressed: () => state.loadUsers(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: state.logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: state.loadUsers,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            if (contacts.isEmpty) {
              return const ListTile(
                title: Text('No other users yet'),
                subtitle: Text('Register another account to test a call.'),
              );
            }
            final user = contacts[index];
            return _UserTile(user: user);
          },
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemCount: contacts.isEmpty ? 1 : contacts.length,
        ),
      ),
    );
  }

  Future<void> _connectIncomingCalls(String token) async {
    connectedToken = token;
    await hub?.stop();

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

    connection.on('IncomingCall', (args) {
      final map = args?.firstOrNull is Map
          ? Map<Object?, Object?>.from(args!.firstOrNull as Map)
          : <Object?, Object?>{};
      _showIncomingCall(map);
    });

    hub = connection;
    await connection.start();
  }

  void _startIncomingPoll(String token) {
    incomingPollTimer?.cancel();
    _pollIncomingCalls(token);
    incomingPollTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _pollIncomingCalls(token),
    );
  }

  Future<void> _pollIncomingCalls(String token) async {
    if (!mounted || connectedToken != token) return;
    try {
      final calls = await context.read<AppState>().api.incomingCalls(token);
      for (final call in calls) {
        if (!mounted || connectedToken != token) return;
        await _showIncomingCall(Map<Object?, Object?>.from(call));
      }
    } catch (_) {
      // SignalR remains the primary path; polling is a best-effort fallback.
    }
  }

  void _disconnectIncomingCalls() {
    incomingPollTimer?.cancel();
    incomingPollTimer = null;
    unawaited(IncomingRingtone.stop());
    hub?.stop();
    hub = null;
    connectedToken = null;
    handledIncomingCallSessionIds.clear();
  }

  Future<void> _showIncomingCall(Map<Object?, Object?> map) async {
    if (!mounted) return;
    final state = context.read<AppState>();
    final callerId = _stringValue(map, 'callerUserId');
    final callerName =
        _stringValue(map, 'callerDisplayName') ?? 'Unknown caller';
    final sessionId = _stringValue(map, 'callSessionId');
    if (callerId == null || sessionId == null) return;
    if (!handledIncomingCallSessionIds.add(sessionId)) return;

    final caller = state.users.firstWhere(
      (x) => x.id == callerId,
      orElse: () => AppUser(
        id: callerId,
        displayName: callerName,
        email: '',
        preferredSourceLanguage: _stringValue(map, 'sourceLanguage') ?? 'bn',
        preferredTargetLanguage: _stringValue(map, 'targetLanguage') ?? 'en',
      ),
    );

    await IncomingRingtone.start();
    if (!mounted) {
      await IncomingRingtone.stop();
      return;
    }

    final bool? accepted;
    try {
      accepted = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text(callerName),
          content: const Text('Incoming live translated call'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Reject'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Accept'),
            ),
          ],
        ),
      );
    } finally {
      await IncomingRingtone.stop();
    }

    if (!mounted) return;
    if (accepted == true) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CallScreen.incoming(
            remoteUser: caller,
            incomingCallSessionId: sessionId,
            incomingCallerName: callerName,
            incomingSourceLanguage:
                _stringValue(map, 'sourceLanguage') ??
                caller.preferredSourceLanguage,
            incomingTargetLanguage:
                _stringValue(map, 'targetLanguage') ??
                caller.preferredTargetLanguage,
          ),
        ),
      );
    } else {
      await hub?.invoke('RejectCall', args: [sessionId]);
    }
  }

  String? _stringValue(Map<Object?, Object?> map, String key) {
    final exact = map[key];
    if (exact != null) return exact.toString();

    final pascalKey = key[0].toUpperCase() + key.substring(1);
    final pascal = map[pascalKey];
    if (pascal != null) return pascal.toString();

    final lowerKey = key.toLowerCase();
    for (final entry in map.entries) {
      if (entry.key?.toString().toLowerCase() == lowerKey) {
        return entry.value?.toString();
      }
    }

    return null;
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(
          user.displayName.isEmpty ? '?' : user.displayName[0].toUpperCase(),
        ),
      ),
      title: Text(user.displayName),
      subtitle: Text(
        '${user.email}  ${user.preferredSourceLanguage} -> ${user.preferredTargetLanguage}',
      ),
      trailing: Wrap(
        spacing: 4,
        children: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: 'Chat',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ChatScreen(remoteUser: user)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.call),
            tooltip: 'Audio Call',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CallScreen.outgoing(remoteUser: user, isVideo: false),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.videocam),
            tooltip: 'Video Call',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CallScreen.outgoing(remoteUser: user, isVideo: true),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
