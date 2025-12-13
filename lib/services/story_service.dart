import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import '../models/story_model.dart';
import 'auth_service.dart';

class StoryService {
  static const String _backendUrl = 'http://localhost:3000/api';

  static Future<String?> uploadStoryMedia({
    Uint8List? mediaBytes,
    File? mediaFile,
    required String userId,
    required bool isVideo,
  }) async {
    try {
      final url = Uri.parse('$_backendUrl/stories/upload');
      final request = http.MultipartRequest('POST', url);
      request.fields['userId'] = userId;
      request.fields['isVideo'] = isVideo.toString();

      if (kIsWeb && mediaBytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'media',
          mediaBytes,
          filename: 'story.jpg', // Dummy filename
          contentType: MediaType('image', 'jpeg'),
        ));
      } else if (!kIsWeb && mediaFile != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'media',
          mediaFile.path,
          contentType: MediaType(isVideo ? 'video' : 'image', isVideo ? 'mp4' : 'jpeg'),
        ));
      }

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        return jsonDecode(responseBody)['url'];
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('❌ Story media upload failed: $e');
      return null;
    }
  }

  static Future<StoryModel?> createStory({
    Uint8List? imageBytes,
    File? imageFile,
    Uint8List? videoBytes,
    File? videoFile,
    String? caption,
  }) async {
    try {
      final userId = AuthService.currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      String? imageUrl;
      String? videoUrl;

      if (imageBytes != null || imageFile != null) {
        imageUrl = await uploadStoryMedia(
          mediaBytes: imageBytes,
          mediaFile: imageFile,
          userId: userId,
          isVideo: false,
        );
      }

      if (videoBytes != null || videoFile != null) {
        videoUrl = await uploadStoryMedia(
          mediaBytes: videoBytes,
          mediaFile: videoFile,
          userId: userId,
          isVideo: true,
        );
      }

      if ((imageUrl == null || imageUrl.isEmpty) &&
          (videoUrl == null || videoUrl.isEmpty)) {
        throw Exception('No media provided');
      }

      final response = await http.post(
        Uri.parse('$_backendUrl/stories'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'imageUrl': imageUrl,
          'videoUrl': videoUrl,
          'caption': caption,
        }),
      );

      if (response.statusCode == 201) {
        return StoryModel.fromJson(jsonDecode(response.body));
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error creating story: $e');
      return null;
    }
  }

  static Future<Map<String, List<StoryModel>>> fetchFollowingStories() async {
    try {
      final userId = AuthService.currentUserId;
      if (userId == null) return {};

      final response = await http.get(
        Uri.parse('$_backendUrl/stories/following/$userId'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> storiesJson = jsonDecode(response.body);
        return storiesJson.map((key, value) {
          final stories = (value as List).map((storyJson) => StoryModel.fromJson(storyJson)).toList();
          return MapEntry(key, stories);
        });
      } else {
        return {};
      }
    } catch (e) {
      debugPrint('❌ Error fetching stories: $e');
      return {};
    }
  }

  static Future<List<StoryModel>> fetchUserStories(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_backendUrl/stories/user/$userId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> storiesJson = jsonDecode(response.body);
        return storiesJson.map((json) => StoryModel.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error fetching user stories: $e');
      return [];
    }
  }
}
