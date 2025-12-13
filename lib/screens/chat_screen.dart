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
    TextEditingController searchController = TextEditingController();
    String searchQuery = "";

    return StatefulBuilder(
      builder: (context, setStateSB) {
        return Column(
          children: [
            // 🔎 Search Bar
            Padding(
              padding: const EdgeInsets.all(10),
              child: TextField(
                controller: searchController,
                onChanged: (value) {
                  setStateSB(() {
                    searchQuery = value.trim().toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: "Search users",
                  prefixIcon: Icon(Icons.search, color: Theme.of(context).iconTheme.color),
                  filled: true,
                  fillColor: Theme.of(context).inputDecorationTheme.fillColor ?? Theme.of(context).colorScheme.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            Expanded(
              child: FutureBuilder(
                future: ChatService.getConversations(),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final convos = snap.data as List;

                  // If no conversations exist → show ALL users
                  if (convos.isEmpty) {
                    return FutureBuilder(
                      future: ChatService.getAllUsers(),
                      builder: (context, snap2) {
                        if (!snap2.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        List<UserModel> users = snap2.data!;

                        // 🔎 Apply search filter
                        if (searchQuery.isNotEmpty) {
                          users = users
                              .where((u) =>
                                  u.username.toLowerCase().contains(searchQuery))
                              .toList();
                        }

                        if (users.isEmpty) {
                          return const Center(child: Text("No users found"));
                        }

                        return ListView.builder(
                          itemCount: users.length,
                          itemBuilder: (context, i) {
                            final user = users[i];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: user.profileImageUrl != null
                                    ? NetworkImage(user.profileImageUrl!)
                                    : const AssetImage("assets/images/story1.jpg")
                                        as ImageProvider,
                              ),
                              title: Text(
                                user.username,
                                style:
                                    const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: const Text("Start chat"),
                              onTap: () {
                                if (isLarge) {
                                  setState(() => selectedUser = user);
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ChatScreenLive(otherUser: user),
                                    ),
                                  );
                                }
                              },
                            );
                          },
                        );
                      },
                    );
                  }

                  // If conversations exist → show conversation list
                  List filteredConvos = convos;

                  // 🔎 Apply search to existing conversations
                  if (searchQuery.isNotEmpty) {
                    filteredConvos = convos.where((c) {
                      final name = c["username"]?.toLowerCase() ?? "";
                      return name.contains(searchQuery);
                    }).toList();
                  }

                  if (filteredConvos.isEmpty) {
                    return const Center(child: Text("No users match your search"));
                  }

                  return ListView.builder(
                    itemCount: filteredConvos.length,
                    itemBuilder: (context, i) {
                      final c = filteredConvos[i];

                      final user = UserModel(
                        id: c['user_id'],
                        email: '',
                        username: c['username'],
                        profileImageUrl: c['profile_image_url'],
                        createdAt: DateTime.now(),
                      );

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: user.profileImageUrl != null
                              ? NetworkImage(user.profileImageUrl!)
                              : const AssetImage("assets/images/story1.jpg")
                                  as ImageProvider,
                        ),
                        title: Text(
                          user.username,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(c['last_message'] ?? ""),
                        onTap: () {
                          if (isLarge) {
                            setState(() => selectedUser = user);
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ChatScreenLive(otherUser: user),
                              ),
                            );
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
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
  dynamic _channel;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _subscribe();
  }

  Future<void> _loadMessages() async {
    _messages =
        await ChatService.fetchMessages(widget.otherUser.id);
    setState(() {});
    _scrollToBottom();
  }

  void _subscribe() {
    _channel = ChatService.subscribeToMessages(
      widget.otherUser.id,
      (msg) {
        setState(() => _messages.add(msg));
        _scrollToBottom();
      },
    );
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

    _controller.clear();
    final msg =
        await ChatService.sendMessage(widget.otherUser.id, text);

    if (msg != null) {
      setState(() => _messages.add(msg));
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
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
