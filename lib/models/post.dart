import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String userId;
  final String username;
  final String? userProfileImageUrl;
  final String? content;
  final String? mediaUrl;
  final String? mediaType; // 'image', 'video', 'audio'
  final Timestamp timestamp;
  final List<String> likes;
  final List<String> comments; // Store comment IDs

  Post({
    required this.id,
    required this.userId,
    required this.username,
    this.userProfileImageUrl,
    this.content,
    this.mediaUrl,
    this.mediaType,
    required this.timestamp,
    this.likes = const [],
    this.comments = const [],
  });

  factory Post.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Post(
      id: doc.id,
      userId: data['userId'] ?? '',
      username: data['username'] ?? '',
      userProfileImageUrl: data['userProfileImageUrl'],
      content: data['content'],
      mediaUrl: data['mediaUrl'],
      mediaType: data['mediaType'],
      timestamp: data['timestamp'] ?? Timestamp.now(),
      likes: List<String>.from(data['likes'] ?? []),
      comments: List<String>.from(data['comments'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'username': username,
      'userProfileImageUrl': userProfileImageUrl,
      'content': content,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'timestamp': timestamp,
      'likes': likes,
      'comments': comments,
    };
  }
}
