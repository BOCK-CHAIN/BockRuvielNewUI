import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  final PageController _pageController = PageController();
  final List<Map<String, String>> reels = [
    {
      "video": "assets/reels/reel1.mp4",
      "username": "drumzzzzz",
      "caption": "Tame Impala Cover",
      "music": "Tame Impala - Loser"
    },
    {
      "video": "assets/reels/reel2.mp4",
      "username": "Mix_tapes",
      "caption": "joji x weeknd mashup",
      "music": "original"
    },
    {
      "video": "assets/reels/reel3.mp4",
      "username": "squid_game",
      "caption": "Front man,so cool",
      "music": "squid_game_music"
    },
    {
      "video": "assets/reels/reel4.mp4",
      "username": "wwe",
      "caption": "Winning moments 🏆,brock whooo...??",
      "music": "Victory tune"
    },
    {
      "video": "assets/reels/reel5.mp4",
      "username": "GOT",
      "caption": "Acting on its peak, tyrion lannister😎",
      "music": "Original audio 🎶 "
    },
    {
      "video": "assets/reels/reel3.mp4",
      "username": "marvel",
      "caption": "some sad lines from marvel",
      "music": "sad music"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: reels.length,
        itemBuilder: (context, index) {
          final reel = reels[index];
          return ReelPlayer(
            videoPath: reel["video"]!,
            username: reel["username"]!,
            caption: reel["caption"]!,
            music: reel["music"]!,
          );
        },
      ),
    );
  }
}

class ReelPlayer extends StatefulWidget {
  final String videoPath;
  final String username;
  final String caption;
  final String music;

  const ReelPlayer({
    super.key,
    required this.videoPath,
    required this.username,
    required this.caption,
    required this.music,
  });

  @override
  State<ReelPlayer> createState() => _ReelPlayerState();
}

class _ReelPlayerState extends State<ReelPlayer> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(widget.videoPath)
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 🔹 Video background
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

        Positioned(
          bottom: 20,
          left: 16,
          right: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "@${widget.username}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.caption,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.music_note, color: Colors.white, size: 16),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      widget.music,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const Positioned(
          bottom: 100,
          right: 12,
          child: Column(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: AssetImage("assets/images/logo.png"),
              ),
              SizedBox(height: 30),
              Icon(Icons.favorite_border, color: Colors.white, size: 36),
              SizedBox(height: 30),
              Icon(Icons.comment_outlined, color: Colors.white, size: 36),
              SizedBox(height: 30),
              Icon(Icons.send, color: Colors.white, size: 36),
              SizedBox(height: 30),
              Icon(Icons.more_vert, color: Colors.white, size: 30),
            ],
          ),
        ),
      ],
    );
  }
}
