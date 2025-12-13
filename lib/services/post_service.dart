import 'dart:typed_data';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../config/supabase_config.dart';
import 'auth_service.dart';

class PostService {
  static final _client = Supabase.instance.client;

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

      final profile = await AuthService.getCurrentUserProfile();
      if (profile == null) throw Exception('Profile not found');

      // Upload image if available
      String? imageUrl;
      if (imageBytes != null || imageFile != null) {
        imageUrl = await uploadImage(
          imageBytes: imageBytes,
          imageFile: imageFile,
          userId: userId,
        );
      }

      // Insert post
      final postId = DateTime.now().millisecondsSinceEpoch.toString();
      final response = await _client.from('posts').insert({
        'id': postId,
        'user_id': userId,
        'username': profile.username,
        'caption': caption,
        'image_url': imageUrl,
        'post_type': postType,
        'likes_count': 0,
        'comments_count': 0,
        'created_at': DateTime.now().toIso8601String(),
      }).select().single();

      // Update user's post count
      await _client.rpc('increment_posts_count', params: {'user_id': userId});

      return PostModel.fromJson(response, currentUserId: userId);
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
      
      var query = _client
          .from('posts')
          .select('''
            *,
            profiles!posts_user_id_fkey(username, profile_image_url),
            likes(user_id),
            comments(id)
          ''');

      // Filter by post type if specified
      if (postType != null) {
        query = query.eq('post_type', postType);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => PostModel.fromJson(json, currentUserId: userId))
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
      
      var query = _client
          .from('posts')
          .select('''
            *,
            profiles!posts_user_id_fkey(username, profile_image_url),
            likes(user_id),
            comments(id)
          ''')
          .eq('user_id', userId);

      // Filter by post type if specified
      if (postType != null) {
        query = query.eq('post_type', postType);
      }

      final response = await query.order('created_at', ascending: false);

      return (response as List)
          .map((json) => PostModel.fromJson(json, currentUserId: currentUserId))
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

      // Check if already liked
      final existingLike = await _client
          .from('likes')
          .select()
          .eq('post_id', postId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existingLike != null) {
        // Unlike
        await _client
            .from('likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', userId);
        
        // Decrement likes count
        await _client.rpc('decrement_likes_count', params: {'post_id': postId});
        return false;
      } else {
        // Like
        await _client.from('likes').insert({
          'post_id': postId,
          'user_id': userId,
          'created_at': DateTime.now().toIso8601String(),
        });
        
        // Increment likes count
        await _client.rpc('increment_likes_count', params: {'post_id': postId});
        return true;
      }
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

