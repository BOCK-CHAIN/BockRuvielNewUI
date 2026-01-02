import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/post_service.dart';
import '../services/reel_service.dart';
import '../services/auth_service.dart';
import '../utils/image_picker_stub.dart'
    if (dart.library.html) '../utils/image_picker_web.dart';

class CreatePostScreen extends StatefulWidget {
  final String postType; // 'instagram', 'twitter', or 'reel'

  const CreatePostScreen({super.key, this.postType = 'instagram'});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _musicController = TextEditingController();
  File? _selectedFile;
  Uint8List? _selectedBytes;
  bool _isPosting = false;
  bool _isVideo = false;

  @override
  void dispose() {
    _captionController.dispose();
    _musicController.dispose();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    final result = widget.postType == 'reel' 
        ? await ImagePickerHelper.pickVideo()
        : await ImagePickerHelper.pickImage();
        
    if (result == null || !mounted) return;

    setState(() {
      _isVideo = widget.postType == 'reel';
      if (result["isWeb"] == true) {
        _selectedBytes = result["bytes"] as Uint8List?;
        _selectedFile = null;
      } else {
        _selectedFile = result["file"] as File?;
        _selectedBytes = null;
      }
    });
  }

  Future<void> _createContent() async {
    if (_captionController.text.trim().isEmpty &&
        _selectedFile == null &&
        _selectedBytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please add a ${_isVideo ? "video" : "image"} or caption')),
        );
      }
      return;
    }

    setState(() => _isPosting = true);

    try {
      if (widget.postType == 'reel') {
        // Create reel
        final reel = await ReelService.createReel(
          caption: _captionController.text.trim(),
          music: _musicController.text.trim(),
          videoBytes: _selectedBytes,
          videoFile: _selectedFile,
          userId: AuthService.currentUserId ?? '',
        );

        if (reel != null && mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reel created successfully!')),
          );
        } else {
          throw Exception('Failed to create reel');
        }
      } else {
        // Create post
        final post = await PostService.createPost(
          caption: _captionController.text.trim(),
          imageBytes: _selectedBytes,
          imageFile: _selectedFile,
          postType: widget.postType,
        );

        if (post != null && mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${widget.postType == 'twitter' ? "Tweet" : "Post"} created successfully!')),
          );
        } else {
          throw Exception('Failed to create post');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPosting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating ${widget.postType == 'reel' ? "reel" : "post"}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isReel = widget.postType == 'reel';
    final title = isReel ? "Create Reel" : (widget.postType == 'twitter' ? "Create Tweet" : "Create Post");

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isPosting ? null : _createContent,
            child: _isPosting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    isReel ? "Reel" : (widget.postType == 'twitter' ? "Tweet" : "Post"),
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Media preview or picker
            if (_selectedFile != null || _selectedBytes != null)
              Stack(
                alignment: Alignment.topRight,
                children: [
                  Container(
                    height: isReel ? 400 : 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: kIsWeb && _selectedBytes != null
                          ? isReel
                              ? _buildVideoPreview(_selectedBytes!)
                              : Image.memory(_selectedBytes!, fit: BoxFit.cover)
                          : _selectedFile != null
                              ? isReel
                                  ? _buildVideoFilePreview(_selectedFile!)
                                  : Image.file(_selectedFile!, fit: BoxFit.cover)
                              : const SizedBox(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedFile = null;
                        _selectedBytes = null;
                      });
                    },
                  ),
                ],
              )
            else
              GestureDetector(
                onTap: _pickMedia,
                child: Container(
                  height: isReel ? 300 : 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isReel ? Icons.videocam : Icons.add_photo_alternate,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to add ${isReel ? "video" : "photo"}',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Caption input
            TextField(
              controller: _captionController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: isReel ? "Write a caption for your reel..." : "Write a caption...",
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),

            // Music input (only for reels)
            if (isReel) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _musicController,
                decoration: const InputDecoration(
                  hintText: "Add music (optional)",
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(12),
                  prefixIcon: Icon(Icons.music_note),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Add media button
            OutlinedButton.icon(
              onPressed: _pickMedia,
              icon: Icon(isReel ? Icons.videocam : Icons.photo_library),
              label: Text('Add ${isReel ? "Video" : "Photo"}'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPreview(Uint8List bytes) {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam, size: 64, color: Colors.white),
            SizedBox(height: 8),
            Text(
              'Video Selected',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoFilePreview(File file) {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam, size: 64, color: Colors.white),
            SizedBox(height: 8),
            Text(
              'Video Selected',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}