import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/activity_model.dart';
import 'auth_service.dart';

class ActivityService {
  static final _client = Supabase.instance.client;
  // No persistent realtime channel here; ActivityScreen handles polling/optimistic updates.

  /// Fetch activity feed (likes, comments, follows)
  static Future<List<ActivityModel>> fetchActivity({int limit = 50}) async {
    try {
      final currentUserId = AuthService.currentUserId;
      if (currentUserId == null) return [];

      // Fetch activities where either the current user is the target (incoming)
      // or the current user is the actor (outgoing) so likes/comments/follows
      // performed by the user also show up in the Activity feed.
      final orFilter = 'target_user_id.eq.$currentUserId,user_id.eq.$currentUserId';

      final response = await _client
          .from('activities')
          .select('''
            *,
            profiles!activities_user_id_fkey(username, profile_image_url),
            posts(image_url)
          ''')
          .or(orFilter)
          .order('created_at', ascending: false)
          .limit(limit);

      // Debug: log response type and size to help diagnose empty feeds
      try {
        if (response is List) {
          debugPrint('ActivityService.fetchActivity: fetched ${response.length} rows');
          if (response.isNotEmpty) {
            debugPrint('ActivityService.fetchActivity: first row keys = ${ (response.first is Map) ? (response.first as Map).keys.toList() : 'non-map' }');
          }
        } else {
          debugPrint('ActivityService.fetchActivity: response is not a List: ${response.runtimeType}');
        }
      } catch (e) {
        debugPrint('ActivityService.fetchActivity: debug print failed: $e');
      }

      return (response as List)
          .map((json) => ActivityModel.fromJson(json))
          .toList();
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
      final userId = AuthService.currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final activityId = DateTime.now().millisecondsSinceEpoch.toString();

      await _client.from('activities').insert({
        'id': activityId,
        'user_id': userId,
        'target_user_id': targetUserId ?? userId,
        'type': type.toString().split('.').last,
        'post_id': postId,
        'comment_text': commentText,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('❌ Error creating activity: $e');
    }
  }
}



