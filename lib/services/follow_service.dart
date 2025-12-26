import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';
import '../models/user_model.dart';
import 'auth_service.dart';

class FollowService {
  static final _client = Supabase.instance.client;

  /// Generate a UUID v4
  static String _generateUUID() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    
    // Set version bits (4)
    bytes[6] = (bytes[6] & 0x0F) | 0x40;
    // Set variant bits (8, 9, A, or B)
    bytes[8] = (bytes[8] & 0x3F) | 0x80;
    
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }

  /// Follow a user
  static Future<void> followUser(String userId) async {
    try {
      final currentUserId = AuthService.currentUserId;
      if (currentUserId == null) throw Exception('User not authenticated');

      if (currentUserId == userId) {
        throw Exception('Cannot follow yourself');
      }

      // Check if already following
      final existing = await _client
          .from('follows')
          .select()
          .eq('follower_id', currentUserId)
          .eq('following_id', userId)
          .maybeSingle();

      if (existing != null) {
        return; // Already following
      }

// Create follow relationship
      await _client.from('follows').insert({
        'id': _generateUUID(),
        'follower_id': currentUserId,
        'following_id': userId,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Update follower count for followed user
      await _client.rpc('increment_followers_count', params: {'user_id': userId});

      // Update following count for current user
      await _client.rpc('increment_following_count', params: {'user_id': currentUserId});
    } catch (e) {
      debugPrint('❌ Error following user: $e');
      rethrow;
    }
  }

  /// Unfollow a user
  static Future<void> unfollowUser(String userId) async {
    try {
      final currentUserId = AuthService.currentUserId;
      if (currentUserId == null) throw Exception('User not authenticated');

      // Delete follow relationship
      await _client
          .from('follows')
          .delete()
          .eq('follower_id', currentUserId)
          .eq('following_id', userId);

      // Update follower count for unfollowed user
      await _client.rpc('decrement_followers_count', params: {'user_id': userId});

      // Update following count for current user
      await _client.rpc('decrement_following_count', params: {'user_id': currentUserId});
    } catch (e) {
      debugPrint('❌ Error unfollowing user: $e');
      rethrow;
    }
  }

  /// Check if current user is following a user
  static Future<bool> isFollowing(String userId) async {
    try {
      final currentUserId = AuthService.currentUserId;
      if (currentUserId == null) return false;

      final response = await _client
          .from('follows')
          .select()
          .eq('follower_id', currentUserId)
          .eq('following_id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('❌ Error checking follow status: $e');
      return false;
    }
  }

  /// Get followers of a user
  static Future<List<UserModel>> getFollowers(String userId) async {
    try {
      final response = await _client
          .from('follows')
          .select('''
            follower_id,
            profiles!follows_follower_id_fkey(*)
          ''')
          .eq('following_id', userId);

      final followers = <UserModel>[];
      for (var item in response) {
        if (item['profiles'] != null) {
          followers.add(UserModel.fromJson(item['profiles']));
        }
      }

      return followers;
    } catch (e) {
      debugPrint('❌ Error fetching followers: $e');
      return [];
    }
  }

  /// Get users that a user is following
  static Future<List<UserModel>> getFollowing(String userId) async {
    try {
      final response = await _client
          .from('follows')
          .select('''
            following_id,
            profiles!follows_following_id_fkey(*)
          ''')
          .eq('follower_id', userId);

      final following = <UserModel>[];
      for (var item in response) {
        if (item['profiles'] != null) {
          following.add(UserModel.fromJson(item['profiles']));
        }
      }

      return following;
    } catch (e) {
      debugPrint('❌ Error fetching following: $e');
      return [];
    }
  }

  /// Get suggested users to follow
  static Future<List<UserModel>> getSuggestedUsers({int limit = 10}) async {
    try {
      final currentUserId = AuthService.currentUserId;
      if (currentUserId == null) return [];

      // Get users not followed by current user
      final following = await getFollowing(currentUserId);
      final followingIds = following.map((u) => u.id).toList();
      followingIds.add(currentUserId); // Exclude self

      final response = await _client
          .from('profiles')
          .select()
          .not('id', 'in', followingIds.isEmpty ? [''] : followingIds)
          .order('followers_count', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => UserModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching suggested users: $e');
      return [];
    }
  }
}



