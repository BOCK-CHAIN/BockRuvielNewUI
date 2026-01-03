import 'package:flutter/material.dart';
import 'create_post_screen.dart';
import 'create_story_screen.dart';

class SelectPostTypeScreen extends StatelessWidget {
  const SelectPostTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _option(
              context,
              title: 'Instagram Post',
              icon: Icons.photo_camera,
              onTap: () => _open(
                context,
                const CreatePostScreen(postType: 'instagram'),
              ),
            ),
            _option(
              context,
              title: 'Twitter / Threads',
              icon: Icons.chat_bubble_outline,
              onTap: () => _open(
                context,
                const CreatePostScreen(postType: 'twitter'),
              ),
            ),
            _option(
              context,
              title: 'Reel',
              icon: Icons.movie,
              onTap: () => _open(
                context,
                const CreateStoryScreen(isReel: true),
              ),
            ),
            _option(
              context,
              title: 'Story',
              icon: Icons.auto_awesome,
              onTap: () => _open(
                context,
                const CreateStoryScreen(isReel: false),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _option(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }

  Future<void> _open(BuildContext context, Widget page) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
    if (result == true && context.mounted) {
      Navigator.pop(context, true);
    }
  }
}