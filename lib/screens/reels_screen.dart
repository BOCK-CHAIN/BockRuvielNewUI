import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/reel_model.dart';
import '../services/reel_service.dart';

class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  late Future<List<ReelModel>> _reelsFuture;

  @override
  void initState() {
    super.initState();
    _reelsFuture = ReelService.fetchReels();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<List<ReelModel>>(
        future: _reelsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                snapshot.error.toString(),
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          final reels = snapshot.data!;
          if (reels.isEmpty) {
            return const Center(
              child: Text('No reels yet', style: TextStyle(color: Colors.white)),
            );
          }

          return PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: reels.length,
            itemBuilder: (_, index) {
              return ReelPlayer(reel: reels[index]);
            },
          );
        },
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

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.network(widget.reel.videoUrl)
      ..initialize().then((_) {
        setState(() {});
        _controller
          ..setLooping(true)
          ..play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 🎥 VIDEO
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

        // 📄 TEXT INFO
        Positioned(
          bottom: 20,
          left: 16,
          right: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "@${widget.reel.username}",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.reel.caption ?? '',
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 6),
              if (widget.reel.music != null)
                Row(
                  children: [
                    const Icon(Icons.music_note,
                        color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.reel.music!,
                        style:
                            const TextStyle(color: Colors.white70, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),

        // ❤️ ACTIONS
        Positioned(
          bottom: 100,
          right: 12,
          child: Column(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundImage: AssetImage("assets/images/logo.png"),
              ),
              const SizedBox(height: 30),
              Icon(
                widget.reel.isLiked
                    ? Icons.favorite
                    : Icons.favorite_border,
                color: widget.reel.isLiked ? Colors.red : Colors.white,
                size: 36,
              ),
              const SizedBox(height: 6),
              Text(
                widget.reel.likesCount.toString(),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 30),
              const Icon(Icons.comment_outlined,
                  color: Colors.white, size: 36),
              const SizedBox(height: 6),
              Text(
                widget.reel.commentsCount.toString(),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 30),
              const Icon(Icons.send, color: Colors.white, size: 36),
            ],
          ),
        ),
      ],
    );
  }
}
