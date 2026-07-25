import 'package:flutter/material.dart';
import '../api_client.dart';
import '../theme/app_theme.dart';

class VideoFeedScreen extends StatefulWidget {
  const VideoFeedScreen({super.key});

  @override
  State<VideoFeedScreen> createState() => _VideoFeedScreenState();
}

class _VideoFeedScreenState extends State<VideoFeedScreen> with SingleTickerProviderStateMixin {
  late TabController _mainTabController;
  int _subCategoryIndex = 0;
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = false;

  final List<String> _subCategories = ['For You', 'Following', 'Trending', 'Education', 'Music'];

  final List<Map<String, dynamic>> _quickVideos = [
    {
      'title': 'A day in my life #vlog #bikelife',
      'author': 'Tanzin Ahmed',
      'views': '12.5K',
      'duration': '00:28',
      'avatar': 'https://i.pravatar.cc/150?img=1',
      'thumbnail': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=600&q=80',
    },
    {
      'title': 'Bike stunt practice #bikelife',
      'author': 'Rider Hridoy',
      'views': '22.1K',
      'duration': '00:45',
      'avatar': 'https://i.pravatar.cc/150?img=2',
      'thumbnail': 'https://images.unsplash.com/photo-1558981806-ec527fa84c39?auto=format&fit=crop&w=600&q=80',
    },
    {
      'title': 'Beautiful moment in the nature 🌲',
      'author': 'Travel With Shuvo',
      'views': '18.7K',
      'duration': '00:31',
      'avatar': 'https://i.pravatar.cc/150?img=3',
      'thumbnail': 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=600&q=80',
    },
    {
      'title': 'Dance Vibes - Feel the beat! 💃',
      'author': 'Nusrat Jahan',
      'views': '9.3K',
      'duration': '00:20',
      'avatar': 'https://i.pravatar.cc/150?img=4',
      'thumbnail': 'https://images.unsplash.com/photo-1547153760-18fc86324498?auto=format&fit=crop&w=600&q=80',
    },
  ];

  final List<Map<String, dynamic>> _storyVideos = [
    {
      'title': 'Road Trip to Cox\'s Bazar | Memories for Life 🌊',
      'author': 'Travel With Shuvo',
      'views': '24K views',
      'duration': '05:12',
      'thumbnail': 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=80',
    },
    {
      'title': 'How I Shoot My Videos 🎬 Complete Behind The Scenes',
      'author': 'Creator Zone',
      'views': '18K views',
      'duration': '07:45',
      'thumbnail': 'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?auto=format&fit=crop&w=800&q=80',
    },
  ];

