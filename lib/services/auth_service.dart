import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  static const String _backendUrl = 'http://localhost:3000/api'; // Replace with your backend URL

  static UserModel? _currentUser;

  static UserModel? get currentUser => _currentUser;

  static bool get isAuthenticated => _currentUser != null;

  static String? get currentUserId => _currentUser?.id;

  static Future<void> _saveSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('user', jsonEncode(user.toJson()));
    _currentUser = user;
  }

  static Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('user');
    _currentUser = null;
  }

  static Future<void> loadSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');
    if (userData != null) {
      _currentUser = UserModel.fromJson(jsonDecode(userData));
    }
  }

  static Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String username,
    String? fullName,
  }) async {
    final response = await http.post(
      Uri.parse('$_backendUrl/auth/signup'),
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
      final user = UserModel.fromJson(data['user']);
      await _saveSession(user);
      return {'user': user, 'session': data['session']};
    } else {
      throw Exception('Failed to sign up');
    }
  }

  static Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$_backendUrl/auth/signin'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final user = UserModel.fromJson(data['user']);
      await _saveSession(user);
      return {'user': user, 'session': data['session']};
    } else {
      throw Exception('Failed to sign in');
    }
  }

  static Future<void> signOut() async {
    // Inform the backend to invalidate the session/token if necessary
    // await http.post(Uri.parse('$_backendUrl/auth/signout'));
    await _clearSession();
  }

  static Future<UserModel?> getCurrentUserProfile() async {
    if (currentUserId == null) return null;

    final response = await http.get(Uri.parse('$_backendUrl/users/$currentUserId'));

    if (response.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(response.body));
    } else {
      return null;
    }
  }

  static Future<void> updateProfile({
    String? fullName,
    String? bio,
    String? profileImageUrl,
  }) async {
    if (currentUserId == null) throw Exception('No authenticated user');

    final response = await http.put(
      Uri.parse('$_backendUrl/users/$currentUserId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'full_name': fullName,
        'bio': bio,
        'profile_image_url': profileImageUrl,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update profile');
    }
  }
}
