import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class OrbitalWheelWidget extends StatefulWidget {
  final Function(String nodeName)? onNodeTap;

  const OrbitalWheelWidget({super.key, this.onNodeTap});

  @override
  State<OrbitalWheelWidget> createState() => _OrbitalWheelWidgetState();
}

class _OrbitalWheelWidgetState extends State<OrbitalWheelWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  final List<OrbitalNodeData> _nodes = const [
    OrbitalNodeData(name: 'Spaces', icon: Icons.hub_outlined, angle: -math.pi / 2),
    OrbitalNodeData(name: 'Rooms', icon: Icons.videocam_outlined, angle: -math.pi / 6),
    OrbitalNodeData(name: 'Vault', icon: Icons.folder_outlined, angle: math.pi / 3),
    OrbitalNodeData(name: 'Nearby', icon: Icons.rocket_launch_outlined, angle: 2 * math.pi / 3),
    OrbitalNodeData(name: 'People', icon: Icons.person_outline, angle: 7 * math.pi / 6),
  ];

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double size = 260.0;
    const double radius = 100.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Cosmic Glow
          Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.cosmicOrbitalGlow,
            ),
          ),

          // Orbital Ring Line
          Container(
            width: radius * 2,
            height: radius * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.cosmicAccentPurple.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
          ),

          // Rotating Nodes
          AnimatedBuilder(
            animation: _rotationController,
            builder: (context, child) {
              final double currentRotation = _rotationController.value * 2 * math.pi;
              return Stack(
                alignment: Alignment.center,
                children: _nodes.map((node) {
                  final double angle = node.angle + currentRotation;
                  final double x = radius * math.cos(angle);
                  final double y = radius * math.sin(angle);

                  return Transform.translate(
                    offset: Offset(x, y),
                    child: _buildOrbitalNode(node),
                  );
                }).toList(),
              );
            },
          ),

          // Center Core Node (Signal)
          GestureDetector(
            onTap: () => widget.onNodeTap?.call('Signal'),
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.purpleGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.cosmicAccentPurple.withValues(alpha: 0.6),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.chat_bubble_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrbitalNode(OrbitalNodeData node) {
    return GestureDetector(
      onTap: () => widget.onNodeTap?.call(node.name),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.cosmicCardBg,
              border: Border.all(
                color: AppTheme.cosmicAccentPurple.withValues(alpha: 0.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Icon(
              node.icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            node.name,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class OrbitalNodeData {
  final String name;
  final IconData icon;
  final double angle;

  const OrbitalNodeData({
    required this.name,
    required this.icon,
    required this.angle,
  });
}
