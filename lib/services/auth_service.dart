import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthService {
  final String _baseUrl = 'http://localhost:3000/api'; // Replace with your backend URL

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  Stream<User?> get authStateChanges async* {
    final token = await _getToken();
    if (token != null) {
      final user = await getCurrentUserProfile();
      yield user as User?;
    } else {
      yield null;
    }
  }

  Future<User?> get currentUser async {
    final token = await _getToken();
    if (token != null) {
      return await getCurrentUserProfile() as User?;
    }
    return null;
  }

  Future<String?> get currentUserId async {
    final user = await currentUser;
    return user?.id;
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String username,
    String? fullName,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'username': username,
        'full_name': fullName,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      await _saveToken(data['data']['session']['access_token']);
    } else {
      throw Exception('Failed to sign up');
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await _saveToken(data['data']['session']['access_token']);
    } else {
      throw Exception('Failed to sign in');
    }
  }

  Future<void> signOut() async {
    final token = await _getToken();
    if (token != null) {
        await http.post(
        Uri.parse('$_baseUrl/auth/logout'),
        headers: {'Authorization': 'Bearer $token'},
      );
      await _removeToken();
    }
  }

  Future<UserModel?> getCurrentUserProfile() async {
    final token = await _getToken();
    if (token == null) {
      return null;
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/auth/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final user = data['user'];
      return UserModel(
        id: user['id'],
        username: user['user_metadata']?['username'] ?? '',
        email: user['email'] ?? '',
        fullName: user['user_metadata']?['full_name'],
        bio: user['user_metadata']?['bio'],
        profileImageUrl: user['user_metadata']?['profile_image_url'],
        createdAt: DateTime.parse(user['created_at']),
      );
    } else {
      return null;
    }
  }

  Future<void> updateProfile({
    String? fullName,
    String? bio,
    String? profileImageUrl,
  }) async {
    // This will be implemented in the next steps
  }
}
