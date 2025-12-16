// ignore_for_file: use_build_context_synchronously

import 'dart:typed_data';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../utils/image_picker_stub.dart'
    if (dart.library.html) '../utils/image_picker_web.dart';
import '../services/post_service.dart';

class TweetFeedScreen extends StatefulWidget {
  const TweetFeedScreen({super.key});

  @override
  State<TweetFeedScreen> createState() => _TweetFeedScreenState();
}

class _TweetFeedScreenState extends State<TweetFeedScreen> {
  final PostService _postService = PostService();
  final TextEditingController _tweetController = TextEditingController();
  File? _selectedImageFile;
  Uint8List? _selectedImageBytes;

  final List<Map<String, dynamic>> _tweets = [];

  @override
  void initState() {
    super.initState();
    _loadTweets();
  }

  // ✅ Load all tweets from Supabase
  Future<void> _loadTweets() async {
    // Only fetch Twitter posts
    final posts = await _postService.fetchPosts(postType: 'twitter');
    setState(() {
      _tweets
        ..clear()
        ..addAll(posts.map((post) => {
              "id": post.id,
              "username": post.username,
              "tweet": post.caption ?? "",
              "likes": post.likesCount,
              "liked": post.isLiked,
              "comments": <Map<String, dynamic>>[],
              "reposts": 0,
              "image": post.imageUrl,
              "isLocal": false,
              "isWeb": true,
            }));
    });
  }

  // ✅ Pick image (supports web + mobile)
  Future<void> _pickImage() async {
    final result = await ImagePickerHelper.pickImage();
    if (result == null) return;

    setState(() {
      if (result["isWeb"]) {
        _selectedImageBytes = result["bytes"];
        _selectedImageFile = null;
      } else {
        _selectedImageFile = result["file"];
        _selectedImageBytes = null;
      }
    });
  }

  // ✅ Create post on Supabase
  Future<void> _addTweet() async {
    if (_tweetController.text.trim().isEmpty &&
        _selectedImageFile == null &&
        _selectedImageBytes == null) return;

    await _postService.createPost(
      caption: _tweetController.text.trim(),
      imageBytes: _selectedImageBytes,
      imageFile: _selectedImageFile,
      postType: 'twitter',
    );

    await _loadTweets();

    setState(() {
      _tweetController.clear();
      _selectedImageFile = null;
      _selectedImageBytes = null;
    });
  }

  // ✅ Toggle Like (with smooth animation + instant UI update)
  Future<void> _toggleLike(int index) async {
    final tweet = _tweets[index];
    final wasLiked = tweet["liked"] == true;
    final postId = tweet["id"]?.toString();

    // ✅ Optimistic UI update (instant feedback)
    setState(() {
      tweet["liked"] = !wasLiked;
      tweet["likes"] = (tweet["likes"] ?? 0) + (wasLiked ? -1 : 1);
    });

    // ✅ Backend call (safe to fail silently for demo)
    try {
      if (postId != null && postId.isNotEmpty) {
        await _postService.toggleLike(postId);
      }
    } catch (e) {
      // Revert UI if backend fails
      if (mounted) {
        setState(() {
          tweet["liked"] = wasLiked;
          tweet["likes"] = (tweet["likes"] ?? 0) + (wasLiked ? 1 : -1);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update like: $e")),
        );
      }
    }
  }

  // ✅ Add a comment
  Future<void> _addComment(int index, String comment) async {
    if (comment.trim().isEmpty) return;

    final postId = _tweets[index]["id"]?.toString();
    if (postId == null) return;

    final newComment = await _postService.addComment(postId, comment);

    if (newComment != null && mounted) {
      setState(() {
        _tweets[index]["comments"].add({
          "comment": newComment.comment,
          "username": newComment.username,
        });
      });
    }
  }

  // ✅ Show comments modal
  void _showComments(BuildContext context, int index) {
    final TextEditingController commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              final comments = _tweets[index]["comments"] ?? [];

              return SizedBox(
                height: 400,
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      height: 4,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Comments",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Divider(),
                    Expanded(
                      child: ListView.builder(
                        itemCount: comments.length,
                        itemBuilder: (context, i) {
                          final comment = comments[i];
                          return ListTile(
                            leading: const CircleAvatar(
                              backgroundImage:
                                  AssetImage("assets/images/story1.jpg"),
                            ),
                            title: Text(
                              comment["comment"] ??
                                  comment["text"] ??
                                  "No comment",
                              style: const TextStyle(fontSize: 14),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: commentController,
                              decoration: const InputDecoration(
                                hintText: "Add a comment...",
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              await _addComment(
                                  index, commentController.text.trim());
                              commentController.clear();
                              setModalState(() {}); // refresh modal
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                            ),
                            child: const Text("Post"),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ✅ Display tweet image
  Widget _buildImage(dynamic image, bool isLocal, {bool isWeb = false}) {
    if (image == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          image,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const SizedBox(),
        ),
      ),
    );
  }

  // ✅ UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Threads / Tweets",
            style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      backgroundImage: AssetImage("assets/images/story1.jpg"),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _tweetController,
                        decoration: const InputDecoration(
                          hintText: "What's happening?",
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _addTweet,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text("Post",
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
                if (_selectedImageFile != null || _selectedImageBytes != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Stack(
                      alignment: Alignment.topRight,
                      children: [
                        if (kIsWeb && _selectedImageBytes != null)
                          Image.memory(_selectedImageBytes!,
                              height: 150, fit: BoxFit.contain)
                        else if (!kIsWeb && _selectedImageFile != null)
                          Image.file(_selectedImageFile!,
                              height: 150, fit: BoxFit.contain),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => setState(() {
                            _selectedImageFile = null;
                            _selectedImageBytes = null;
                          }),
                        ),
                      ],
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    TextButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image, color: Colors.blue),
                      label: const Text("Add Image",
                          style: TextStyle(color: Colors.blue)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadTweets,
              child: ListView.builder(
                itemCount: _tweets.length,
                itemBuilder: (context, index) {
                  final tweet = _tweets[index];
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                radius: 20,
                                backgroundImage:
                                    AssetImage("assets/images/story1.jpg"),
                              ),
                              const SizedBox(width: 10),
                              Text(tweet["username"],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(tweet["tweet"],
                              style: const TextStyle(fontSize: 16)),
                          _buildImage(tweet["image"], tweet["isLocal"],
                              isWeb: tweet["isWeb"] ?? false),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              // ❤️ Like button with smooth animation
                              IconButton(
                                onPressed: () => _toggleLike(index),
                                icon: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  transitionBuilder: (child, anim) =>
                                      ScaleTransition(
                                          scale: anim, child: child),
                                  child: Icon(
                                    tweet["liked"]
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    key: ValueKey(tweet["liked"]),
                                    color: tweet["liked"]
                                        ? Colors.red
                                        : Colors.black,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.chat_bubble_outline),
                                onPressed: () => _showComments(context, index),
                              ),
                              IconButton(
                                icon: const Icon(Icons.repeat),
                                onPressed: () {},
                              ),
                            ],
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              "${tweet["likes"]} likes · ${tweet["comments"].length} comments · ${tweet["reposts"]} reposts",
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
  