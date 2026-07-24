import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../theme/app_theme.dart';

class VideoRoomScreen extends StatefulWidget {
  final String roomName;

  const VideoRoomScreen({super.key, this.roomName = 'Product Discussion'});

  @override
  State<VideoRoomScreen> createState() => _VideoRoomScreenState();
}

class _VideoRoomScreenState extends State<VideoRoomScreen> {
  bool _isCameraOn = true;
  bool _isMuted = false;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final currentUserName = appState.currentUser?.displayName ?? 'Me';

    final List<Map<String, dynamic>> participants = [
      {'name': '$currentUserName (Me)', 'color': Colors.indigo},
      {'name': 'Nusrat', 'color': Colors.pinkAccent},
      {'name': 'Rasel', 'color': Colors.teal},
      {'name': 'Mim', 'color': Colors.orangeAccent},
      {'name': 'Ariyan', 'color': Colors.purpleAccent},
      {'name': 'Jannat', 'color': Colors.deepPurple},
      {'name': 'Sabbir', 'color': Colors.blueAccent},
      {'name': 'Nadia', 'color': Colors.amberAccent},
      {'name': '+4', 'color': Colors.grey},
    ];

    return Scaffold(
      backgroundColor: AppTheme.cosmicBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          children: [
            const Text(
              'Video Room',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.roomName,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              const Text('12:45', style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.liveRed,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'LIVE',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.people_alt_outlined, color: Colors.white70, size: 16),
              const SizedBox(width: 4),
              const Text('12', style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(width: 16),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Video Grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: participants.length,
                  itemBuilder: (context, index) {
                    final item = participants[index];
                    return _buildVideoTile(item);
                  },
                ),
              ),
            ),

            // Bottom Control Toolbar
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.cosmicCardBg,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppTheme.cosmicCardBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildControlBtn(
                    icon: _isCameraOn ? Icons.videocam : Icons.videocam_off,
                    label: 'Camera',
                    isActive: _isCameraOn,
                    onTap: () => setState(() => _isCameraOn = !_isCameraOn),
                  ),
                  _buildControlBtn(
                    icon: _isMuted ? Icons.mic_off : Icons.mic,
                    label: 'Mic',
                    isActive: !_isMuted,
                    onTap: () => setState(() => _isMuted = !_isMuted),
                  ),
                  // Red End Call Button
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.liveRed,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.liveRed.withValues(alpha: 0.5),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.call_end, color: Colors.white, size: 20),
                          SizedBox(width: 6),
                          Text('Leave', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  _buildControlBtn(
                    icon: Icons.screen_share_outlined,
                    label: 'Screen Share',
                    isActive: false,
                    onTap: () {},
                  ),
                  _buildControlBtn(
                    icon: Icons.more_horiz,
                    label: 'More',
                    isActive: false,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoTile(Map<String, dynamic> item) {
    final color = item['color'] as Color;
    final name = item['name'] as String;

    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cosmicCardBorder),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: color,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                name,
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlBtn({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isActive ? Colors.white : Colors.white38, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: isActive ? Colors.white70 : Colors.white38, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
