import 'dart:io' show File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../config/supabase_config.dart';
import 'profile_service.dart';

class AuthService {
  static final _client = Supabase.instance.client;

  /// Get current authenticated user
  static User? get currentUser => _client.auth.currentUser;

  /// Check if user is authenticated
  static bool get isAuthenticated => currentUser != null;

  /// Get current user ID
  static String? get currentUserId => currentUser?.id;

  /// Sign up with email and password
  static Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String username,
    String? fullName,
  }) async {
    try {
      // Sign up with Supabase Auth
      // The trigger will automatically create the profile
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'username': username,
          'full_name': fullName ?? '',
        },
      );

      if (response.user == null) {
        throw Exception('Failed to create user');
      }

      // Wait a bit for the trigger to complete
      await Future.delayed(const Duration(milliseconds: 500));

      // Verify profile was created, if not create it manually via backend
      try {
        final profileExists = await ProfileService.profileExists(response.user!.id);

        if (!profileExists) {
          // Fallback: manually create profile if trigger didn't work
          try {
            await ProfileService.createProfile(
              id: response.user!.id,
              email: email,
              username: username,
              fullName: fullName,
            );
          } catch (e) {
            debugPrint('❌ Manual profile creation failed: $e');
            // If profile creation fails, still return success if user was created
            // User can update profile later
          }
        }
      } catch (profileError) {
        debugPrint('⚠️ Profile creation check failed: $profileError');
        // Continue with signup flow even if profile check fails
      }

      return {
        'user': response.user,
        'session': response.session,
      };
    } catch (e) {
      debugPrint('❌ Sign up error: $e');
      rethrow;
    }
  }

  /// Sign in with email and password
  static Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null || response.session == null) {
        throw Exception('Invalid credentials');
      }

      return {
        'user': response.user,
        'session': response.session,
      };
    } catch (e) {
      debugPrint('❌ Sign in error: $e');
      rethrow;
    }
  }

  /// Sign out
  static Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      debugPrint('❌ Sign out error: $e');
      rethrow;
    }
  }

  /// Get current user profile
  static Future<UserModel?> getCurrentUserProfile() async {
    return await ProfileService.getCurrentProfile();
  }

  static Future<UserModel?> getUserProfileById(String userId) async {
    return await ProfileService.getUserProfileById(userId);
  }

  /// Update user profile
  static Future<void> updateProfile({
    String? fullName,
    String? bio,
    String? profileImageUrl,
  }) async {
    await ProfileService.updateProfile(
      fullName: fullName,
      bio: bio,
    );
  }

  /// Upload profile image to Supabase Storage and return public URL
  static Future<String?> uploadProfileImage({
    Uint8List? imageBytes,
    File? imageFile,
  }) async {
    return await ProfileService.uploadProfileImage(
      imageBytes: imageBytes,
      imageFile: imageFile,
    );
  }

  /// Stream auth state changes
  static Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}
