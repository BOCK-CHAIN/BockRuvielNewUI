import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;

import '../utils/image_picker_stub.dart'
    if (dart.library.html) '../utils/image_picker_web.dart';
import '../services/post_service.dart';
import '../widgets/tweet_card.dart';
import '../widgets/twitter/right_sidebar.dart';
import 'chat_screen.dart';

class TwitterShellScreen extends StatefulWidget {
  const TwitterShellScreen({super.key});

  @override
  State<TwitterShellScreen> createState() => _TwitterShellScreenState();
}

class _TwitterShellScreenState extends State<TwitterShellScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLargeScreen = MediaQuery.of(context).size.width > 900;

    final pages = <Widget>[
      const _TwitterHomePage(),
      const _TwitterExplorePage(),
      const _TwitterNotificationsPage(),
      const ChatScreen(),
      const _TwitterBookmarksPage(),
      const _TwitterProfilePage(),
      const _TwitterMorePage(),
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Row(
        children: [
          _buildSidebar(theme, isLargeScreen),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: pages[_selectedIndex],
                ),
              ),
            ),
          ),
          // Right Sidebar - only visible on large screens
          if (isLargeScreen)
            SizedBox(
              width: 350,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: const IntrinsicHeight(
                        child: RightSidebar(),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      floatingActionButton: isLargeScreen
          ? null
          : FloatingActionButton.extended(
              onPressed: () {},
              backgroundColor: Colors.blue,
              label: const Text('Post'),
              icon: const Icon(Icons.edit),
            ),
    );
  }

  Widget _buildSidebar(ThemeData theme, bool isLargeScreen) {
    final items = [
      _NavItemData(icon: Icons.home_outlined, label: 'Home'),
      _NavItemData(icon: Icons.search, label: 'Explore'),
      _NavItemData(icon: Icons.notifications_none_outlined, label: 'Notifications'),
      _NavItemData(icon: Icons.mail_outline, label: 'Messages'),
      _NavItemData(icon: Icons.bookmark_border, label: 'Bookmarks'),
      _NavItemData(icon: Icons.person_outline, label: 'Profile'),
      _NavItemData(icon: Icons.more_horiz, label: 'More'),
    ];

    return Container
    (
      width: isLargeScreen ? 260 : 72,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        crossAxisAlignment:
            isLargeScreen ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Back to Instagram',
                onPressed: () => Navigator.pop(context),
              ),
              if (isLargeScreen)
                const Text(
                  'X',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final selected = index == _selectedIndex;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () {
                      if (index == items.length - 1) {
                        final overlay = Overlay.of(context)?.context
                            .findRenderObject() as RenderBox?;
                        final size = overlay?.size ?? const Size(0, 0);
                        showMenu(
                          context: context,
                          position: RelativeRect.fromLTRB(
                            (isLargeScreen ? 180.0 : 72.0),
                            kToolbarHeight + 80,
                            size.width - 16,
                            0,
                          ),
                          items: const [
                            PopupMenuItem(
                              value: 'settings',
                              child: Text('Settings'),
                            ),
                            PopupMenuItem(
                              value: 'analytics',
                              child: Text('Analytics'),
                            ),
                            PopupMenuItem(
                              value: 'help',
                              child: Text('Help Center'),
                            ),
                            PopupMenuItem(
                              value: 'logout',
                              child: Text('Logout'),
                            ),
                          ],
                        );
                      } else {
                        setState(() {
                          _selectedIndex = index;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
                      decoration: selected
                          ? BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(24),
                            )
                          : null,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item.icon,
                            size: 26,
                            color: selected
                                ? theme.colorScheme.primary
                                : theme.iconTheme.color,
                          ),
                          if (isLargeScreen) ...[
                            const SizedBox(width: 16),
                            Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? theme.colorScheme.onSurface
                                    : theme.textTheme.bodyMedium?.color,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (isLargeScreen)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Post',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final String label;

  const _NavItemData({required this.icon, required this.label});
}

class _TwitterHomePage extends StatelessWidget {
  const _TwitterHomePage();

  @override
  Widget build(BuildContext context) {
    return const _TwitterHomeFeed();
  }
}

class _TwitterHomeFeed extends StatefulWidget {
  const _TwitterHomeFeed();

  @override
  State<_TwitterHomeFeed> createState() => _TwitterHomeFeedState();
}

class _TwitterHomeFeedState extends State<_TwitterHomeFeed> {
  final TextEditingController _tweetController = TextEditingController();
  File? _selectedImageFile;
  Uint8List? _selectedImageBytes;

  final List<Map<String, dynamic>> _tweets = [];

  @override
  void initState() {
    super.initState();
    _loadTweets();
  }

  Future<void> _loadTweets() async {
    final posts = await PostService.fetchPosts(postType: 'twitter');
    if (!mounted) return;
    setState(() {
      _tweets
        ..clear()
        ..addAll(posts.map((post) => {
              'id': post.id,
              'username': post.username,
              'handle': '@${post.username.toLowerCase()}',
              'time': '· 1h',
              'text': post.caption ?? '',
              'image': post.imageUrl,
              'likes': post.likesCount,
              'liked': post.isLiked,
              'likedByUser': post.isLiked,
              'comments': <Map<String, dynamic>>[],
              'commentsCount': post.commentsCount,
              'reposts': 0,
              'repostedByUser': false,
            }));
    });
  }

  Future<void> _pickImage() async {
    final result = await ImagePickerHelper.pickImage();
    if (result == null) return;

    setState(() {
      if (result['isWeb']) {
        _selectedImageBytes = result['bytes'];
        _selectedImageFile = null;
      } else {
        _selectedImageFile = result['file'];
        _selectedImageBytes = null;
      }
    });
  }

  Future<void> _addTweet() async {
    if (_tweetController.text.trim().isEmpty &&
        _selectedImageFile == null &&
        _selectedImageBytes == null) {
      return;
    }

    await PostService.createPost(
      caption: _tweetController.text.trim(),
      imageBytes: _selectedImageBytes,
      imageFile: _selectedImageFile,
      postType: 'twitter',
    );

    await _loadTweets();

    if (!mounted) return;
    setState(() {
      _tweetController.clear();
      _selectedImageFile = null;
      _selectedImageBytes = null;
    });
  }

  Future<void> _toggleLike(int index) async {
    final tweet = _tweets[index];
    final wasLiked = tweet['liked'] == true || tweet['likedByUser'] == true;
    final postId = tweet['id']?.toString();

    setState(() {
      final currentLikes = (tweet['likes'] ?? 0) as int;
      tweet['liked'] = !wasLiked;
      tweet['likedByUser'] = !wasLiked;
      tweet['likes'] = currentLikes + (wasLiked ? -1 : 1);
    });

    try {
      if (postId != null && postId.isNotEmpty) {
        await PostService.toggleLike(postId);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        final currentLikes = (tweet['likes'] ?? 0) as int;
        tweet['liked'] = wasLiked;
        tweet['likedByUser'] = wasLiked;
        tweet['likes'] = currentLikes + (wasLiked ? 1 : -1);
      });
    }
  }

  Widget _buildComposer(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage:
                    const AssetImage('assets/images/story1.jpg'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _tweetController,
                  maxLines: null,
                  decoration: const InputDecoration(
                    hintText: "What's happening?",
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_selectedImageFile != null || _selectedImageBytes != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: kIsWeb && _selectedImageBytes != null
                      ? Image.memory(
                          _selectedImageBytes!,
                          height: 180,
                          fit: BoxFit.cover,
                        )
                      : _selectedImageFile != null
                          ? Image.file(
                              _selectedImageFile!,
                              height: 180,
                              fit: BoxFit.cover,
                            )
                          : const SizedBox.shrink(),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.black54),
                  onPressed: () {
                    setState(() {
                      _selectedImageFile = null;
                      _selectedImageBytes = null;
                    });
                  },
                ),
              ],
            ),
          ),
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 8),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.image_outlined,
                  color: theme.colorScheme.primary,
                  size: 22,
                ),
                onPressed: _pickImage,
              ),
              const Spacer(),
              FilledButton(
                onPressed: _addTweet,
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Post',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            'Home',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Divider(height: 1),
        _buildComposer(context),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadTweets,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: _tweets.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final tweet = _tweets[index];
                return TweetCard(
                  key: ValueKey(tweet['id'] ?? index),
                  post: tweet,
                  onUpdate: (updated) {
                    setState(() {
                      _tweets[index] = updated;
                    });
                  },
                  onCreateQuote: (quote) {
                    setState(() {
                      _tweets.insert(0, quote);
                    });
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _TwitterExplorePage extends StatelessWidget {
  const _TwitterExplorePage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.inputDecorationTheme.fillColor ??
                    theme.colorScheme.surfaceVariant,
              ),
            ),
          ),
          const Divider(height: 1),
          const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'For you'),
              Tab(text: 'News'),
              Tab(text: 'Sports'),
            ],
          ),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(
              children: [
                _TrendingList(category: 'Trending in Tech'),
                _TrendingList(category: 'News · Trending'),
                _TrendingList(category: 'Sports · Trending'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendingList extends StatelessWidget {
  final String category;

  const _TrendingList({required this.category});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = List.generate(8, (index) {
      return {
        'category': category,
        'title': 'Sample trend #${index + 1}',
        'count': '${(index + 1) * 2}K posts',
      };
    });

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = items[index];
        return InkWell(
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['category'] as String,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  item['title'] as String,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  item['count'] as String,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TwitterNotificationsPage extends StatelessWidget {
  const _TwitterNotificationsPage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              'Notifications',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          const TabBar(
            tabs: [
              Tab(text: 'All'),
              Tab(text: 'Verified'),
              Tab(text: 'Mentions'),
            ],
          ),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(
              children: [
                _NotificationList(type: 'all'),
                _NotificationList(type: 'verified'),
                _NotificationList(type: 'mentions'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationList extends StatelessWidget {
  final String type;

  const _NotificationList({required this.type});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = List.generate(10, (index) {
      IconData icon;
      String text;
      switch (type) {
        case 'verified':
          icon = Icons.verified;
          text = 'Verified account engaged with your post';
          break;
        case 'mentions':
          icon = Icons.alternate_email;
          text = 'User mentioned you in a post';
          break;
        default:
          icon = Icons.favorite_border;
          text = 'User liked your post';
      }
      return {
        'icon': icon,
        'text': text,
      };
    });

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = items[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                item['icon'] as IconData,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              const CircleAvatar(
                radius: 18,
                backgroundImage: AssetImage('assets/images/story1.jpg'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item['text'] as String,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TwitterBookmarksPage extends StatelessWidget {
  const _TwitterBookmarksPage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sampleTweets = List.generate(5, (index) {
      return {
        'username': 'Bookmarked User ${index + 1}',
        'handle': '@bookmarked${index + 1}',
        'time': '· 2h',
        'text': 'This is a bookmarked tweet example #${index + 1}.',
        'image': '',
        'liked': false,
        'likes': (index + 1) * 3,
        'comments': index,
        'reposts': index,
      };
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bookmarks',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                '@you',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            itemCount: sampleTweets.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final t = sampleTweets[index];
              final String? image = t['image'] as String?;
              final post = <String, dynamic>{
                'id': 'bookmark-$index',
                'username': t['username'],
                'handle': t['handle'],
                'time': t['time'],
                'text': t['text'],
                'image': image == null || image.isEmpty ? null : image,
                'likes': t['likes'],
                'liked': t['liked'],
                'likedByUser': t['liked'],
                'comments': <Map<String, dynamic>>[],
                'commentsCount': t['comments'],
                'reposts': t['reposts'],
                'repostedByUser': false,
              };
              return TweetCard(
                post: post,
                onUpdate: (_) {},
                onCreateQuote: null,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TwitterProfilePage extends StatelessWidget {
  const _TwitterProfilePage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sampleTweets = List.generate(6, (index) {
      return {
        'username': 'Demo User',
        'handle': '@demouser',
        'time': '· ${index + 1}d',
        'text': 'This is a sample post #${index + 1} on the profile timeline.',
        'image': '',
        'liked': false,
        'likes': (index + 1) * 5,
        'comments': index,
        'reposts': index,
      };
    });

    return DefaultTabController(
      length: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 150,
            child: Stack(
              children: [
                Container(
                  height: 100,
                  color: Colors.grey[800],
                ),
                Positioned(
                  left: 16,
                  bottom: 0,
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor:
                        Theme.of(context).scaffoldBackgroundColor,
                    child: const CircleAvatar(
                      radius: 30,
                      backgroundImage:
                          AssetImage('assets/images/story1.jpg'),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Demo User',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  '@demouser',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bio goes here. This is a short description matching X style.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_month, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Joined January 2024',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '120',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Following',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '200',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Followers',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Posts'),
              Tab(text: 'Replies'),
              Tab(text: 'Media'),
              Tab(text: 'Likes'),
            ],
          ),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(
              children: [
                _ProfileFeed(tweets: sampleTweets),
                _ProfileFeed(tweets: sampleTweets),
                _ProfileFeed(tweets: sampleTweets),
                _ProfileFeed(tweets: sampleTweets),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileFeed extends StatelessWidget {
  final List<Map<String, dynamic>> tweets;

  const _ProfileFeed({required this.tweets});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: tweets.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final t = tweets[index];
        final String? image = t['image'] as String?;
        final post = <String, dynamic>{
          'id': 'profile-$index',
          'username': t['username'],
          'handle': t['handle'],
          'time': t['time'],
          'text': t['text'],
          'image': image == null || image.isEmpty ? null : image,
          'likes': t['likes'],
          'liked': t['liked'],
          'likedByUser': t['liked'],
          'comments': <Map<String, dynamic>>[],
          'commentsCount': t['comments'],
          'reposts': t['reposts'],
          'repostedByUser': false,
        };
        return TweetCard(
          post: post,
          onUpdate: (_) {},
          onCreateQuote: null,
        );
      },
    );
  }
}

class _TwitterMorePage extends StatelessWidget {
  const _TwitterMorePage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Text(
        'Open the More menu from the sidebar',
        style:
            theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
      ),
    );
  }
}
