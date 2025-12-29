import 'dart:typed_data';
import 'dart:io';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../config/supabase_config.dart';
import 'auth_service.dart';
import 'api_client.dart';

class PostService {
  static final _client = Supabase.instance.client;

  static String _encodeAsDataUrl({
    required Uint8List bytes,
    required bool isVideo,
  }) {
    final base64Data = base64Encode(bytes);
    final mime = isVideo ? 'video/mp4' : 'image/jpeg';
    return 'data:$mime;base64,$base64Data';
  }

  /// Upload image to Supabase Storage
  static Future<String?> uploadImage({
    Uint8List? imageBytes,
    File? imageFile,
    required String userId,
  }) async {
    try {
      final fileName =
          'post_${DateTime.now().millisecondsSinceEpoch}_$userId.jpg';
      final storagePath = '$userId/$fileName';

      if (kIsWeb && imageBytes != null) {
        await _client.storage
            .from(SupabaseConfig.postsBucket)
            .uploadBinary(storagePath, imageBytes,
                fileOptions: const FileOptions(upsert: true));
      } else if (!kIsWeb && imageFile != null) {
        await _client.storage
            .from(SupabaseConfig.postsBucket)
            .upload(storagePath, imageFile,
                fileOptions: const FileOptions(upsert: true));
      }

      final publicUrl = _client.storage
          .from(SupabaseConfig.postsBucket)
          .getPublicUrl(storagePath);
      return publicUrl;
    } catch (e) {
      debugPrint('❌ Image upload failed: $e');
      return null;
    }
  }

  /// Create a new post
  static Future<PostModel?> createPost({
    required String caption,
    Uint8List? imageBytes,
    File? imageFile,
    String postType = 'instagram', // 'instagram' or 'twitter'
  }) async {
    try {
      final userId = AuthService.currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      Uint8List? bytes;
      if (imageBytes != null) {
        bytes = imageBytes;
      } else if (imageFile != null) {
        bytes = await imageFile.readAsBytes();
      }

      final payload = <String, dynamic>{
        'caption': caption,
        'post_type': postType,
      };

      if (bytes != null && bytes.isNotEmpty) {
        payload['imageBase64'] = _encodeAsDataUrl(bytes: bytes, isVideo: false);
      }

      final decoded = await ApiClient.post('/posts', body: payload);
      if (decoded is Map<String, dynamic> && decoded['post'] is Map) {
        return PostModel.fromJson(
          Map<String, dynamic>.from(decoded['post'] as Map),
          currentUserId: userId,
        );
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error creating post: $e');
      return null;
    }
  }

  /// Fetch posts for feed
  static Future<List<PostModel>> fetchPosts({
    int limit = 20,
    int offset = 0,
    String? postType, // Filter by 'instagram' or 'twitter'
  }) async {
    try {
      final userId = AuthService.currentUserId;

      final qp = <String, String>{
        'limit': limit.toString(),
        'offset': offset.toString(),
      };
      if (postType != null) {
        qp['post_type'] = postType;
      }

      final decoded = await ApiClient.get('/posts', queryParameters: qp);
      if (decoded is! Map<String, dynamic>) return [];
      final list = decoded['posts'];
      if (list is! List) return [];
      return list
          .whereType<Map>()
          .map((e) => PostModel.fromJson(Map<String, dynamic>.from(e),
              currentUserId: userId))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching posts: $e');
      return [];
    }
  }

  /// Fetch user's posts
  static Future<List<PostModel>> fetchUserPosts(
    String userId, {
    String? postType, // Filter by 'instagram' or 'twitter'
  }) async {
    try {
      final currentUserId = AuthService.currentUserId;

      final qp = <String, String>{};
      if (postType != null) {
        qp['post_type'] = postType;
      }

      final decoded = await ApiClient.get('/posts/user/$userId',
          queryParameters: qp.isEmpty ? null : qp);
      if (decoded is! Map<String, dynamic>) return [];
      final list = decoded['posts'];
      if (list is! List) return [];
      return list
          .whereType<Map>()
          .map((e) => PostModel.fromJson(Map<String, dynamic>.from(e),
              currentUserId: currentUserId))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching user posts: $e');
      return [];
    }
  }

  /// Toggle like on a post
  static Future<bool> toggleLike(String postId) async {
    try {
      final userId = AuthService.currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final decoded = await ApiClient.post('/likes/posts/$postId/like');
      if (decoded is Map<String, dynamic> && decoded['is_liked'] is bool) {
        return decoded['is_liked'] as bool;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error toggling like: $e');
      rethrow;
    }
  }

  /// Add comment to a post
  static Future<CommentModel?> addComment(String postId, String commentText) async {
    try {
      final userId = AuthService.currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final profile = await AuthService.getCurrentUserProfile();
      if (profile == null) throw Exception('Profile not found');

      final commentId = DateTime.now().millisecondsSinceEpoch.toString();

      final response = await _client.from('comments').insert({
        'id': commentId,
        'post_id': postId,
        'user_id': userId,
        'username': profile.username,
        'comment': commentText,
        'created_at': DateTime.now().toIso8601String(),
      }).select().single();

      // Increment comments count
      await _client.rpc('increment_comments_count', params: {'post_id': postId});

      return CommentModel.fromJson(response);
    } catch (e) {
      debugPrint('❌ Error adding comment: $e');
      return null;
    }
  }

  /// Fetch comments for a post
  static Future<List<CommentModel>> fetchComments(String postId) async {
    try {
      final response = await _client
          .from('comments')
          .select('''
            *,
            profiles!comments_user_id_fkey(username, profile_image_url)
          ''')
          .eq('post_id', postId)
          .order('created_at', ascending: true);

      return (response as List)
          .map((json) => CommentModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching comments: $e');
      return [];
    }
  }

  /// Delete a post
  static Future<void> deletePost(String postId) async {
    try {
      final userId = AuthService.currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      // Get post to verify ownership
      final post = await _client
          .from('posts')
          .select()
          .eq('id', postId)
          .eq('user_id', userId)
          .single();

      // Delete image from storage if exists
      if (post['image_url'] != null) {
        // Extract path from URL and delete
        // Implementation depends on your storage structure
      }

      // Delete post (cascading will delete comments and likes)
      await _client.from('posts').delete().eq('id', postId);

      // Decrement user's post count
      await _client.rpc('decrement_posts_count', params: {'user_id': userId});
    } catch (e) {
      debugPrint('❌ Error deleting post: $e');
      rethrow;
    }
  }
}

