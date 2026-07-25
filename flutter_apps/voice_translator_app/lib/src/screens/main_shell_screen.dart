import 'package:flutter/material.dart';

import '../models.dart';
import '../theme/app_theme.dart';
import 'chat_screen.dart';
import 'galaxy_home_screen.dart';
import 'signal_chat_list_screen.dart';
import 'space_details_screen.dart';
import 'user_list_screen.dart';
import 'voice_room_screen.dart';
import 'video_room_screen.dart';
import 'video_feed_screen.dart';
import 'call_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDarkTab = _currentIndex == 0;

    return Scaffold(
      backgroundColor: isDarkTab ? AppTheme.cosmicBackground : AppTheme.signalBackground,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // Tab 0: Galaxy Home
          GalaxyHomeScreen(
            onNavigate: (route, {args}) => _handleNavigation(context, route, args: args),
          ),
          // Tab 1: Signal Chat List
          SignalChatListScreen(
            onSelectUser: (targetUser) => _openChat(context, targetUser),
          ),
          // Tab 2: Videos Hub
          const VideoFeedScreen(),
          // Tab 3: Orbit / Spaces
          SpaceDetailsScreen(
            onNavigate: (route) => _handleNavigation(context, route),
          ),
          // Tab 4: Profile / Users List
          const UserListScreen(),
        ],
      ),

      // Central Floating Gradient Action Button
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppTheme.purpleGradient,
          boxShadow: [
            BoxShadow(
              color: AppTheme.cosmicAccentPurple.withValues(alpha: 0.5),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: IconButton(
          icon: const Icon(Icons.add, color: Colors.white, size: 28),
          onPressed: () => _showQuickActionMenu(context),
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: BottomAppBar(
        color: isDarkTab ? AppTheme.cosmicCardBg : Colors.white,
        elevation: 10,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.auto_awesome_outlined, 'Galaxy', isDarkTab),
              _buildNavItem(1, Icons.chat_bubble_outline, 'Signal', isDarkTab),
              _buildNavItem(2, Icons.ondemand_video, 'Videos', isDarkTab),
              const SizedBox(width: 44), // Space for central FAB
              _buildNavItem(3, Icons.hub_outlined, 'Orbit', isDarkTab),
              _buildNavItem(4, Icons.person_outline, 'Profile', isDarkTab),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, bool isDarkTab) {
    final isSelected = _currentIndex == index;
    final activeColor = isDarkTab ? AppTheme.cosmicAccentPurple : const Color(0xFF6366F1);
    final inactiveColor = isDarkTab ? Colors.white38 : AppTheme.signalTextSecondary;

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : inactiveColor,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? activeColor : inactiveColor,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNavigation(BuildContext context, String route, {dynamic args}) {
    if (route == 'signal') {
      setState(() => _currentIndex = 1);
    } else if (route == 'space') {
      setState(() => _currentIndex = 2);
    } else if (route == 'voice_room') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const VoiceRoomScreen()),
      );
    } else if (route == 'video_room') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const VideoRoomScreen()),
      );
    }
  }

  void _openChat(BuildContext context, AppUser targetUser) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          remoteUser: targetUser,
          onStartCall: (remoteUser, isVideo) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CallScreen.outgoing(
                  remoteUser: remoteUser,
                  isVideo: isVideo,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showQuickActionMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cosmicCardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.chat_bubble_outline, color: Color(0xFF6366F1)),
                ),
                title: const Text('Start Direct Message', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.of(context).pop();
                  setState(() => _currentIndex = 1);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.graphic_eq, color: Color(0xFF10B981)),
                ),
                title: const Text('Create Voice Room', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.of(context).pop();
                  _handleNavigation(context, 'voice_room');
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFFD946EF).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.video_call_outlined, color: Color(0xFFD946EF)),
                ),
                title: const Text('Post / Upload Video', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.of(context).pop();
                  setState(() => _currentIndex = 2);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
