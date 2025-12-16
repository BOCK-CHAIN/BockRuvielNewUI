import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';
import 'comment_section.dart';

class PostModal extends StatefulWidget {
  final PostModel post;

  const PostModal({super.key, required this.post});

  @override
  State<PostModal> createState() => _PostModalState();
}

class _PostModalState extends State<PostModal> {
  final PostService _postService = PostService();
  late PostModel _post;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 1000,
          maxHeight: 720,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 700;

            final content = Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: isNarrow
                  ? Column(
                      children: [
                        _buildMedia(context),
                        const Divider(height: 1),
                        Expanded(child: _buildRightPanel(context)),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(flex: 3, child: _buildMedia(context)),
                        const VerticalDivider(width: 1),
                        Expanded(flex: 2, child: _buildRightPanel(context)),
                      ],
                    ),
            );

            return content;
          },
        ),
      ),
    );
  }

  Widget _buildMedia(BuildContext context) {
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      child: _post.imageUrl != null && _post.imageUrl!.isNotEmpty
          ? Image.network(
              _post.imageUrl!,
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
            )
          : const SizedBox(),
    );
  }

  Widget _buildRightPanel(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: _post.profileImageUrl != null &&
                        _post.profileImageUrl!.isNotEmpty
                    ? NetworkImage(_post.profileImageUrl!)
                    : const AssetImage('assets/images/story1.jpg')
                        as ImageProvider,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _post.username,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('Follow'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Caption & comments scroll area
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_post.caption != null && _post.caption!.isNotEmpty) ...[
                    RichText(
                      text: TextSpan(
                        style: theme.textTheme.bodyMedium,
                        children: [
                          TextSpan(
                            text: '${_post.username} ',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(text: _post.caption!),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  CommentSection(postId: _post.id),
                ],
              ),
            ),
          ),
        ),

        // Actions & input
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _post.isLiked
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: _post.isLiked ? Colors.red : null,
                    ),
                    onPressed: () async {
                      try {
                        final wasLiked = _post.isLiked;
                        setState(() {
                          _post = _post.copyWith(
                            isLiked: !wasLiked,
                            likesCount: wasLiked
                                ? _post.likesCount - 1
                                : _post.likesCount + 1,
                          );
                        });
                        await _postService.toggleLike(_post.id);
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.send_outlined),
                    onPressed: () {},
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.bookmark_border),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_post.likesCount} likes',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
