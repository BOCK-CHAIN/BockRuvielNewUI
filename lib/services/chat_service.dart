import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/message_model.dart';

class ChatService {
  static const String _backendUrl = 'http://localhost:3000/api';

  static Future<List<MessageModel>> getMessages(String chatId) async {
    final response = await http.get(Uri.parse('$_backendUrl/messages?chatId=$chatId'));

    if (response.statusCode == 200) {
      final List<dynamic> messagesJson = jsonDecode(response.body);
      return messagesJson.map((json) => MessageModel.fromJson(json)).toList();
    } else {
      return [];
    }
  }

  static Future<void> sendMessage(String chatId, String userId, String content) async {
    await http.post(
      Uri.parse('$_backendUrl/messages'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'chatId': chatId, 'userId': userId, 'content': content}),
    );
  }
}
