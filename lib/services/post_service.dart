import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/post_model.dart';
import '../models/comment_model.dart';
import 'auth_service.dart';

class PostService {
  final String _backendUrl = 'http://localhost:3000/api';
  final AuthService _authService = AuthService();

  Future<String?> _getUserId() async {
    return await _authService.currentUserId;
  }

  Future<String?> uploadImage({
    Uint8List? imageBytes,
    File? imageFile,
    required String userId,
  }) async {
    // This now needs to be handled by your backend. 
    // The backend will receive the image and upload it to Supabase.
    // This is a placeholder and needs a proper implementation.
    return null;
  }

  Future<PostModel?> createPost({
    required String caption,
    Uint8List? imageBytes,
    File? imageFile,
    String postType = 'instagram', 
  }) async {
    final userId = await _getUserId();
    if (userId == null) throw Exception('User not authenticated');

    final profile = await _authService.getCurrentUserProfile();
    if (profile == null) throw Exception('Profile not found');

    // Image upload would be handled by a separate endpoint on your backend
    // For now, we assume no image upload
    String? imageUrl;

    final response = await http.post(
      Uri.parse('$_backendUrl/posts'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'username': profile.username,
        'caption': caption,
        'imageUrl': imageUrl,
        'postType': postType,
      }),
    );

    if (response.statusCode == 201) {
      return PostModel.fromJson(jsonDecode(response.body), currentUserId: userId);
    } else {
      return null;
    }
  }

  Future<List<PostModel>> fetchPosts({
    int limit = 20,
    int offset = 0,
    String? postType,
  }) async {
    final userId = await _getUserId();
    final queryParameters = {
      'limit': limit.toString(),
      'offset': offset.toString(),
      if (postType != null) 'postType': postType,
    };

    final response = await http.get(
      Uri.parse('$_backendUrl/posts').replace(queryParameters: queryParameters),
    );

    if (response.statusCode == 200) {
      final List<dynamic> postsJson = jsonDecode(response.body);
      return postsJson.map((json) => PostModel.fromJson(json, currentUserId: userId)).toList();
    } else {
      return [];
    }
  }

  Future<List<PostModel>> fetchUserPosts(
    String userId, {
    String? postType,
  }) async {
    final currentUserId = await _getUserId();
    final queryParameters = {
      if (postType != null) 'postType': postType,
    };
    
    final response = await http.get(
      Uri.parse('$_backendUrl/users/$userId/posts').replace(queryParameters: queryParameters),
    );

    if (response.statusCode == 200) {
      final List<dynamic> postsJson = jsonDecode(response.body);
      return postsJson.map((json) => PostModel.fromJson(json, currentUserId: currentUserId)).toList();
    } else {
      return [];
    }
  }

  Future<bool> toggleLike(String postId) async {
    final userId = await _getUserId();
    if (userId == null) throw Exception('User not authenticated');

    final response = await http.post(
      Uri.parse('$_backendUrl/posts/$postId/like'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['liked'];
    } else {
      throw Exception('Failed to toggle like');
    }
  }

  Future<CommentModel?> addComment(String postId, String commentText) async {
    final userId = await _getUserId();
    if (userId == null) throw Exception('User not authenticated');

    final profile = await _authService.getCurrentUserProfile();
    if (profile == null) throw Exception('Profile not found');

    final response = await http.post(
      Uri.parse('$_backendUrl/posts/$postId/comments'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'username': profile.username,
        'comment': commentText,
      }),
    );

    if (response.statusCode == 201) {
      return CommentModel.fromJson(jsonDecode(response.body));
    } else {
      return null;
    }
  }

  Future<List<CommentModel>> fetchComments(String postId) async {
    final response = await http.get(Uri.parse('$_backendUrl/posts/$postId/comments'));

    if (response.statusCode == 200) {
      final List<dynamic> commentsJson = jsonDecode(response.body);
      return commentsJson.map((json) => CommentModel.fromJson(json)).toList();
    } else {
      return [];
    }
  }

  Future<void> deletePost(String postId) async {
    final userId = await _getUserId();
    if (userId == null) throw Exception('User not authenticated');

    final response = await http.delete(
      Uri.parse('$_backendUrl/posts/$postId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId}),
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete post');
    }
  }
}
