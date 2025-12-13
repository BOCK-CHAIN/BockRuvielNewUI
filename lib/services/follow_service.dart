import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

class FollowService {
  static const String _backendUrl = 'http://localhost:3000/api';

  static Future<void> followUser(String userId) async {
    try {
      final currentUserId = AuthService.currentUserId;
      if (currentUserId == null) throw Exception('User not authenticated');

      await http.post(
        Uri.parse('$_backendUrl/follow'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'followerId': currentUserId, 'followingId': userId}),
      );
    } catch (e) {
      debugPrint('❌ Error following user: $e');
      rethrow;
    }
  }

  static Future<void> unfollowUser(String userId) async {
    try {
      final currentUserId = AuthService.currentUserId;
      if (currentUserId == null) throw Exception('User not authenticated');

      await http.post(
        Uri.parse('$_backendUrl/unfollow'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'followerId': currentUserId, 'followingId': userId}),
      );
    } catch (e) {
      debugPrint('❌ Error unfollowing user: $e');
      rethrow;
    }
  }

  static Future<bool> isFollowing(String userId) async {
    try {
      final currentUserId = AuthService.currentUserId;
      if (currentUserId == null) return false;

      final response = await http.get(
        Uri.parse('$_backendUrl/is-following?followerId=$currentUserId&followingId=$userId'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['isFollowing'];
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error checking follow status: $e');
      return false;
    }
  }

  static Future<List<UserModel>> getFollowers(String userId) async {
    try {
      final response = await http.get(Uri.parse('$_backendUrl/followers/$userId'));

      if (response.statusCode == 200) {
        final List<dynamic> followersJson = jsonDecode(response.body);
        return followersJson.map((json) => UserModel.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error fetching followers: $e');
      return [];
    }
  }

  static Future<List<UserModel>> getFollowing(String userId) async {
    try {
      final response = await http.get(Uri.parse('$_backendUrl/following/$userId'));

      if (response.statusCode == 200) {
        final List<dynamic> followingJson = jsonDecode(response.body);
        return followingJson.map((json) => UserModel.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error fetching following: $e');
      return [];
    }
  }

  static Future<List<UserModel>> getSuggestedUsers({int limit = 10}) async {
    try {
      final currentUserId = AuthService.currentUserId;
      if (currentUserId == null) return [];

      final response = await http.get(
        Uri.parse('$_backendUrl/suggested-users?userId=$currentUserId&limit=$limit'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> usersJson = jsonDecode(response.body);
        return usersJson.map((json) => UserModel.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error fetching suggested users: $e');
      return [];
    }
  }
}
