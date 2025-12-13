import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/story_model.dart';
import '../services/story_service.dart';
import '../widgets/story_progress_bar.dart';

class StoryViewerScreen extends StatefulWidget {
  final List<StoryModel> stories;
  final int initialIndex;
  final String userId;

  const StoryViewerScreen({
    super.key,
    required this.stories,
    this.initialIndex = 0,
    required this.userId,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late int _currentIndex;
  late AnimationController _animationController;
  VideoPlayerController? _videoController;
  bool _isPaused = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addStatusListener(_onAnimationEnd);

    _loadStory(story: widget.stories[_currentIndex]);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  void _loadStory({required StoryModel story}) async {
    setState(() => _isLoading = true);
    _animationController.stop();
    _animationController.reset();

    // Dispose previous video controller if any
    _videoController?.dispose();
    _videoController = null;

    if (story.mediaUrl.endsWith('.mp4')) {
      _videoController = VideoPlayerController.network(story.mediaUrl)
        ..initialize().then((_) {
          setState(() => _isLoading = false);
          _videoController?.play();
          _animationController.duration = _videoController?.value.duration;
          _animationController.forward();
        });
    } else {
      setState(() => _isLoading = false);
      _animationController.forward();
    }
  }

  void _onAnimationEnd(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _animationController.stop();
      _animationController.reset();
      
      if (_currentIndex < widget.stories.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        Navigator.of(context).pop();
      }
    }
  }

  void _onPageChanged(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      _loadStory(story: widget.stories[_currentIndex]);
    }
  }

  void _onTapDown(TapDownDetails details) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double tapPosition = details.globalPosition.dx;
    
    if (tapPosition < screenWidth / 3) {
      // Tap on left side - go to previous story
      if (_currentIndex > 0) {
        _pageController.previousPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        Navigator.of(context).pop();
      }
    } else if (tapPosition > screenWidth * 2 / 3) {
      // Tap on right side - go to next story
      if (_currentIndex < widget.stories.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        Navigator.of(context).pop();
      }
    } else {
      // Tap in the middle - toggle pause/play
      setState(() {
        _isPaused = !_isPaused;
        if (_isPaused) {
          _animationController.stop();
          _videoController?.pause();
        } else {
          _animationController.forward();
          _videoController?.play();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Story Content
          GestureDetector(
            onTapDown: _onTapDown,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: widget.stories.length,
              itemBuilder: (context, index) {
                final story = widget.stories[index];
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    if (story.mediaUrl.endsWith('.mp4'))
                      _videoController != null &&
                              _videoController!.value.isInitialized
                          ? AspectRatio(
                              aspectRatio: _videoController!.value.aspectRatio,
                              child: VideoPlayer(_videoController!),
                            )
                          : const Center(child: CircularProgressIndicator())
                    else
                      Image.network(
                        story.mediaUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(child: CircularProgressIndicator());
                        },
                      ),
                    
                    // Story caption
                    if (story.caption != null && story.caption!.isNotEmpty)
                      Positioned(
                        bottom: 24.0,
                        left: 16.0,
                        right: 16.0,
                        child: Text(
                          story.caption!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16.0,
                            shadows: [
                              Shadow(
                                color: Colors.black,
                                offset: Offset(1, 1),
                                blurRadius: 3.0,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          
          // Progress bars
          Positioned(
            top: MediaQuery.of(context).padding.top + 8.0,
            left: 8.0,
            right: 8.0,
            child: Row(
              children: List.generate(
                widget.stories.length,
                (i) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: StoryProgressBar(
                      animationController: i == _currentIndex
                          ? _animationController
                          : AnimationController(
                              vsync: this,
                              duration: const Duration(seconds: 5),
                              value: i < _currentIndex ? 1.0 : 0.0,
                            ),
                      color: i < _currentIndex
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Close button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16.0,
            left: 16.0,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 32.0),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          
          // Loading indicator
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
            ),
        ],
      ),
    );
  }
}

class StoryProgressBar extends StatelessWidget {
  final AnimationController animationController;
  final Color color;

  const StoryProgressBar({
    super.key,
    required this.animationController,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        return LinearProgressIndicator(
          value: animationController.value,
          backgroundColor: color.withOpacity(0.3),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 2.0,
        );
      },
    );
  }
}
