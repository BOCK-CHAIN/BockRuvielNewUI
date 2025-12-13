import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/story_service.dart';
import '../services/auth_service.dart';

class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _isVideo = false;
  XFile? _mediaFile;
  final TextEditingController _captionController = TextEditingController();

  Future<void> _pickMedia() async {
    try {
      XFile? media;
      if (_isVideo) {
        media = await _picker.pickVideo(source: ImageSource.gallery);
      } else {
        media = await _picker.pickImage(source: ImageSource.gallery);
      }

      if (media != null) {
        setState(() {
          _mediaFile = media;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick media: $e')),
        );
      }
    }
  }

  Future<void> _createStory() async {
    if (_mediaFile == null) return;

    if (kIsWeb) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Creating stories from web is not supported yet.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final file = File(_mediaFile!.path);
      await StoryService.createStory(
        imageFile: _isVideo ? null : file,
        videoFile: _isVideo ? file : null,
        caption: _captionController.text.trim().isEmpty
            ? null
            : _captionController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop(true); // Return success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create story: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Story'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createStory,
            child: _isLoading
                ? const CircularProgressIndicator()
                : const Text('Share'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Media Type Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Photo'),
                Switch(
                  value: _isVideo,
                  onChanged: (value) {
                    setState(() {
                      _isVideo = value;
                      _mediaFile = null;
                    });
                  },
                ),
                const Text('Video'),
              ],
            ),
            const SizedBox(height: 20),
            
            // Media Preview
            if (_mediaFile != null)
              _isVideo
                  ? AspectRatio(
                      aspectRatio: 9 / 16,
                      child: Container(
                        color: theme.colorScheme.surface,
                        child: const Center(
                          child: Text(
                            'Video preview not available on web yet',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    )
                  : (kIsWeb
                      ? Image.network(
                          _mediaFile!.path,
                          fit: BoxFit.contain,
                          height: 300,
                        )
                      : Image.file(
                          File(_mediaFile!.path),
                          fit: BoxFit.contain,
                          height: 300,
                        ))
            else
              Container(
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isVideo ? Icons.videocam : Icons.photo_camera,
                        size: 50,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isVideo
                            ? 'No video selected'
                            : 'No image selected',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 20),
            
            // Select Media Button
            ElevatedButton(
              onPressed: _pickMedia,
              child: Text(_isVideo ? 'Select Video' : 'Select Image'),
            ),
            
            const SizedBox(height: 20),
            
            // Caption Field
            TextField(
              controller: _captionController,
              decoration: const InputDecoration(
                labelText: 'Add a caption',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }
}
