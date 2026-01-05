class Comment {
  final String id;
  final String userId;
  final String movieId;
  final String commentText;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? username; // From profiles

  Comment({
    required this.id,
    required this.userId,
    required this.movieId,
    required this.commentText,
    required this.createdAt,
    required this.updatedAt,
    this.username,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      movieId: json['movie_id']?.toString() ?? '',
      commentText: json['comment_text']?.toString() ?? '',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
      username: json['profiles']?['username']?.toString(),
    );
  }
}