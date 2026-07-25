import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:signalr_netcore/signalr_client.dart' as signalr;

import '../app_state.dart';
import '../config.dart';
import '../models.dart';
import '../theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.remoteUser, this.onStartCall});

  final AppUser remoteUser;
  final Function(AppUser remoteUser, bool isVideo)? onStartCall;

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
      backgroundColor: AppTheme.signalBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.signalTextPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.purpleAccent,
              child: Text(
                widget.remoteUser.displayName[0],
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.remoteUser.displayName,
                  style: const TextStyle(
                    color: AppTheme.signalTextPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Online',
                  style: TextStyle(color: AppTheme.onlineGreen, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_outlined, color: AppTheme.signalTextPrimary),
            onPressed: () => widget.onStartCall?.call(widget.remoteUser, false),
          ),
          IconButton(
            icon: const Icon(Icons.videocam_outlined, color: AppTheme.signalTextPrimary),
            onPressed: () => widget.onStartCall?.call(widget.remoteUser, true),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppTheme.signalTextPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Encrypted Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            color: const Color(0xFFEEF2FF),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 12, color: Color(0xFF6366F1)),
                SizedBox(width: 4),
                Text(
                  'Messages are end-to-end encrypted',
                  style: TextStyle(color: Color(0xFF6366F1), fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

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

          // Message List
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final mine = message.senderUserId == currentUser.userId;
                          return _buildMessageBubble(message, mine);
                        },
                      ),
          ),

          // Input Bar
          SafeArea(
            top: false,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Color(0xFF6366F1), size: 28),
                    onPressed: _showAttachmentDrawer,
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: textController,
                        minLines: 1,
                        maxLines: 4,
                        style: const TextStyle(fontSize: 14, color: AppTheme.signalTextPrimary),
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(color: Colors.black38, fontSize: 13),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.sentiment_satisfied_alt, color: AppTheme.signalTextSecondary),
                    onPressed: () {},
                  ),
                  GestureDetector(
                    onTap: sending ? null : _send,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppTheme.purpleGradient,
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.chat_bubble_outline, color: Color(0xFF6366F1), size: 32),
          ),
          const SizedBox(height: 12),
          const Text('Say Hello to Babu! 👋', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          const Text('Start typing or initiate a real-time translated call.', style: TextStyle(color: Colors.black45, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool mine) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: mine ? AppTheme.purpleGradient : null,
            color: mine ? null : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: mine ? const Radius.circular(16) : Radius.zero,
              bottomRight: mine ? Radius.zero : const Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.message,
                style: TextStyle(
                  color: mine ? Colors.white : AppTheme.signalTextPrimary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '9:42 AM',
                    style: TextStyle(
                      color: mine ? Colors.white70 : AppTheme.signalTextSecondary,
                      fontSize: 10,
                    ),
                  ),
                  if (mine) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.done_all, color: Colors.white70, size: 14),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAttachmentDrawer() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                mainAxisSpacing: 16,
                crossAxisSpacing: 12,
                childAspectRatio: 0.80,
                children: [
                  _buildDrawerItem(Icons.image_outlined, 'Photo', const Color(0xFF10B981)),
                  _buildDrawerItem(Icons.videocam_outlined, 'Video', const Color(0xFFEF4444)),
                  _buildDrawerItem(Icons.graphic_eq, 'Audio', const Color(0xFF8B5CF6)),
                  _buildDrawerItem(Icons.insert_drive_file_outlined, 'File', const Color(0xFF3B82F6)),
                  _buildDrawerItem(Icons.person_outline, 'Contact', const Color(0xFF6366F1)),
                  _buildDrawerItem(Icons.location_on_outlined, 'Location', const Color(0xFF10B981)),
                  _buildDrawerItem(Icons.navigation_outlined, 'Live Location', const Color(0xFFF59E0B)),
                  _buildDrawerItem(Icons.poll_outlined, 'Poll', const Color(0xFF3B82F6)),
                  _buildDrawerItem(Icons.calendar_today_outlined, 'Event', const Color(0xFFEC4899)),
                  _buildDrawerItem(Icons.mic_outlined, 'Voice Message', const Color(0xFF8B5CF6), isNew: true),
                  _buildDrawerItem(Icons.record_voice_over_outlined, 'Voice Changer', const Color(0xFF6366F1), isNew: true),
                  _buildDrawerItem(Icons.auto_awesome_outlined, 'AI Assistant', const Color(0xFF7F32FF), isNew: true),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDrawerItem(IconData icon, String label, Color color, {bool isNew = false}) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppTheme.signalTextPrimary),
            ),
          ],
        ),
        if (isNew)
          Positioned(
            top: 0,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(color: const Color(0xFF6366F1), borderRadius: BorderRadius.circular(6)),
              child: const Text('New', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
            ),
          ),
      ],
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
    if (!messageIds.add(message.id)) return;
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
    return (message.senderUserId == currentUserId && message.recipientUserId == remoteUserId) ||
        (message.senderUserId == remoteUserId && message.recipientUserId == currentUserId);
  }

  ChatMessage? _messageFromArgs(List<Object?>? args) => _messageFromValue(args?.firstOrNull);

  ChatMessage? _messageFromValue(Object? value) {
    if (value is Map) {
      return ChatMessage.fromMap(Map<Object?, Object?>.from(value));
    }
    return null;
  }

  List<ChatMessage> _messagesFromResult(Object? value) {
    if (value is! Iterable) return [];
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
