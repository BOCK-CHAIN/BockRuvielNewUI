import 'package:flutter/material.dart';
import '../models/story_model.dart';
import '../widgets/story_avatar.dart';

class StoryDemoScreen extends StatelessWidget {
  const StoryDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Demo stories
    final storiesWithStory = [
      StoryModel(
        id: '1',
        userId: 'user1',
        username: 'john_doe',
        profileImageUrl: 'https://picsum.photos/100',
        imageUrl: 'https://picsum.photos/200',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        expiresAt: DateTime.now().add(const Duration(hours: 22)),
      ),
      StoryModel(
        id: '2',
        userId: 'user1',
        username: 'john_doe',
        profileImageUrl: 'https://picsum.photos/100',
        videoUrl: 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4',
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        expiresAt: DateTime.now().add(const Duration(hours: 20)),
      ),
    ];

    final storiesWithoutStory = [
      StoryModel(
        id: '3',
        userId: 'user2',
        username: 'jane_smith',
        profileImageUrl: 'https://picsum.photos/101',
        imageUrl: 'https://picsum.photos/201',
        createdAt: DateTime.now().subtract(const Duration(days: 2)), // Expired
        expiresAt: DateTime.now().subtract(const Duration(days: 1)), // Expired
      ),
    ];

    final multipleStories = [
      StoryModel(
        id: '4',
        userId: 'user3',
        username: 'mike_wilson',
        profileImageUrl: 'https://picsum.photos/102',
        imageUrl: 'https://picsum.photos/202',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        expiresAt: DateTime.now().add(const Duration(hours: 23)),
      ),
      StoryModel(
        id: '5',
        userId: 'user3',
        username: 'mike_wilson',
        profileImageUrl: 'https://picsum.photos/102',
        imageUrl: 'https://picsum.photos/203',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        expiresAt: DateTime.now().add(const Duration(hours: 21)),
      ),
      StoryModel(
        id: '6',
        userId: 'user3',
        username: 'mike_wilson',
        profileImageUrl: 'https://picsum.photos/102',
        imageUrl: 'https://picsum.photos/204',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        expiresAt: DateTime.now().add(const Duration(hours: 19)),
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Story Avatar Demo'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Instagram-Style Story Rings',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Users with active stories show animated gradient rings. Users without stories show normal avatars.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            
            // Story examples
            const Text(
              'User with Single Story (Animated)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                StoryAvatar(
                  userId: 'user1',
                  username: 'john_doe',
                  profileImageUrl: 'https://picsum.photos/100',
                  stories: storiesWithStory,
                  radius: 40,
                  showAnimation: true,
                ),
                const SizedBox(width: 20),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('john_doe', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('2 stories', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 40),
            
            // No stories
            const Text(
              'User without Stories',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                StoryAvatar(
                  userId: 'user2',
                  username: 'jane_smith',
                  profileImageUrl: 'https://picsum.photos/101',
                  stories: storiesWithoutStory, // All expired
                  radius: 40,
                  showAnimation: false,
                ),
                const SizedBox(width: 20),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('jane_smith', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('No active stories', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 40),
            
            // Multiple stories
            const Text(
              'User with Multiple Stories (Single Ring)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                StoryAvatar(
                  userId: 'user3',
                  username: 'mike_wilson',
                  profileImageUrl: 'https://picsum.photos/102',
                  stories: multipleStories,
                  radius: 40,
                  showAnimation: true,
                ),
                const SizedBox(width: 20),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('mike_wilson', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('3 stories', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 40),
            
            const Text(
              'Smaller Sizes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                StoryAvatar(
                  userId: 'user1',
                  username: 'john',
                  profileImageUrl: 'https://picsum.photos/100',
                  stories: storiesWithStory,
                  radius: 20,
                  showAnimation: false,
                ),
                const SizedBox(width: 10),
                StoryAvatar(
                  userId: 'user1',
                  username: 'john',
                  profileImageUrl: 'https://picsum.photos/100',
                  stories: storiesWithStory,
                  radius: 25,
                  showAnimation: false,
                ),
                const SizedBox(width: 10),
                StoryAvatar(
                  userId: 'user1',
                  username: 'john',
                  profileImageUrl: 'https://picsum.photos/100',
                  stories: storiesWithStory,
                  radius: 30,
                  showAnimation: false,
                ),
                const SizedBox(width: 10),
                StoryAvatar(
                  userId: 'user1',
                  username: 'john',
                  profileImageUrl: 'https://picsum.photos/100',
                  stories: storiesWithStory,
                  radius: 35,
                  showAnimation: false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}