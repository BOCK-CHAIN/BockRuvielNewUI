import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../models/message_model.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  UserModel? selectedUser;

  @override
  Widget build(BuildContext context) {
    final isLarge = MediaQuery.of(context).size.width > 800;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: isLarge
          ? null
          : AppBar(
              elevation: 1,
              backgroundColor: theme.appBarTheme.backgroundColor,
              title: Text(
                "Direct Messages",
                style: theme.appBarTheme.titleTextStyle,
              ),
            ),
      body: isLarge
          ? Row(
              children: [
                SizedBox(width: 300, child: _buildConversationList(true)),
                const VerticalDivider(width: 1),
                Expanded(
                  child: selectedUser == null
                      ? const Center(
                          child: Text(
                            "Select a conversation",
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        )
                      : ChatScreenLive(
                          otherUser: selectedUser!,
                          isEmbedded: true,
                        ),
                ),
              ],
            )
          : _buildConversationList(false),
    );
  }

  Widget _buildConversationList(bool isLarge) {
    return const Center(child: Text("No conversations yet."));
  }
}

class ChatScreenLive extends StatefulWidget {
  final UserModel otherUser;
  final bool isEmbedded;

  const ChatScreenLive({
    super.key,
    required this.otherUser,
    this.isEmbedded = false,
  });

  @override
  State<ChatScreenLive> createState() => _ChatScreenLiveState();
}

class _ChatScreenLiveState extends State<ChatScreenLive> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  List<MessageModel> _messages = [];

  @override
  void initState() {
    super.initState();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final currentUserId = AuthService.currentUserId;
    if (currentUserId == null) return;

    _controller.clear();
    await ChatService.sendMessage(widget.otherUser.id, currentUserId, text);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final header = Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundImage: widget.otherUser.profileImageUrl != null
              ? NetworkImage(widget.otherUser.profileImageUrl!)
              : const AssetImage("assets/images/story1.jpg")
                  as ImageProvider,
        ),
        const SizedBox(width: 8),
        Text(widget.otherUser.username,
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );

    final input = Container(
      padding: const EdgeInsets.all(8),
      color: theme.colorScheme.surface,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: "Message...",
                filled: true,
                fillColor: theme.inputDecorationTheme.fillColor ?? theme.colorScheme.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send, color: theme.colorScheme.primary),
            onPressed: _send,
          ),
        ],
      ),
    );

    final messages = Expanded(
      child: ListView.builder(
        controller: _scroll,
        padding: const EdgeInsets.all(12),
        itemCount: _messages.length,
        itemBuilder: (context, i) {
          final msg = _messages[i];
          final isMe = msg.senderId == AuthService.currentUserId;

          return Align(
            alignment:
                isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMe
                    ? theme.colorScheme.primary.withOpacity(0.25)
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                msg.message,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          );
        },
      ),
    );

    if (widget.isEmbedded) {
      return Column(
        children: [
          Container(
              padding: const EdgeInsets.all(12), child: header),
          const Divider(height: 1),
          messages,
          input,
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 1,
        title: header,
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [messages, input],
      ),
    );
  }
}
