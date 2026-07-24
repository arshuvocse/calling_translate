import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class VoiceRoomScreen extends StatefulWidget {
  final String roomName;

  const VoiceRoomScreen({super.key, this.roomName = 'Design Team'});

  @override
  State<VoiceRoomScreen> createState() => _VoiceRoomScreenState();
}

class _VoiceRoomScreenState extends State<VoiceRoomScreen> {
  bool _isMuted = false;
  bool _isSpeaker = true;
  bool _handRaised = false;

  final List<Map<String, dynamic>> _participants = const [
    {'name': 'Babu', 'role': 'Host', 'isSpeaking': true, 'color': Colors.purpleAccent},
    {'name': 'Nusrat', 'role': '', 'isSpeaking': false, 'color': Colors.pinkAccent},
    {'name': 'Rasel', 'role': '', 'isSpeaking': true, 'color': Colors.tealAccent},
    {'name': 'Ariyan', 'role': '', 'isSpeaking': false, 'color': Colors.blueAccent},
    {'name': 'Nadia', 'role': '', 'isSpeaking': false, 'color': Colors.amberAccent},
    {'name': '+3', 'role': '', 'isSpeaking': false, 'color': Colors.grey},
  ];

  @override
  Widget build(BuildContext context) {
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
            Text(
              'Voice Room',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.roomName,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.phone, color: Colors.white70)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.videocam, color: Colors.white70)),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Session Stats Header
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.cosmicCardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.cosmicCardBorder),
                  ),
                  child: const Row(
                    children: [
                      Text(
                        '25:48',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      SizedBox(width: 12),
                      Icon(Icons.people_alt, color: AppTheme.onlineGreen, size: 16),
                      SizedBox(width: 4),
                      Text(
                        '8 in room',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Spacer(),

            // Circular Speaker Grid
            SizedBox(
              width: 320,
              height: 320,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Center Waveform Circle
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.onlineGreen.withOpacity(0.2),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.onlineGreen.withOpacity(0.5),
                          blurRadius: 30,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.graphic_eq, color: AppTheme.onlineGreen, size: 44),
                  ),

                  // Speaker Nodes in Radial Orbit
                  Positioned(top: 10, left: 130, child: _buildSpeakerNode(_participants[0])),
                  Positioned(top: 60, right: 30, child: _buildSpeakerNode(_participants[1])),
                  Positioned(bottom: 70, right: 30, child: _buildSpeakerNode(_participants[2])),
                  Positioned(bottom: 10, left: 130, child: _buildSpeakerNode(_participants[3])),
                  Positioned(bottom: 70, left: 30, child: _buildSpeakerNode(_participants[4])),
                  Positioned(top: 60, left: 30, child: _buildSpeakerNode(_participants[5])),
                ],
              ),
            ),

            const Spacer(),

            // Bottom Control Toolbar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                    icon: _isSpeaker ? Icons.volume_up : Icons.volume_off,
                    label: 'Speaker',
                    isActive: _isSpeaker,
                    onTap: () => setState(() => _isSpeaker = !_isSpeaker),
                  ),
                  _buildControlBtn(
                    icon: _isMuted ? Icons.mic_off : Icons.mic,
                    label: 'Mic',
                    isActive: !_isMuted,
                    onTap: () => setState(() => _isMuted = !_isMuted),
                  ),
                  // Center Waveform Trigger
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.onlineGreen,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.onlineGreen,
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.graphic_eq, color: Colors.white, size: 28),
                    ),
                  ),
                  _buildControlBtn(
                    icon: Icons.back_hand_outlined,
                    label: 'Raise Hand',
                    isActive: _handRaised,
                    onTap: () => setState(() => _handRaised = !_handRaised),
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

            // Slide Up Handle
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.keyboard_arrow_up, color: Colors.white54, size: 16),
                SizedBox(width: 4),
                Text('Slide up for options', style: TextStyle(color: Colors.white54, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeakerNode(Map<String, dynamic> speaker) {
    final isSpeaking = speaker['isSpeaking'] == true;
    final color = speaker['color'] as Color;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            if (isSpeaking)
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.onlineGreen, width: 2.5),
                  boxShadow: [
                    BoxShadow(color: AppTheme.onlineGreen.withOpacity(0.5), blurRadius: 12),
                  ],
                ),
              ),
            CircleAvatar(
              radius: 22,
              backgroundColor: color,
              child: Text(
                speaker['name'][0],
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          speaker['name'],
          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
        ),
        if (speaker['role'].isNotEmpty)
          Text(
            speaker['role'],
            style: const TextStyle(color: AppTheme.onlineGreen, fontSize: 9, fontWeight: FontWeight.bold),
          ),
      ],
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
          Icon(icon, color: isActive ? Colors.white : Colors.white38, size: 22),
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
