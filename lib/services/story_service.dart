import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../models/story_model.dart';

class StoryService {
  static const String _backendUrl = 'http://localhost:3000/api';

  static Future<List<StoryModel>> getStories() async {
    final response = await http.get(Uri.parse('$_backendUrl/stories'));

    if (response.statusCode == 200) {
      final List<dynamic> storiesJson = jsonDecode(response.body);
      return storiesJson.map((json) => StoryModel.fromJson(json)).toList();
    } else {
      return [];
    }
  }

  static Future<void> uploadStory(XFile file, String storyType) async {
    final request = http.MultipartRequest('POST', Uri.parse('$_backendUrl/stories'));
    request.files.add(await http.MultipartFile.fromPath('story', file.path));
    request.fields['storyType'] = storyType;
    request.fields['userId'] = 'YOUR_USER_ID'; // Replace with actual user ID

    await request.send();
  }
}