  final List<Map<String, dynamic>> _fullVideos = [
    {
      'title': 'Exploring the Most Beautiful Places on Earth 🌍',
      'author': 'Travel With Shuvo',
      'views': '125K views',
      'timeAgo': '2 days ago',
      'duration': '24:35',
      'thumbnail': 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?auto=format&fit=crop&w=800&q=80',
    },
    {
      'title': 'Success Mindset: Habits of Highly Successful People',
      'author': 'Life Motivation',
      'views': '98K views',
      'timeAgo': '5 days ago',
      'duration': '32:10',
      'thumbnail': 'https://images.unsplash.com/photo-1475721027785-f74eccf877e2?auto=format&fit=crop&w=800&q=80',
    },
    {
      'title': 'iPhone 15 Pro Max Full Review in Bangla',
      'author': 'Tech Master',
      'views': '78K views',
      'timeAgo': '1 week ago',
      'duration': '18:42',
      'thumbnail': 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?auto=format&fit=crop&w=800&q=80',
    },
    {
      'title': 'Street Food Tour in Old Dhaka 🍱',
      'author': 'Food Explorer',
      'views': '65K views',
      'timeAgo': '1 week ago',
      'duration': '15:20',
      'thumbnail': 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=800&q=80',
    },
  ];

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 3, vsync: this);
    _loadDynamicVideos();
  }

  Future<void> _loadDynamicVideos() async {
    setState(() => _isLoading = true);
    final fetched = await _apiClient.fetchVideos();
    if (fetched.isNotEmpty) {
      setState(() {
        _quickVideos.clear();
        for (var item in fetched) {
          _quickVideos.add({
            'title': item['title'] ?? 'Video',
            'author': item['author'] ?? 'Creator',
            'views': '${item['viewsCount'] ?? 1} views',
            'duration': item['duration'] ?? '00:30',
            'avatar': item['authorAvatar'] ?? 'https://i.pravatar.cc/150?img=3',
            'thumbnail': item['thumbnailUrl'] ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=600&q=80',
          });
        }
      });
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cosmicBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.cosmicCardBg,
        elevation: 0,
        title: const Text(
          'Videos Hub',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppTheme.cosmicAccentPurple),
            onPressed: () => _showCreateVideoDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _loadDynamicVideos,
          ),
        ],
        bottom: TabBar(
          controller: _mainTabController,
          indicatorColor: AppTheme.cosmicAccentPurple,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.bolt, size: 18), text: 'Quick (Shorts)'),
            Tab(icon: Icon(Icons.menu_book_outlined, size: 18), text: 'Story (1-10m)'),
            Tab(icon: Icon(Icons.ondemand_video, size: 18), text: 'Full Video'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Subcategory Filter Pills
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _subCategories.length,
              itemBuilder: (context, index) {
                final isSelected = _subCategoryIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_subCategories[index]),
                    selected: isSelected,
                    selectedColor: AppTheme.cosmicAccentPurple,
                    backgroundColor: AppTheme.cosmicCardBg,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.white60,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? AppTheme.cosmicAccentPurple : AppTheme.cosmicCardBorder,
                      ),
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _subCategoryIndex = index);
                      }
                    },
                  ),
                );
              },
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _mainTabController,
              children: [
                _buildQuickGrid(),
                _buildStoryList(),
                _buildFullVideoList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Quick Videos Grid (TikTok / Reels style grid)
  Widget _buildQuickGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _quickVideos.length,
      itemBuilder: (context, index) {
        final video = _quickVideos[index];
        return GestureDetector(
          onTap: () => _openVideoPlayer(context, video),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: DecorationImage(
                image: NetworkImage(video['thumbnail']),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                // Dark Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [Colors.black.withOpacity(0.1), Colors.black.withOpacity(0.8)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                // Duration Badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      video['duration'],
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                // Bottom Metadata
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        video['title'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 9,
                            backgroundImage: NetworkImage(video['avatar']),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              video['author'],
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white70, fontSize: 10),
                            ),
                          ),
                          const Icon(Icons.remove_red_eye, color: Colors.white60, size: 10),
                          const SizedBox(width: 2),
                          Text(
                            video['views'],
                            style: const TextStyle(color: Colors.white60, fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Story Videos (Medium Length)
  Widget _buildStoryList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _storyVideos.length,
      itemBuilder: (context, index) {
        final video = _storyVideos[index];
        return GestureDetector(
          onTap: () => _openVideoPlayer(context, video),
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: AppTheme.cosmicCardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.cosmicCardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Image.network(
                        video['thumbnail'],
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          video['duration'],
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const Positioned.fill(
                      child: Center(
                        child: CircleAvatar(
                          backgroundColor: Colors.black54,
                          child: Icon(Icons.play_arrow, color: Colors.white, size: 28),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              video['title'],
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${video['author']} • ${video['views']}',
                              style: const TextStyle(color: Colors.white54, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.more_vert, color: Colors.white54),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Full Video List (YouTube style)
  Widget _buildFullVideoList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _fullVideos.length,
      itemBuilder: (context, index) {
        final video = _fullVideos[index];
        return GestureDetector(
          onTap: () => _openVideoPlayer(context, video),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.cosmicCardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.cosmicCardBorder),
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        video['thumbnail'],
                        width: 120,
                        height: 75,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          video['duration'],
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video['title'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        video['author'],
                        style: const TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${video['views']} • ${video['timeAgo']}',
                        style: const TextStyle(color: Colors.white38, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCreateVideoDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String selectedType = 'Quick';
    String selectedCategory = 'For You';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cosmicCardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 16),
                  const Text('Create & Upload Video', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  // Video Type Selector
                  const Text('Choose Video Type:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 6),
                  Row(
                    children: ['Quick', 'Story', 'Full'].map((t) {
                      final isSelected = selectedType == t;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(t),
                          selected: isSelected,
                          selectedColor: AppTheme.cosmicAccentPurple,
                          backgroundColor: Colors.white10,
                          labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.white60),
                          onSelected: (_) => setModalState(() => selectedType = t),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  // Title Field
                  TextField(
                    controller: titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Video Title...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Description Field
                  TextField(
                    controller: descController,
                    maxLines: 2,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Description (optional)...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (titleController.text.trim().isEmpty) return;
                        Navigator.pop(ctx);
                        final success = await _apiClient.createVideo(
                          title: titleController.text.trim(),
                          description: descController.text.trim(),
                          videoType: selectedType,
                          category: selectedCategory,
                        );
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Video published dynamically to API!')),
                          );
                          _loadDynamicVideos();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.cosmicAccentPurple,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Publish Video', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _openVideoPlayer(BuildContext context, Map<String, dynamic> video) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(video: video),
      ),
    );
  }
}

// Video Player & Details Screen
class VideoPlayerScreen extends StatelessWidget {
  final Map<String, dynamic> video;

  const VideoPlayerScreen({super.key, required this.video});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cosmicBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Video Player Mockup Box
            Container(
              height: 220,
              width: double.infinity,
              color: Colors.black,
              child: Stack(
                children: [
                  Image.network(
                    video['thumbnail'] ?? '',
                    width: double.infinity,
                    height: 220,
                    fit: BoxFit.cover,
                  ),
                  Container(color: Colors.black38),
                  const Center(
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.black54,
                      child: Icon(Icons.play_arrow, color: Colors.white, size: 36),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const Positioned(
                    bottom: 10,
                    left: 16,
                    right: 16,
                    child: Row(
                      children: [
                        Text('05:30', style: TextStyle(color: Colors.white, fontSize: 11)),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: LinearProgressIndicator(
                              value: 0.25,
                              color: AppTheme.cosmicAccentPurple,
                              backgroundColor: Colors.white24,
                            ),
                          ),
                        ),
                        Text('24:35', style: TextStyle(color: Colors.white, fontSize: 11)),
                        SizedBox(width: 8),
                        Icon(Icons.fullscreen, color: Colors.white, size: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Video Meta & Actions
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video['title'] ?? 'Video Title',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${video['views'] ?? '125K views'} • 2 days ago • #travel #nature',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    const SizedBox(height: 16),

                    // Author Channel Row
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: NetworkImage(video['avatar'] ?? 'https://i.pravatar.cc/150?img=3'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                video['author'] ?? 'Creator Name',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const Text(
                                '125K Followers',
                                style: TextStyle(color: Colors.white38, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.cosmicAccentPurple,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: const Text('Follow', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Action Buttons (Like, Share, Save)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildActionButton(Icons.thumb_up_alt_outlined, '8.7K'),
                        _buildActionButton(Icons.share_outlined, 'Share'),
                        _buildActionButton(Icons.download_outlined, 'Download'),
                        _buildActionButton(Icons.bookmark_outline, 'Save'),
                      ],
                    ),
                    const Divider(color: Colors.white12, height: 32),

                    // Description Box
                    const Text('About this video', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    const Text(
                      'Join me as I explore the most beautiful places on earth. Nature, adventure, and peace — all in one journey.',
                      style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
      ],
    );
  }
}
