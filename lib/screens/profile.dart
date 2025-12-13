import 'dart:io' show File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../utils/image_picker_stub.dart'
    if (dart.library.html) '../utils/image_picker_web.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../services/post_service.dart';
import '../services/story_service.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../models/story_model.dart';
import 'select_post_type_screen.dart';
import 'login_screen.dart';
import 'settings_screen.dart';
import 'create_story_screen.dart';
import 'story_viewer_screen.dart';
import '../widgets/post_modal.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? userProfile;
  List<PostModel> posts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _changeProfilePicture() async {
    if (userProfile == null) return;

    try {
      final result = await ImagePickerHelper.pickImage();
      if (result == null) return;

      Uint8List? imageBytes;
      File? imageFile;

      if (result['isWeb'] == true) {
        imageBytes = result['bytes'] as Uint8List?;
      } else {
        imageFile = result['file'] as File?;
      }

      setState(() => isLoading = true);

      final url = await AuthService.uploadProfileImage(
        imageBytes: imageBytes,
        imageFile: imageFile,
      );

      if (!mounted) return;
      if (url != null) {
        await _loadProfile();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated')), 
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile picture')), 
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile picture: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _loadProfile() async {
    setState(() => isLoading = true);
    try {
      final profile = await AuthService.getCurrentUserProfile();
      if (profile != null) {
        // Only fetch Instagram posts for profile
        final userPosts = await PostService.fetchUserPosts(
          profile.id,
          postType: 'instagram',
        );
        if (mounted) {
          setState(() {
            userProfile = profile;
            posts = userPosts;
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to load profile')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  Future<void> _editProfile() async {
    if (userProfile == null) return;

    final nameController = TextEditingController(text: userProfile!.fullName ?? '');
    final bioController = TextEditingController(text: userProfile!.bio ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Profile"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: _changeProfilePicture,
              child: const Text("Change profile photo"),
            ),
            const SizedBox(height: 8),
            TextField(
                controller: nameController,
              decoration: const InputDecoration(labelText: "Full Name"),
            ),
            TextField(
              controller: bioController,
              decoration: const InputDecoration(labelText: "Bio"),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Save"),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await AuthService.updateProfile(
          fullName: nameController.text.trim().isEmpty ? null : nameController.text.trim(),
          bio: bioController.text.trim().isEmpty ? null : bioController.text.trim(),
        );
        if (mounted) {
          _loadProfile(); // Reload profile
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating profile: $e')),
          );
        }
      }
    }
  }

  Future<void> _addNewPost() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SelectPostTypeScreen()),
    );
    
    if (result == true) {
      _loadProfile(); // Reload posts
    }
  }

  void _openPost(PostModel post) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: PostModal(post: post),
        );
      },
    );
  }

  void _openMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Settings"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SettingsScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmark_border),
              title: const Text("Saved"),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Logout", style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                try {
                  await AuthService.signOut();
                  if (mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error logging out: $e')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _shareProfile() {
    if (userProfile == null) return;
    Clipboard.setData(ClipboardData(text: "https://ruviel.app/${userProfile!.username}"));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile link copied to clipboard!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (userProfile == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text("Profile"),
          backgroundColor: theme.appBarTheme.backgroundColor,
        ),
        body: const Center(
          child: Text("Failed to load profile"),
        ),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: theme.appBarTheme.backgroundColor,
          title: Text(
            userProfile!.username,
            style: theme.appBarTheme.titleTextStyle,
          ),
          centerTitle: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.add_box_outlined, color: Colors.black, size: 28),
              onPressed: _addNewPost,
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.menu, color: Colors.black, size: 28),
              onPressed: _openMenu,
            ),
            const SizedBox(width: 12),
          ],
        ),
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            // Tap on avatar: if user has stories, view; else create
                            final stories = await StoryService.fetchUserStories(userProfile!.id);
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
                                    userId: userProfile!.id,
                                  ),
                                ),
                              );
                            }
                          },
                          onLongPress: _changeProfilePicture,
                          child: CircleAvatar(
                            radius: 40,
                            backgroundImage: userProfile!.profileImageUrl != null &&
                                    userProfile!.profileImageUrl!.isNotEmpty
                                ? NetworkImage(userProfile!.profileImageUrl!)
                                : null,
                            child: (userProfile!.profileImageUrl == null ||
                                    userProfile!.profileImageUrl!.isEmpty)
                                ? Text(
                                    userProfile!.username.isNotEmpty
                                        ? userProfile!.username[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 24,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        const Spacer(),
                        Column(
                          children: [
                            Text(
                              "${userProfile!.postsCount}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const Text("Posts"),
                          ],
                        ),
                        const SizedBox(width: 20),
                        Column(
                          children: [
                            Text(
                              "${userProfile!.followersCount}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 19,
                              ),
                            ),
                            const Text("Followers"),
                          ],
                        ),
                        const SizedBox(width: 20),
                        Column(
                          children: [
                            Text(
                              "${userProfile!.followingCount}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 19,
                              ),
                            ),
                            const Text("Following"),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userProfile!.fullName ?? userProfile!.username,
                            style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (userProfile!.bio != null && userProfile!.bio!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                          Text(
                            userProfile!.bio!,
                            style: const TextStyle(fontSize: 15),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _editProfile,
                            child: Text(
                              "Edit Profile",
                              style: theme.textTheme.labelLarge,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _shareProfile,
                            child: Text(
                              "Share Profile",
                              style: theme.textTheme.labelLarge,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 0),
                  TabBar(
                    indicatorColor: theme.colorScheme.onBackground,
                    tabs: const [
                      Tab(icon: Icon(Icons.grid_on)),
                      Tab(icon: Icon(Icons.video_collection_outlined)),
                      Tab(icon: Icon(Icons.person_pin_outlined)),
                    ],
                  ),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(2),
              sliver: posts.isEmpty
                  ? SliverFillRemaining(
                      hasScrollBody: false,
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              "No posts yet",
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final post = posts[index];
                    return GestureDetector(
                      onTap: () => _openPost(post),
                            child: post.imageUrl != null
                                ? Image.network(
                                    post.imageUrl!,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        color: Colors.grey[200],
                                        child: const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.broken_image, color: Colors.grey),
                                      );
                                    },
                                  )
                                : Container(
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.image, color: Colors.grey),
                                  ),
                    );
                  },
                  childCount: posts.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
