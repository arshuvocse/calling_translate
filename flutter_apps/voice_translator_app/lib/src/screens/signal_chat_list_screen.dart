import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme/app_theme.dart';

class SignalChatListScreen extends StatefulWidget {
  final Function(AppUser targetUser)? onSelectUser;

  const SignalChatListScreen({super.key, this.onSelectUser});

  @override
  State<SignalChatListScreen> createState() => _SignalChatListScreenState();
}

class _SignalChatListScreenState extends State<SignalChatListScreen> {
  String _selectedCategory = 'All';

  final List<Map<String, dynamic>> _mockConversations = const [
    {
      'id': '1',
      'name': 'Nusrat Jahan',
      'lastMsg': 'Typing...',
      'isTyping': true,
      'time': '9:41 AM',
      'unread': 2,
      'color': Colors.pinkAccent,
      'sourceLang': 'bn-BD',
      'targetLang': 'en-US',
    },
    {
      'id': '2',
      'name': 'Rakib Hasan',
      'lastMsg': 'Thanks for the file',
      'isTyping': false,
      'time': '9:30 AM',
      'unread': 1,
      'color': Colors.blueAccent,
      'sourceLang': 'en-US',
      'targetLang': 'bn-BD',
    },
    {
      'id': '3',
      'name': 'Ariyan Shuvo',
      'lastMsg': 'Voice message (0:18)',
      'isAudio': true,
      'time': 'Yesterday',
      'unread': 0,
      'color': Colors.purpleAccent,
      'sourceLang': 'bn-BD',
      'targetLang': 'en-US',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final currentUserId = appState.currentUser?.userId;
    final liveUsers = appState.users.where((u) => u.id != currentUserId).toList();

    return Scaffold(
      backgroundColor: AppTheme.signalBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 20,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Signal',
              style: TextStyle(
                color: AppTheme.signalTextPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Personal Messages',
              style: TextStyle(
                color: AppTheme.signalTextSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => appState.loadUsers(),
            icon: const Icon(Icons.refresh, color: AppTheme.signalTextSecondary),
            tooltip: 'Refresh Users',
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.format_list_bulleted, color: AppTheme.signalTextSecondary),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const TextField(
                    decoration: InputDecoration(
                      hintText: 'Search messages or users',
                      hintStyle: TextStyle(color: Colors.black38, fontSize: 13),
                      prefixIcon: Icon(Icons.search, color: Colors.black38, size: 20),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: ['All', 'Unread', 'Family', 'Friends', 'Work'].map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _selectedCategory = cat),
                          selectedColor: const Color(0xFF6366F1),
                          backgroundColor: const Color(0xFFF1F5F9),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.signalTextSecondary,
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          side: BorderSide.none,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Message List
          Expanded(
            child: liveUsers.isNotEmpty
                ? ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: liveUsers.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, indent: 76, endIndent: 20, color: Color(0xFFF1F5F9)),
                    itemBuilder: (context, index) {
                      final user = liveUsers[index];
                      final colors = [
                        Colors.pinkAccent,
                        Colors.blueAccent,
                        Colors.purpleAccent,
                        Colors.teal,
                        Colors.indigo,
                        Colors.orangeAccent,
                      ];
                      final color = colors[index % colors.length];

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        leading: Stack(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: color,
                              child: Text(
                                user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: AppTheme.onlineGreen,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                              ),
                            ),
                          ],
                        ),
                        title: Text(
                          user.displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppTheme.signalTextPrimary,
                          ),
                        ),
                        subtitle: Text(
                          '${user.email} • ${user.preferredSourceLanguage} ➔ ${user.preferredTargetLanguage}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.signalTextSecondary,
                            fontSize: 12,
                          ),
                        ),
                        trailing: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Online',
                              style: TextStyle(color: AppTheme.onlineGreen, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 4),
                            Icon(Icons.chat_bubble_outline, color: Color(0xFF6366F1), size: 18),
                          ],
                        ),
                        onTap: () {
                          widget.onSelectUser?.call(user);
                        },
                      );
                    },
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _mockConversations.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, indent: 76, endIndent: 20, color: Color(0xFFF1F5F9)),
                    itemBuilder: (context, index) {
                      final item = _mockConversations[index];

                      final user = AppUser(
                        id: item['id'],
                        displayName: item['name'],
                        email: '${item['name'].toString().toLowerCase().replaceAll(' ', '')}@example.com',
                        preferredSourceLanguage: item['sourceLang'] ?? 'bn-BD',
                        preferredTargetLanguage: item['targetLang'] ?? 'en-US',
                      );

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        leading: Stack(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: item['color'],
                              child: Text(
                                user.displayName[0],
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: AppTheme.onlineGreen,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                              ),
                            ),
                          ],
                        ),
                        title: Text(
                          user.displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppTheme.signalTextPrimary,
                          ),
                        ),
                        subtitle: Row(
                          children: [
                            if (item['isAudio'] == true) ...[
                              const Icon(Icons.graphic_eq, color: Color(0xFF6366F1), size: 16),
                              const SizedBox(width: 4),
                            ],
                            Expanded(
                              child: Text(
                                item['lastMsg'],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: item['isTyping'] == true
                                      ? const Color(0xFF6366F1)
                                      : AppTheme.signalTextSecondary,
                                  fontWeight: item['unread'] > 0 ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              item['time'],
                              style: const TextStyle(color: AppTheme.signalTextSecondary, fontSize: 11),
                            ),
                            if (item['unread'] > 0) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF6366F1),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${item['unread']}',
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                        onTap: () {
                          widget.onSelectUser?.call(user);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
