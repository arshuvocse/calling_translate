import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/orbital_wheel_widget.dart';

class GalaxyHomeScreen extends StatelessWidget {
  final Function(String route, {dynamic args})? onNavigate;

  const GalaxyHomeScreen({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final currentUserId = appState.currentUser?.userId;
    final liveUsers = appState.users.where((u) => u.id != currentUserId).toList();

    return Scaffold(
      backgroundColor: AppTheme.cosmicBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 32),
                  Column(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.auto_awesome, color: AppTheme.cosmicAccentPink, size: 18),
                          const SizedBox(width: 6),
                          const Text(
                            'CONNECT',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'One Universe. All Connections.',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.notifications_outlined, color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Central Orbital Wheel
              OrbitalWheelWidget(
                onNodeTap: (nodeName) {
                  if (nodeName == 'Signal') {
                    onNavigate?.call('signal');
                  } else if (nodeName == 'Rooms') {
                    onNavigate?.call('voice_room');
                  } else if (nodeName == 'Spaces') {
                    onNavigate?.call('space');
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Opening $nodeName...')),
                    );
                  }
                },
              ),
              const SizedBox(height: 24),

              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.cosmicCardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.cosmicCardBorder),
                ),
                child: const TextField(
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search people, spaces, or messages...',
                    hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                    prefixIcon: Icon(Icons.search, color: Colors.white38),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Quick Actions Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Edit', style: TextStyle(color: AppTheme.cosmicAccentPurple)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Quick Actions Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
                children: [
                  _buildQuickActionTile(
                    context,
                    icon: Icons.chat_bubble_outline,
                    label: 'New Message',
                    color: const Color(0xFF6366F1),
                    onTap: () => onNavigate?.call('signal'),
                  ),
                  _buildQuickActionTile(
                    context,
                    icon: Icons.graphic_eq,
                    label: 'Voice Room',
                    color: const Color(0xFF10B981),
                    onTap: () => onNavigate?.call('voice_room'),
                  ),
                  _buildQuickActionTile(
                    context,
                    icon: Icons.videocam_outlined,
                    label: 'Video Room',
                    color: const Color(0xFFF59E0B),
                    onTap: () => onNavigate?.call('video_room'),
                  ),
                  _buildQuickActionTile(
                    context,
                    icon: Icons.grid_view_rounded,
                    label: 'Create Space',
                    color: const Color(0xFF8B5CF6),
                    onTap: () => onNavigate?.call('space'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Active Now Row
              Row(
                children: [
                  const Text(
                    'Active Now',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 14),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 76,
                child: liveUsers.isNotEmpty
                    ? ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: liveUsers.length,
                        itemBuilder: (context, index) {
                          final user = liveUsers[index];
                          final colors = [
                            Colors.pinkAccent,
                            Colors.purpleAccent,
                            Colors.blueAccent,
                            Colors.tealAccent,
                            Colors.orangeAccent,
                          ];
                          return _ActiveUserAvatar(
                            name: user.displayName,
                            color: colors[index % colors.length],
                            onTap: () => onNavigate?.call('signal'),
                          );
                        },
                      )
                    : ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _ActiveUserAvatar(name: 'Nusrat', color: Colors.pinkAccent, onTap: () => onNavigate?.call('signal')),
                          _ActiveUserAvatar(name: 'Babu', color: Colors.purpleAccent, onTap: () => onNavigate?.call('signal')),
                          _ActiveUserAvatar(name: 'Rasel', color: Colors.lightBlueAccent, onTap: () => onNavigate?.call('signal')),
                          _ActiveUserAvatar(name: 'Mim', color: Colors.amberAccent, onTap: () => onNavigate?.call('signal')),
                          _ActiveUserAvatar(name: 'Ariyan', color: Colors.tealAccent, onTap: () => onNavigate?.call('signal')),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.cosmicCardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.cosmicCardBorder),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveUserAvatar extends StatelessWidget {
  final String name;
  final Color color;
  final VoidCallback onTap;

  const _ActiveUserAvatar({required this.name, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [color, color.withValues(alpha: 0.6)],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppTheme.onlineGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.cosmicBackground, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              name,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
