class ReelModel {
  final String id;
  final String userId;
  final String username;
  final String? profileImageUrl;
  final String videoUrl;
  final String? caption;
  final String? music;
  final int likesCount;
  final int commentsCount;
  final bool isLiked;
  final DateTime createdAt;

  ReelModel({
    required this.id,
    required this.userId,
    required this.username,
    this.profileImageUrl,
    required this.videoUrl,
    this.caption,
    this.music,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isLiked = false,
    required this.createdAt,
  });

  factory ReelModel.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    final profileData = json['profiles'] is Map
        ? json['profiles'] as Map<String, dynamic>?
        : null;

    final likesList = json['likes'] is List ? json['likes'] as List? : null;
    final likesCount = (json['likes_count'] as num?)?.toInt() ??
        likesList?.length ??
        0;

    final isLiked = currentUserId != null && likesList != null
        ? likesList.any((like) => 
            (like is Map && like['user_id'] == currentUserId) ||
            (like is String && like == currentUserId))
        : false;

    return ReelModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      username: json['username'] as String? ?? 
          profileData?['username'] as String? ?? 
          'Unknown',
      profileImageUrl: json['profile_image_url'] as String? ?? 
          profileData?['profile_image_url'] as String?,
      videoUrl: json['video_url'] as String,
      caption: json['caption'] as String?,
      music: json['music'] as String?,
      likesCount: likesCount,
      commentsCount: (json['comments_count'] as num?)?.toInt() ?? 
          (json['comments'] is List ? (json['comments'] as List).length : 0),
      isLiked: isLiked,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'username': username,
      'profile_image_url': profileImageUrl,
      'video_url': videoUrl,
      'caption': caption,
      'music': music,
      'likes_count': likesCount,
      'comments_count': commentsCount,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

