import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SpaceDetailsScreen extends StatelessWidget {
  final Function(String route)? onNavigate;

  const SpaceDetailsScreen({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.signalBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.signalTextPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Design Team',
              style: TextStyle(color: AppTheme.signalTextPrimary, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Space',
              style: TextStyle(color: AppTheme.signalTextSecondary, fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined, color: AppTheme.signalTextPrimary),
            onPressed: () => _showJoinSpaceModal(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              // Space Glowing Core Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppTheme.purpleGradient,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.cosmicAccentPurple.withOpacity(0.4),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.hub, color: Colors.white, size: 32),
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _MemberAvatar(color: Colors.pinkAccent),
                        _MemberAvatar(color: Colors.purpleAccent),
                        _MemberAvatar(color: Colors.blueAccent),
                        _MemberAvatar(color: Colors.tealAccent),
                        SizedBox(width: 8),
                        Text(
                          '28 Members • 6 Online',
                          style: TextStyle(color: AppTheme.signalTextSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Feature Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.0,
                children: [
                  _buildFeatureCard(
                    icon: Icons.chat_bubble_outline,
                    title: 'Chat',
                    subtext: '',
                    color: const Color(0xFF6366F1),
                    onTap: () => onNavigate?.call('signal'),
                  ),
                  _buildFeatureCard(
                    icon: Icons.graphic_eq,
                    title: 'Voice Room',
                    subtext: '8 in room',
                    color: const Color(0xFF10B981),
                    onTap: () => onNavigate?.call('voice_room'),
                  ),
                  _buildFeatureCard(
                    icon: Icons.videocam_outlined,
                    title: 'Video Room',
                    subtext: 'Join now',
                    color: const Color(0xFF6366F1),
                    onTap: () => onNavigate?.call('video_room'),
                  ),
                  _buildFeatureCard(
                    icon: Icons.folder_open_outlined,
                    title: 'Files & Media',
                    subtext: '',
                    color: const Color(0xFFF59E0B),
                    onTap: () {},
                  ),
                  _buildFeatureCard(
                    icon: Icons.assignment_outlined,
                    title: 'Tasks',
                    subtext: '',
                    color: const Color(0xFFEC4899),
                    onTap: () {},
                  ),
                  _buildFeatureCard(
                    icon: Icons.calendar_today_outlined,
                    title: 'Events',
                    subtext: '',
                    color: const Color(0xFFEF4444),
                    onTap: () {},
                  ),
                  _buildFeatureCard(
                    icon: Icons.people_outline,
                    title: 'Members',
                    subtext: '',
                    color: const Color(0xFF6366F1),
                    onTap: () {},
                  ),
                  _buildFeatureCard(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    subtext: '',
                    color: const Color(0xFF64748B),
                    onTap: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtext,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(color: AppTheme.signalTextPrimary, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            if (subtext.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                subtext,
                style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showJoinSpaceModal(BuildContext context) {
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Join a Space', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Text('Choose a way to join', style: TextStyle(color: Colors.black45, fontSize: 12)),
              const SizedBox(height: 16),
              _buildJoinOptionTile(Icons.format_list_bulleted, 'Enter Space Code', 'Enter 6-8 digit code', const Color(0xFF6366F1)),
              _buildJoinOptionTile(Icons.qr_code_scanner, 'Scan QR Code', 'Scan and join instantly', const Color(0xFF8B5CF6)),
              _buildJoinOptionTile(Icons.graphic_eq, 'Join Nearby Spaces', 'Find spaces near you', const Color(0xFF6366F1)),
              _buildJoinOptionTile(Icons.link, 'Join with Invite Link', 'Open a link to join', const Color(0xFF3B82F6)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildJoinOptionTile(IconData icon, String title, String subtitle, Color color) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.black45)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black26),
      onTap: () {},
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  final Color color;

  const _MemberAvatar({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 2),
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
    );
  }
}
