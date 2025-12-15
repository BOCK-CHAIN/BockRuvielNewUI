import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthService {
  final _supabase = Supabase.instance.client;

  Stream<User?> get authStateChanges => _supabase.auth.onAuthStateChange.map(
        (data) => data.session?.user,
      );

  User? get currentUser => _supabase.auth.currentUser;

  Future<void> signUp({
    required String email,
    required String password,
    required String username,
    String? fullName,
  }) async {
    await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'username': username,
        'full_name': fullName,
      },
    );
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<UserModel?> getCurrentUserProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return null;
    }
    return UserModel(
      id: user.id,
      username: user.userMetadata?['username'] ?? '',
      email: user.email ?? '',
      fullName: user.userMetadata?['full_name'],
      bio: user.userMetadata?['bio'],
      profileImageUrl: user.userMetadata?['profile_image_url'],
    );
  }

  Future<void> updateProfile({
    String? fullName,
    String? bio,
    String? profileImageUrl,
  }) async {
    await _supabase.auth.updateUser(
      UserAttributes(
        data: {
          'full_name': fullName,
          'bio': bio,
          'profile_image_url': profileImageUrl,
        },
      ),
    );
  }
}
