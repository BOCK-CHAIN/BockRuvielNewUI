import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/story_service.dart';
import '../services/reel_service.dart';

class CreateStoryScreen extends StatefulWidget {
  final bool isReel;
  const CreateStoryScreen({super.key, this.isReel = false});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  bool _isVideo = false;
  late bool _isReel;

  XFile? _mediaFile;
  Uint8List? _webMediaBytes;

  final TextEditingController _captionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isReel = widget.isReel;
    if (_isReel) _isVideo = true; // reels = video only
  }

  Future<void> _pickMedia() async {
    XFile? media;

    if (_isVideo) {
      media = await _picker.pickVideo(source: ImageSource.gallery);
    } else {
      media = await _picker.pickImage(source: ImageSource.gallery);
    }

    if (media == null) return;

    if (kIsWeb) {
      final bytes = await media.readAsBytes();
      setState(() {
        _mediaFile = media;
        _webMediaBytes = bytes;
      });
    } else {
      setState(() {
        _mediaFile = media;
        _webMediaBytes = null;
      });
    }
  }

  Future<void> _share() async {
    if (_mediaFile == null) return;

    setState(() => _isLoading = true);

    try {
      Uint8List bytes;

      if (kIsWeb) {
        bytes = _webMediaBytes!;
      } else {
        bytes = await File(_mediaFile!.path).readAsBytes();
      }

      if (_isReel) {
        await ReelService.createReel(
          videoBytes: bytes,
          caption: _captionController.text.trim().isEmpty
              ? null
              : _captionController.text.trim(),
          music: null,
        );
      } else {
        if (kIsWeb) {
          await StoryService.createStory(
            imageBytes: _isVideo ? null : bytes,
            videoBytes: _isVideo ? bytes : null,
            caption: _captionController.text.trim().isEmpty
                ? null
                : _captionController.text.trim(),
          );
        } else {
          final file = File(_mediaFile!.path);
          await StoryService.createStory(
            imageFile: _isVideo ? null : file,
            videoFile: _isVideo ? file : null,
            caption: _captionController.text.trim().isEmpty
                ? null
                : _captionController.text.trim(),
          );
        }
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isReel ? 'Create Reel' : 'Create Story'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _share,
            child: _isLoading
                ? const CircularProgressIndicator()
                : const Text('Share'),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          if (!_isReel)
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('Photo'),
              Switch(
                value: _isVideo,
                onChanged: (v) {
                  setState(() {
                    _isVideo = v;
                    _mediaFile = null;
                    _webMediaBytes = null;
                  });
                },
              ),
              const Text('Video'),
            ]),

          const SizedBox(height: 16),

          Expanded(
            child: _mediaFile == null
                ? Center(
                    child: Text(
                      _isVideo ? 'No video selected' : 'No image selected',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  )
                : _isVideo
                    ? const Center(child: Icon(Icons.videocam, size: 80))
                    : kIsWeb
                        ? Image.memory(_webMediaBytes!)
                        : Image.file(File(_mediaFile!.path)),
          ),

          ElevatedButton(
            onPressed: _pickMedia,
            child: Text(_isVideo ? 'Select Video' : 'Select Image'),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: _captionController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Caption',
              border: OutlineInputBorder(),
            ),
          ),
        ]),
      ),
    );
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }
}