import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/post_service.dart';
import '../services/auth_service.dart';
import '../services/story_service.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../widgets/comment_section.dart';
import '../models/story_model.dart';
import 'select_post_type_screen.dart';
import 'create_story_screen.dart';
import 'story_viewer_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final PostService _postService = PostService();
  final AuthService _authService = AuthService();
  final StoryService _storyService = StoryService();
  List<PostModel> posts = [];
  UserModel? currentUserProfile;
  bool isLoading = true;
  bool isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    setState(() => isLoading = true);
    try {
      final fetchedPosts = await _postService.fetchPosts(postType: 'instagram');
      final profile = await _authService.getCurrentUserProfile();

      if (mounted) {
        setState(() {
          posts = fetchedPosts;
          currentUserProfile = profile;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading feed: $e')),
        );
      }
    }
  }

  Future<void> _refreshFeed() async {
    setState(() => isRefreshing = true);
    await _loadFeed();
    setState(() => isRefreshing = false);
  }

  Future<void> _createPost() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SelectPostTypeScreen()),
    );
    
    if (result == true) {
      _refreshFeed();
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return DateFormat('MMM d').format(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  String _formatLikes(int likes) {
    if (likes >= 1000000) {
      return '${(likes / 1000000).toStringAsFixed(1)}M';
    } else if (likes >= 1000) {
      return '${(likes / 1000).toStringAsFixed(1)}K';
    }
    return likes.toString();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);

    if (isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    Widget feed = RefreshIndicator(
      onRefresh: _refreshFeed,
      child: ListView(
        children: [
          SizedBox(
            height: 130,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 1, // Just "Your Story" for now
              itemBuilder: (context, index) {
                final String initials = (currentUserProfile?.username.isNotEmpty ?? false)
                    ? currentUserProfile!.username[0].toUpperCase()
                    : '?';

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          if (currentUserProfile == null) return;

                          final List<StoryModel> stories =
                              await _storyService.getStories();

                          if (!context.mounted) return;

                          if (stories.isEmpty) {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CreateStoryScreen(),
                              ),
                            );
                          } else {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StoryViewerScreen(
                                  stories: stories,
                                  userId: currentUserProfile!.id,
                                ),
                              ),
                            );
                          }
                        },
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundImage:
                                  currentUserProfile?.profileImageUrl != null &&
                                          currentUserProfile!.profileImageUrl!.isNotEmpty
                                      ? NetworkImage(currentUserProfile!.profileImageUrl!)
                                      : null,
                              child: (currentUserProfile?.profileImageUrl == null ||
                                      currentUserProfile!.profileImageUrl!.isEmpty)
                                  ? Text(
                                      initials,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.blue,
                                ),
                                child: const Icon(Icons.add, size: 18, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5),
                      const SizedBox(
                        width: 65,
                        child: Text(
                          "Your Story",
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          if (posts.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No posts yet',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Create your first post!',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          else
            for (var post in posts) _buildPostCard(post),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0.5,
        title: Row(
          children: [
            Image.asset("assets/images/logo.png", height: 35),
            const SizedBox(width: 5),
            Text(
              "Ruviel",
              style: theme.appBarTheme.titleTextStyle?.copyWith(
                    fontStyle: FontStyle.italic,
                  ) ??
                  const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    fontSize: 22,
                  ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_box_outlined, color: theme.iconTheme.color),
            onPressed: _createPost,
            tooltip: 'Create Post',
          ),
          IconButton(
            icon: Icon(Icons.favorite_border, color: theme.iconTheme.color),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.send_outlined, color: theme.iconTheme.color),
            onPressed: () {},
          ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: screenWidth > 1000 ? 2 : 3,
            child: Padding(
              padding: const EdgeInsets.only(right: 40),
              child: feed,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(PostModel post) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundImage: post.profileImageUrl != null && post.profileImageUrl!.isNotEmpty
                ? NetworkImage(post.profileImageUrl!)
                : null,
            child: (post.profileImageUrl == null || post.profileImageUrl!.isEmpty)
                ? Text(
                    post.username.isNotEmpty
                        ? post.username[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          title: Text(
            post.username,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          trailing: const Icon(Icons.more_vert),
        ),

        if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
          GestureDetector(
            onDoubleTap: () => _toggleLike(post),
            child: AspectRatio(
              aspectRatio: 1,
              child: Image.network(
                post.imageUrl!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
          )
        else if (post.caption != null && post.caption!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Text(post.caption!, style: const TextStyle(fontSize: 16)),
          ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  post.isLiked ? Icons.favorite : Icons.favorite_border,
                  size: 28,
                  color: post.isLiked ? Colors.red : Colors.black,
                ),
                onPressed: () => _toggleLike(post),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline, size: 28),
                onPressed: () => _showComments(post),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.send_outlined, size: 28),
                onPressed: () {},
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.bookmark_border, size: 28),
                onPressed: () {},
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            "${_formatLikes(post.likesCount)} likes",
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),

        const SizedBox(height: 4),

        if (post.caption != null && post.caption!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black),
                children: [
                  TextSpan(
                    text: "${post.username} ",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: post.caption!),
                ],
              ),
            ),
          ),

        if (post.commentsCount > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: GestureDetector(
              onTap: () => _showComments(post),
              child: Text(
                "View all ${post.commentsCount} comments",
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
          ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            _formatTimeAgo(post.createdAt),
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
        ),

        const SizedBox(height: 10),
        const Divider(),
      ],
    );
  }

  Future<void> _toggleLike(PostModel post) async {
    try {
      final wasLiked = post.isLiked;
      
      setState(() {
        final index = posts.indexOf(post);
        if (index != -1) {
          posts[index] = PostModel(
            id: post.id,
            userId: post.userId,
            username: post.username,
            profileImageUrl: post.profileImageUrl,
            caption: post.caption,
            imageUrl: post.imageUrl,
            videoUrl: post.videoUrl,
            likesCount: wasLiked ? post.likesCount - 1 : post.likesCount + 1,
            commentsCount: post.commentsCount,
            isLiked: !wasLiked,
            createdAt: post.createdAt,
            updatedAt: post.updatedAt,
          );
        }
      });

      await _postService.toggleLike(post.id);
    } catch (e) {
      _refreshFeed();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error liking post: $e')),
        );
      }
    }
  }

  void _showComments(PostModel post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.95,
          minChildSize: 0.4,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: CommentSection(postId: post.id),
              ),
            );
          },
        );
      },
    );
  }
}
