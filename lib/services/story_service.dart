import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../models/story_model.dart';
import 'auth_service.dart';

class StoryService {
  final String _backendUrl = 'http://localhost:3000/api';
  final AuthService _authService = AuthService();

  Future<String?> _getUserId() async {
    return await _authService.currentUserId;
  }

  Future<List<StoryModel>> getStories() async {
    final response = await http.get(Uri.parse('$_backendUrl/stories'));

    if (response.statusCode == 200) {
      final List<dynamic> storiesJson = jsonDecode(response.body);
      return storiesJson.map((json) => StoryModel.fromJson(json)).toList();
    } else {
      return [];
    }
  }

  Future<void> uploadStory(XFile file, String storyType) async {
    final userId = await _getUserId();
    if (userId == null) {
      throw Exception('User not logged in');
    }
    final request = http.MultipartRequest('POST', Uri.parse('$_backendUrl/stories'));
    request.files.add(await http.MultipartFile.fromPath('story', file.path));
    request.fields['storyType'] = storyType;
    request.fields['userId'] = userId;

    await request.send();
  }
}
