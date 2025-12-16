import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/activity_model.dart';
import 'auth_service.dart';

class ActivityService {
  final String _backendUrl = 'http://localhost:3000/api';

  Future<List<ActivityModel>> fetchActivity() async {
    final response = await http.get(Uri.parse('$_backendUrl/activity'));

    if (response.statusCode == 200) {
      final List<dynamic> activitiesJson = jsonDecode(response.body);
      return activitiesJson.map((json) => ActivityModel.fromJson(json)).toList();
    } else {
      return [];
    }
  }

  Future<void> createActivity(String type, String fromUserId, String toUserId, {String? postId}) async {
    await http.post(
      Uri.parse('$_backendUrl/activity'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String?>{
        'type': type,
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'postId': postId,
      }),
    );
  }
}
