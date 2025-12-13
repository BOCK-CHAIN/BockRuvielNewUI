import 'dart:typed_data';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/story_model.dart';
import '../config/supabase_config.dart';
import 'auth_service.dart';

class StoryService {
  static final _client = Supabase.instance.client;
  static const Duration storyExpiry = Duration(hours: 24);

  /// Upload story image/video to Supabase Storage
  static Future<String?> uploadStoryMedia({
    Uint8List? mediaBytes,
    File? mediaFile,
    required String userId,
    required bool isVideo,
  }) async {
    try {
      final extension = isVideo ? 'mp4' : 'jpg';
      final fileName =
          'story_${DateTime.now().millisecondsSinceEpoch}_$userId.$extension';
      final storagePath = '$userId/$fileName';
      final bucket = SupabaseConfig.storiesBucket;

      if (kIsWeb && mediaBytes != null) {
        await _client.storage
            .from(bucket)
            .uploadBinary(storagePath, mediaBytes,
                fileOptions: const FileOptions(upsert: true));
      } else if (!kIsWeb && mediaFile != null) {
        await _client.storage
            .from(bucket)
            .upload(storagePath, mediaFile,
                fileOptions: const FileOptions(upsert: true));
      }

      final publicUrl = _client.storage.from(bucket).getPublicUrl(storagePath);
      return publicUrl;
    } catch (e) {
      debugPrint('❌ Story media upload failed: $e');
      return null;
    }
  }

  /// Create a new story
  static Future<StoryModel?> createStory({
    Uint8List? imageBytes,
    File? imageFile,
    Uint8List? videoBytes,
    File? videoFile,
    String? caption,
  }) async {
    try {
      final userId = AuthService.currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final profile = await AuthService.getCurrentUserProfile();
      if (profile == null) throw Exception('Profile not found');

      String? imageUrl;
      String? videoUrl;

      // Upload media
      if (imageBytes != null || imageFile != null) {
        imageUrl = await uploadStoryMedia(
          mediaBytes: imageBytes,
          mediaFile: imageFile,
          userId: userId,
          isVideo: false,
        );
      }

      if (videoBytes != null || videoFile != null) {
        videoUrl = await uploadStoryMedia(
          mediaBytes: videoBytes,
          mediaFile: videoFile,
          userId: userId,
          isVideo: true,
        );
      }

      if ((imageUrl == null || imageUrl.isEmpty) &&
          (videoUrl == null || videoUrl.isEmpty)) {
        throw Exception('No media provided');
      }

      // Insert story
      final storyId = DateTime.now().millisecondsSinceEpoch.toString();
      final expiresAt = DateTime.now().add(storyExpiry);

      final response = await _client.from('stories').insert({
        'id': storyId,
        'user_id': userId,
        'username': profile.username,
        'image_url': imageUrl,
        'video_url': videoUrl,
        'caption': caption,
        'created_at': DateTime.now().toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
      }).select().single();

      return StoryModel.fromJson(response);
    } catch (e) {
      debugPrint('❌ Error creating story: $e');
      return null;
    }
  }

  /// Fetch active stories from users you follow
  static Future<Map<String, List<StoryModel>>> fetchFollowingStories() async {
    try {
      final userId = AuthService.currentUserId;
      if (userId == null) return {};

      // Get users you follow
      final following = await _client
          .from('follows')
          .select('following_id')
          .eq('follower_id', userId);

      final followingIds = (following as List)
          .map((f) => f['following_id'] as String)
          .toList();

      // Add current user
      followingIds.add(userId);

      // Fetch active stories
      final now = DateTime.now().toIso8601String();
      var query = _client
          .from('stories')
          .select('''
            *,
            profiles!stories_user_id_fkey(username, profile_image_url)
          ''')
          .gte('expires_at', now);
      
      // Filter by user IDs - build OR conditions if needed
      if (followingIds.isNotEmpty) {
        // Use 'in' filter with proper syntax
        query = query.inFilter('user_id', followingIds);
      }
      
      final response = await query.order('created_at', ascending: false);

      // Group by user
      final Map<String, List<StoryModel>> grouped = {};
      for (var storyJson in response) {
        final story = StoryModel.fromJson(storyJson);
        if (!story.isExpired) {
          grouped.putIfAbsent(story.userId, () => []).add(story);
        }
      }

      // Sort stories within each user by created_at
      grouped.forEach((key, stories) {
        stories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      });

      return grouped;
    } catch (e) {
      debugPrint('❌ Error fetching stories: $e');
      return {};
    }
  }

  /// Fetch user's stories
  static Future<List<StoryModel>> fetchUserStories(String userId) async {
    try {
      final now = DateTime.now().toIso8601String();
      final response = await _client
          .from('stories')
          .select('''
            *,
            profiles!stories_user_id_fkey(username, profile_image_url)
          ''')
          .eq('user_id', userId)
          .gte('expires_at', now)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => StoryModel.fromJson(json))
          .where((story) => !story.isExpired)
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching user stories: $e');
      return [];
    }
  }

  /// Delete expired stories (should be run periodically)
  static Future<void> deleteExpiredStories() async {
    try {
      final now = DateTime.now().toIso8601String();
      await _client
          .from('stories')
          .delete()
          .lt('expires_at', now);
    } catch (e) {
      debugPrint('❌ Error deleting expired stories: $e');
    }
  }
}

