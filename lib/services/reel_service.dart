import 'dart:typed_data';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/reel_model.dart';
import 'auth_service.dart';

class ReelService {
  final _client = Supabase.instance.client;
  final AuthService _authService = AuthService();

  /// Upload reel video to Supabase Storage
  Future<String?> uploadReelVideo({
    Uint8List? videoBytes,
    File? videoFile,
    required String userId,
  }) async {
    try {
      final fileName =
          'reel_${DateTime.now().millisecondsSinceEpoch}_$userId.mp4';
      final storagePath = '$userId/$fileName';

      if (kIsWeb && videoBytes != null) {
        await _client.storage
            .from('reels')
            .uploadBinary(storagePath, videoBytes,
                fileOptions: const FileOptions(upsert: true));
      } else if (!kIsWeb && videoFile != null) {
        await _client.storage
            .from('reels')
            .upload(storagePath, videoFile,
                fileOptions: const FileOptions(upsert: true));
      }

      final publicUrl = _client.storage
          .from('reels')
          .getPublicUrl(storagePath);
      return publicUrl;
    } catch (e) {
      debugPrint('❌ Reel video upload failed: $e');
      return null;
    }
  }

  /// Create a new reel
  Future<ReelModel?> createReel({
    required String videoUrl,
    String? caption,
    String? music,
  }) async {
    try {
      final userId = await _authService.currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final profile = await _authService.getCurrentUserProfile();
      if (profile == null) throw Exception('Profile not found');

      final reelId = DateTime.now().millisecondsSinceEpoch.toString();

      final response = await _client.from('reels').insert({
        'id': reelId,
        'user_id': userId,
        'username': profile.username,
        'video_url': videoUrl,
        'caption': caption,
        'music': music ?? 'Original audio',
        'likes_count': 0,
        'comments_count': 0,
        'created_at': DateTime.now().toIso8601String(),
      }).select().single();

      return ReelModel.fromJson(response, currentUserId: userId);
    } catch (e) {
      debugPrint('❌ Error creating reel: $e');
      return null;
    }
  }

  /// Fetch reels for feed
  Future<List<ReelModel>> fetchReels({int limit = 20, int offset = 0}) async {
    try {
      final userId = await _authService.currentUserId;

      final response = await _client
          .from('reels')
          .select('''
            *,
            profiles!reels_user_id_fkey(username, profile_image_url),
            likes(user_id),
            comments(id)
          ''')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => ReelModel.fromJson(json, currentUserId: userId))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching reels: $e');
      return [];
    }
  }

  /// Toggle like on a reel
  Future<bool> toggleLike(String reelId) async {
    try {
      final userId = await _authService.currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      // Check if already liked
      final existingLike = await _client
          .from('reel_likes')
          .select()
          .eq('reel_id', reelId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existingLike != null) {
        // Unlike
        await _client
            .from('reel_likes')
            .delete()
            .eq('reel_id', reelId)
            .eq('user_id', userId);
        
        await _client.rpc('decrement_reel_likes_count', params: {'reel_id': reelId});
        return false;
      } else {
        // Like
        await _client.from('reel_likes').insert({
          'reel_id': reelId,
          'user_id': userId,
          'created_at': DateTime.now().toIso8601String(),
        });
        
        await _client.rpc('increment_reel_likes_count', params: {'reel_id': reelId});
        return true;
      }
    } catch (e) {
      debugPrint('❌ Error toggling reel like: $e');
      rethrow;
    }
  }
}
