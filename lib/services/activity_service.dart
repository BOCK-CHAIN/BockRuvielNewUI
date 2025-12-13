import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/activity_model.dart';
import 'auth_service.dart';

class ActivityService {
  static const String _backendUrl = 'http://localhost:3000/api';

  static Future<List<ActivityModel>> fetchActivity({int limit = 50}) async {
    try {
      final currentUserId = AuthService.currentUserId;
      if (currentUserId == null) return [];

      final response = await http.get(
        Uri.parse('$_backendUrl/activities?userId=$currentUserId&limit=$limit'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> activitiesJson = jsonDecode(response.body);
        return activitiesJson.map((json) => ActivityModel.fromJson(json)).toList();
      } else {
        debugPrint('ActivityService.fetchActivity: failed with status ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error fetching activity: $e');
      return [];
    }
  }

  static Future<void> createActivity({
    required ActivityType type,
    String? postId,
    String? commentText,
    String? targetUserId,
  }) async {
    try {
      final userId = AuthService.currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final response = await http.post(
        Uri.parse('$_backendUrl/activities'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'targetUserId': targetUserId,
          'type': type.toString().split('.').last,
          'postId': postId,
          'commentText': commentText,
        }),
      );

      if (response.statusCode != 201) {
        debugPrint('❌ Error creating activity: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error creating activity: $e');
    }
  }
}
