import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../models/reel_model.dart';
import '../services/reel_service.dart';

class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  final PageController _pageController = PageController();
  final FocusNode _focusNode = FocusNode();
  List<ReelModel> reels = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadReels();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> loadReels() async {
    reels = await ReelService.getReels();
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: (KeyEvent event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              if (_pageController.page != null && _pageController.page! < reels.length - 1) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              if (_pageController.page != null && _pageController.page! > 0) {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            }
          }
        },
        child: PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          itemCount: reels.length,
          itemBuilder: (_, i) => ReelPlayer(reel: reels[i]),
        ),
      ),
    );
  }
}

class ReelPlayer extends StatefulWidget {
  final ReelModel reel;
  const ReelPlayer({super.key, required this.reel});

  @override
  State<ReelPlayer> createState() => _ReelPlayerState();
}

class _ReelPlayerState extends State<ReelPlayer> {
  late VideoPlayerController _controller;
  bool _showControls = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.reel.videoUrl)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
        _controller.setLooping(true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showCommentsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => CommentsBottomSheet(reelId: widget.reel.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showControls = !_showControls;
        });
        
        if (_controller.value.isPlaying) {
          _controller.pause();
        } else {
          _controller.play();
        }
        
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _showControls = false;
            });
          }
        });
      },
      child: Stack(children: [
        _controller.value.isInitialized
            ? SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller.value.size.width,
                    height: _controller.value.size.height,
                    child: VideoPlayer(_controller),
                  ),
                ),
              )
            : const Center(child: CircularProgressIndicator()),

        // Play/Pause indicator
        if (_showControls && _controller.value.isInitialized)
          Positioned.fill(
            child: Center(
              child: Icon(
                _controller.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                color: Colors.white.withOpacity(0.7),
                size: 80,
              ),
            ),
          ),

        Positioned(
          bottom: 20,
          left: 16,
          right: 80,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('@${widget.reel.username}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            if (widget.reel.caption != null)
              Text(widget.reel.caption!, style: const TextStyle(color: Colors.white)),
            if (widget.reel.music != null)
              Text(widget.reel.music!, style: const TextStyle(color: Colors.white70)),
          ]),
        ),

        Positioned(
          right: 12,
          bottom: 100,
          child: Column(children: [
            IconButton(
              icon: Icon(widget.reel.isLiked ? Icons.favorite : Icons.favorite_border, color: Colors.white, size: 32),
              onPressed: () async {
                if (widget.reel.isLiked) {
                  await ReelService.unlike(widget.reel.id);
                  widget.reel.isLiked = false;
                  widget.reel.likesCount--;
                } else {
                  await ReelService.like(widget.reel.id);
                  widget.reel.isLiked = true;
                  widget.reel.likesCount++;
                }
                setState(() {});
              },
            ),
            Text('${widget.reel.likesCount}', style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 16),
            IconButton(
              icon: const Icon(Icons.comment_outlined, color: Colors.white, size: 32),
              onPressed: () => _showCommentsBottomSheet(context),
            ),
            Text('${widget.reel.commentsCount}', style: const TextStyle(color: Colors.white))
          ]),
        )
      ]),
    );
  }
}

class CommentsBottomSheet extends StatefulWidget {
  final String reelId;
  
  const CommentsBottomSheet({super.key, required this.reelId});

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  List<Map<String, dynamic>> comments = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    try {
      final fetchedComments = await ReelService.getComments(widget.reelId);
      setState(() {
        comments = fetchedComments;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
    }
  }

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty) return;
    
    try {
      await ReelService.addComment(widget.reelId, _commentController.text.trim());
      _commentController.clear();
      await _loadComments();
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Comments header
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Comments',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Comments list
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : comments.isEmpty
                    ? const Center(
                        child: Text(
                          'No comments yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final comment = comments[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Profile image
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.grey[600],
                                  child: comment['profiles'] != null
                                      ? ClipOval(
                                          child: Image.network(
                                            comment['profiles']['profile_image_url'] ?? '',
                                            width: 40,
                                            height: 40,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                width: 40,
                                                height: 40,
                                                color: Colors.grey[600],
                                                child: const Icon(Icons.person, color: Colors.white),
                                              );
                                            },
                                          ),
                                        )
                                      : const Icon(Icons.person, color: Colors.white),
                                ),
                                const SizedBox(width: 12),
                                
                                // Comment content
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        comment['profiles']?['username'] ?? 'Unknown',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        comment['comment'] ?? '',
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
          
          // Comment input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              border: Border(top: BorderSide(color: Colors.grey[700]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _postComment,
                  icon: const Icon(Icons.send, color: Colors.blue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}