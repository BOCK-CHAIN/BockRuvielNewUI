import 'dart:typed_data';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/reel_model.dart';
import '../config/supabase_config.dart';
import 'auth_service.dart';
import 'api_client.dart';

class ReelService {
  static String _encodeAsDataUrl({
    required Uint8List bytes,
    required bool isVideo,
  }) {
    final base64Data = base64Encode(bytes);
    final mime = isVideo ? 'video/mp4' : 'image/jpeg';
    return 'data:$mime;base64,$base64Data';
  }

  /// Upload reel video to Supabase Storage (now via backend)
  static Future<String?> uploadReelVideo({
    Uint8List? videoBytes,
    File? videoFile,
    required String userId,
  }) async {
    try {
      String? base64Video;

      if (kIsWeb && videoBytes != null) {
        base64Video = base64Encode(videoBytes);
      } else if (!kIsWeb && videoFile != null) {
        final bytes = await videoFile.readAsBytes();
        base64Video = base64Encode(bytes);
      }

      // Backend will handle the actual upload to Supabase Storage
      return base64Video != null ? 'uploading' : null;
    } catch (e) {
      debugPrint('❌ Reel video upload failed: $e');
      return null;
    }
  }

  /// Create a new reel
  static Future<ReelModel?> createReel({
    String? videoUrl,
    String? caption,
    String? music,
    Uint8List? videoBytes,
    File? videoFile,
    required String userId,
  }) async {
    try {
      String? videoBase64;
      
      if (videoBytes != null) {
        videoBase64 = base64Encode(videoBytes);
      } else if (videoFile != null) {
        final bytes = await videoFile.readAsBytes();
        videoBase64 = base64Encode(bytes);
      }

      final response = await ApiClient.post('/reels', body: {
        'video_url': videoUrl,
        'caption': caption,
        'music': music,
        if (videoBase64 != null) 'videoBase64': videoBase64,
      });

      final responseReel = response['reel'] as Map<String, dynamic>;
      return ReelModel.fromJson(responseReel, currentUserId: AuthService.currentUserId);
    } catch (e) {
      debugPrint('❌ Create reel error: $e');
      return null;
    }
  }

  /// Get all reels - alias for fetchReels
  static Future<List<ReelModel>> fetchReels() async {
    return getReels();
  }

  /// Get all reels
  static Future<List<ReelModel>> getReels() async {
    try {
      final response = await ApiClient.get('/reels');
      final reelsData = response['reels'] as List;
      return reelsData.map((reel) => ReelModel.fromJson(reel as Map<String, dynamic>, currentUserId: AuthService.currentUserId)).toList();
    } catch (e) {
      debugPrint('❌ Get reels error: $e');
      return [];
    }
  }

  /// Get reels for a specific user
  static Future<List<ReelModel>> getUserReels(String userId) async {
    try {
      final response = await ApiClient.get('/reels', queryParameters: {
        'user_id': userId,
      });
      final reelsData = response['reels'] as List;
      return reelsData.map((reel) => ReelModel.fromJson(reel as Map<String, dynamic>, currentUserId: AuthService.currentUserId)).toList();
    } catch (e) {
      debugPrint('❌ Get user reels error: $e');
      return [];
    }
  }

  /// Like/unlike a reel
  static Future<bool> toggleReelLike(String reelId) async {
    try {
      final response = await ApiClient.post('/reels/$reelId/like');
      return response['success'] == true;
    } catch (e) {
      debugPrint('❌ Toggle reel like error: $e');
      return false;
    }
  }

  /// Delete a reel
  static Future<bool> deleteReel(String reelId) async {
    try {
      final response = await ApiClient.delete('/reels/$reelId');
      return response['success'] == true;
    } catch (e) {
      debugPrint('❌ Delete reel error: $e');
      return false;
    }
  }
}