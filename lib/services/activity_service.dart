import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/activity_model.dart';
import 'auth_service.dart';

class ActivityService {
  static const String _baseUrl = 'http://localhost:3001/api';
  static final _client = Supabase.instance.client;
  // ActivityScreen handles polling/optimistic updates.

/// Fetch activity feed (likes, comments, follows)
  static Future<List<ActivityModel>> fetchActivity({int limit = 50}) async {
    try {
      final session = _client.auth.currentSession;
      if (session == null) throw Exception('Not authenticated');
      final token = session.accessToken;
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('$_baseUrl/activities?limit=$limit'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final activities = data['activities'] as List;
        
        debugPrint('ActivityService.fetchActivity: fetched ${activities.length} rows');
        
        return activities
            .map((json) => ActivityModel.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to fetch activities: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching activity: $e');
      return [];
    }
  }

  // Note: Realtime subscriptions can be implemented, but to avoid SDK differences
  // and keep behavior predictable across environments we'll rely on polling from
  // `ActivityScreen` and optimistic updates when performing actions.

/// Create activity (called when user likes, comments, or follows)
  static Future<void> createActivity({
    required ActivityType type,
    String? postId,
    String? commentText,
    String? targetUserId,
  }) async {
    try {
      final session = _client.auth.currentSession;
      if (session == null) throw Exception('User not authenticated');
      final token = session.accessToken;

      final response = await http.post(
        Uri.parse('$_baseUrl/activities'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'type': type.toString().split('.').last,
          'targetUserId': targetUserId,
          'postId': postId,
          'commentText': commentText,
        }),
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to create activity: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error creating activity: $e');
    }
  }
}