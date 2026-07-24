import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:signalr_netcore/signalr_client.dart' as signalr;

import '../app_state.dart';
import '../config.dart';
import '../models.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.remoteUser});

  final AppUser remoteUser;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final textController = TextEditingController();
  final scrollController = ScrollController();
  final messages = <ChatMessage>[];
  final messageIds = <String>{};

  signalr.HubConnection? hub;
  var loading = true;
  var sending = false;
  String? error;

  @override
  void initState() {
    super.initState();
    unawaited(_connectAndLoad());
  }

  @override
  void dispose() {
    textController.dispose();
    scrollController.dispose();
    hub?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AppState>().currentUser!;

    return Scaffold(
      appBar: AppBar(title: Text(widget.remoteUser.displayName)),
      body: Column(
        children: [
          if (error != null)
            Material(
              color: Theme.of(context).colorScheme.errorContainer,
              child: ListTile(
                dense: true,
                title: Text(error!),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => error = null),
                ),
              ),
            ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                ? const Center(child: Text('No messages yet'))
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final mine = message.senderUserId == currentUser.userId;
                      return Align(
                        alignment: mine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.sizeOf(context).width * 0.78,
                          ),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: mine
                                  ? const Color(0xFF0C766F)
                                  : const Color(0xFFEFF5F6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              message.message,
                              style: TextStyle(
                                color: mine
                                    ? Colors.white
                                    : const Color(0xFF142B34),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: textController,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      decoration: const InputDecoration(
                        hintText: 'Message',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: sending ? null : _send,
                    icon: const Icon(Icons.send),
                    tooltip: 'Send',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _connectAndLoad() async {
    try {
      final token = context.read<AppState>().currentUser!.token;
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

      connection.on('ChatMessageReceived', (args) {
        final message = _messageFromArgs(args);
        if (message == null || !_belongsToConversation(message)) return;
        _addMessage(message);
      });

      hub = connection;
      await connection.start();

      final result = await connection.invoke(
        'GetChatHistory',
        args: [widget.remoteUser.id],
      );
      final loaded = _messagesFromResult(result);
      if (!mounted) return;
      setState(() {
        messages
          ..clear()
          ..addAll(loaded);
        messageIds
          ..clear()
          ..addAll(loaded.map((x) => x.id));
        loading = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = _friendlyError(e);
        loading = false;
      });
    }
  }

  Future<void> _send() async {
    final text = textController.text.trim();
    if (text.isEmpty || hub == null) return;

    setState(() => sending = true);
    try {
      textController.clear();
      final result = await hub!.invoke(
        'SendChatMessage',
        args: [
          {'recipientUserId': widget.remoteUser.id, 'message': text},
        ],
      );
      final message = _messageFromValue(result);
      if (message != null) _addMessage(message);
    } catch (e) {
      if (mounted) setState(() => error = _friendlyError(e));
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  void _addMessage(ChatMessage message) {
    if (!messageIds.add(message.id)) {
      return;
    }
    if (!mounted) return;
    setState(() {
      messages.add(message);
      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    });
    _scrollToBottom();
  }

  bool _belongsToConversation(ChatMessage message) {
    final currentUserId = context.read<AppState>().currentUser!.userId;
    final remoteUserId = widget.remoteUser.id;
    return (message.senderUserId == currentUserId &&
            message.recipientUserId == remoteUserId) ||
        (message.senderUserId == remoteUserId &&
            message.recipientUserId == currentUserId);
  }

  ChatMessage? _messageFromArgs(List<Object?>? args) =>
      _messageFromValue(args?.firstOrNull);

  ChatMessage? _messageFromValue(Object? value) {
    if (value is Map) {
      return ChatMessage.fromMap(Map<Object?, Object?>.from(value));
    }
    return null;
  }

  List<ChatMessage> _messagesFromResult(Object? value) {
    if (value is! Iterable) {
      return [];
    }
    return value
        .whereType<Map>()
        .map((x) => ChatMessage.fromMap(Map<Object?, Object?>.from(x)))
        .where(_belongsToConversation)
        .toList();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  String _friendlyError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    return message.isEmpty ? 'Chat failed.' : message;
  }
}
