import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';


class ChatService {
  static final _client = Supabase.instance.client;

  /// Send message to a receiver
  static Future<MessageModel?> sendMessage(String receiverId, String message) async {
    try {
      final senderId = AuthService.currentUserId;
      if (senderId == null) throw Exception('User not authenticated');

      if (message.trim().isEmpty) {
        throw Exception('Message cannot be empty');
      }

      final messageId = DateTime.now().millisecondsSinceEpoch.toString();

      final response = await _client.from('messages').insert({
        'id': messageId,
        'sender_id': senderId,
        'receiver_id': receiverId,
        'message': message.trim(),
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      }).select().single();

      return MessageModel.fromJson(response);
    } catch (e) {
      debugPrint('❌ Error sending message: $e');
      return null;
    }
  }

  /// Fetch all messages between current user and another user
  static Future<List<MessageModel>> fetchMessages(String otherUserId) async {
    try {
      final currentUserId = AuthService.currentUserId;
      if (currentUserId == null) return [];

      final response = await _client
          .from('messages')
          .select()
          .or(
            'and(sender_id.eq.$currentUserId,receiver_id.eq.$otherUserId),'
            'and(sender_id.eq.$otherUserId,receiver_id.eq.$currentUserId)',
          )
          .order('created_at', ascending: true);

      return (response as List)
          .map((json) => MessageModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching messages: $e');
      return [];
    }
  }

  /// Mark messages as read
  static Future<void> markMessagesAsRead(String senderId) async {
    try {
      final currentUserId = AuthService.currentUserId;
      if (currentUserId == null) return;

      await _client
          .from('messages')
          .update({'is_read': true})
          .eq('sender_id', senderId)
          .eq('receiver_id', currentUserId)
          .eq('is_read', false);
    } catch (e) {
      debugPrint('❌ Error marking messages as read: $e');
    }
  }

  /// Subscribe to new messages in real-time
  static RealtimeChannel? subscribeToMessages(
    String otherUserId,
    void Function(MessageModel) onNewMessage,
  ) {
    final currentUserId = AuthService.currentUserId;
    if (currentUserId == null) {
      debugPrint('❌ Cannot subscribe: User not authenticated');
      return null;
    }

    try {
      final channel = _client
          .channel('messages_channel_${currentUserId}_$otherUserId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'messages',
            callback: (payload) {
              final msg = payload.newRecord;
              if (msg != null && msg is Map<String, dynamic>) {
                final message = MessageModel.fromJson(msg);
                // Only process messages relevant to this chat
                if ((message.senderId == otherUserId && message.receiverId == currentUserId) ||
                    (message.senderId == currentUserId && message.receiverId == otherUserId)) {
                  onNewMessage(message);
                  // Mark as read automatically if received
                  if (message.receiverId == currentUserId) {
                    markMessagesAsRead(otherUserId);
                  }
                }
              }
            },
          )
          .subscribe();

      return channel;
    } catch (e) {
      debugPrint('❌ Error subscribing to messages: $e');
      return null;
    }
  }

    /// Get list of conversations (users you've messaged or who messaged you)
    static Future<List<Map<String, dynamic>>> getConversations() async {
    try {
      final currentUserId = AuthService.currentUserId;
      if (currentUserId == null) return [];

      final response = await _client
          .from('messages')
          .select('''
            sender_id,
            receiver_id,
            message,
            created_at,
            is_read,
            sender:profiles!messages_sender_id_fkey(
              username,
              profile_image_url
            ),
            receiver:profiles!messages_receiver_id_fkey(
              username,
              profile_image_url
            )
          ''')
          .or('sender_id.eq.$currentUserId,receiver_id.eq.$currentUserId')
          .order('created_at', ascending: false);

      final Map<String, Map<String, dynamic>> conversations = {};

      for (var msg in response) {
        final partnerId = msg['sender_id'] == currentUserId
            ? msg['receiver_id'] as String
            : msg['sender_id'] as String;

        final partnerProfile = msg['sender_id'] == currentUserId
            ? msg['receiver']
            : msg['sender'];

        conversations.putIfAbsent(partnerId, () {
          return {
            'user_id': partnerId,
            'username': partnerProfile?['username'] ?? 'Unknown',
            'profile_image_url': partnerProfile?['profile_image_url'],
            'last_message': msg['message'],
            'last_message_time': msg['created_at'],
            'unread_count': 0,
          };
        });

        if (msg['sender_id'] != currentUserId && !msg['is_read']) {
          conversations[partnerId]!['unread_count'] =
              (conversations[partnerId]!['unread_count'] as int) + 1;
        }
      }

      return conversations.values.toList();
    } catch (e) {
      debugPrint('❌ Error fetching conversations: $e');
      return [];
    }
  }
  static Future<List<UserModel>> getAllUsers() async {
  try {
    final currentUserId = AuthService.currentUserId;
    if (currentUserId == null) return [];

    final response = await _client
        .from('profiles')
        .select('id, username, profile_image_url')
        .neq('id', currentUserId);

    return (response as List).map((u) {
      return UserModel(
        id: u['id'],
        email: '',
        username: u['username'],
        profileImageUrl: u['profile_image_url'],
        createdAt: DateTime.now(),
      );
    }).toList();
  } catch (e) {
    debugPrint('❌ Error fetching users: $e');
    return [];
  }
}


}
