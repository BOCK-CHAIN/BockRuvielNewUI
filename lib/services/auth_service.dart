import 'dart:io' show File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../config/supabase_config.dart';

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

      // Verify profile was created, if not create it manually
      try {
        final profileExists = await _client
            .from('profiles')
            .select('id')
            .eq('id', response.user!.id)
            .maybeSingle();

        if (profileExists == null) {
          // Fallback: manually create profile if trigger didn't work
          await _client.from('profiles').insert({
            'id': response.user!.id,
            'email': email,
            'username': username,
            'full_name': fullName,
            'followers_count': 0,
            'following_count': 0,
            'posts_count': 0,
          });
        }
      } catch (profileError) {
        debugPrint('⚠️ Profile creation check failed: $profileError');
        // Try to create profile manually as fallback
        try {
          await _client.from('profiles').insert({
            'id': response.user!.id,
            'email': email,
            'username': username,
            'full_name': fullName,
            'followers_count': 0,
            'following_count': 0,
            'posts_count': 0,
          });
        } catch (e) {
          debugPrint('❌ Manual profile creation also failed: $e');
          // If profile creation fails, still return success if user was created
          // User can update profile later
        }
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
    try {
      if (currentUserId == null) return null;

      final response = await _client
          .from('profiles')
          .select()
          .eq('id', currentUserId!)
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      debugPrint('❌ Get profile error: $e');
      return null;
    }
  }

  /// Update user profile
  static Future<void> updateProfile({
    String? fullName,
    String? bio,
    String? profileImageUrl,
  }) async {
    try {
      if (currentUserId == null) {
        throw Exception('No authenticated user');
      }

      final updates = <String, dynamic>{};
      if (fullName != null) updates['full_name'] = fullName;
      if (bio != null) updates['bio'] = bio;
      if (profileImageUrl != null) updates['profile_image_url'] = profileImageUrl;
      updates['updated_at'] = DateTime.now().toIso8601String();

      await _client
          .from('profiles')
          .update(updates)
          .eq('id', currentUserId!);
    } catch (e) {
      debugPrint('❌ Update profile error: $e');
      rethrow;
    }
  }

  /// Upload profile image to Supabase Storage and return public URL
  static Future<String?> uploadProfileImage({
    Uint8List? imageBytes,
    File? imageFile,
  }) async {
    try {
      if (currentUserId == null) {
        throw Exception('No authenticated user');
      }

      final storagePath =
          'avatars/${currentUserId!}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      if (kIsWeb && imageBytes != null) {
        await _client.storage
            .from(SupabaseConfig.profilesBucket)
            .uploadBinary(storagePath, imageBytes,
                fileOptions: const FileOptions(upsert: true));
      } else if (!kIsWeb && imageFile != null) {
        await _client.storage
            .from(SupabaseConfig.profilesBucket)
            .upload(storagePath, imageFile,
                fileOptions: const FileOptions(upsert: true));
      } else {
        throw Exception('No image data provided');
      }

      final publicUrl = _client.storage
          .from(SupabaseConfig.profilesBucket)
          .getPublicUrl(storagePath);

      // Persist to profile
      await updateProfile(profileImageUrl: publicUrl);

      return publicUrl;
    } catch (e) {
      debugPrint('❌ Upload profile image error: $e');
      return null;
    }
  }

  /// Stream auth state changes
  static Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}
