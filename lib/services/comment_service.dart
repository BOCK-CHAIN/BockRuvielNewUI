import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/comment_model.dart';

class CommentService {
  static const String _backendUrl = 'http://localhost:3000/api';

  static Future<List<CommentModel>> getComments(String postId) async {
    final response = await http.get(Uri.parse('$_backendUrl/comments?postId=$postId'));

    if (response.statusCode == 200) {
      final List<dynamic> commentsJson = jsonDecode(response.body);
      return commentsJson.map((json) => CommentModel.fromJson(json)).toList();
    } else {
      return [];
    }
  }

  static Future<void> createComment(String postId, String userId, String content) async {
    await http.post(
      Uri.parse('$_backendUrl/comments'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'postId': postId, 'userId': userId, 'content': content}),
    );
  }
}
