import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

class CommentService {
  static final supabase = Supabase.instance.client;

  static Future<List<Map<String, dynamic>>> getComments(String postId) async {
    final response = await supabase
        .from('comments')
        .select('''
          *, 
          user:user_id (id, username, profile_image_url)
        ''')
        .eq('post_id', postId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> addComment(String postId, String content) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Get profile to populate username column (NOT NULL in schema)
    final profile = await AuthService.getCurrentUserProfile();
    if (profile == null) throw Exception('Profile not found');

    final commentId = DateTime.now().millisecondsSinceEpoch.toString();

    await supabase.from('comments').insert({
      'id': commentId,
      'post_id': postId,
      'user_id': user.id,
      'username': profile.username,
      'comment': content,
    });
  }

  static Future<void> deleteComment(String commentId) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await supabase
        .from('comments')
        .delete()
        .eq('id', commentId)
        .eq('user_id', user.id);
  }
}
