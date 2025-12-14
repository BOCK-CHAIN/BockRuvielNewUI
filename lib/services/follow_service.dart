import 'dart:convert';
import 'package:http/http.dart' as http;

class FollowService {
  static const String _backendUrl = 'http://localhost:3000/api';

  static Future<void> followUser(String userId, String followedId) async {
    await http.post(
      Uri.parse('$_backendUrl/follow'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'followedId': followedId}),
    );
  }

  static Future<void> unfollowUser(String userId, String followedId) async {
    await http.delete(
      Uri.parse('$_backendUrl/unfollow'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'followedId': followedId}),
    );
  }
}
