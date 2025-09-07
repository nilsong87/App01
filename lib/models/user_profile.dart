import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String email;
  String username;
  String userType; // 'musician' or 'band'
  String? bio;
  String? profileImageUrl;
  String? nickname; // @apelido
  bool? isAvailable; // For musicians: available for band; for bands: has openings
  List<String>? friendUids; // List of UIDs of friends
  int? postCount;
  int? profileViewCount;
  List<String>? instruments; // Instruments played by musician or needed by band

  UserProfile({
    required this.uid,
    required this.email,
    required this.username,
    required this.userType,
    this.bio,
    this.profileImageUrl,
    this.nickname,
    this.isAvailable,
    this.friendUids,
    this.postCount,
    this.profileViewCount,
    this.instruments,
  });

  // Factory constructor to create a UserProfile from a Firestore document
  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: doc.id,
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      userType: data['userType'] ?? '',
      bio: data['bio'],
      profileImageUrl: data['profileImageUrl'],
      nickname: data['nickname'],
      isAvailable: data['isAvailable'],
      friendUids: List<String>.from(data['friendUids'] ?? []),
      postCount: data['postCount'],
      profileViewCount: data['profileViewCount'],
      instruments: List<String>.from(data['instruments'] ?? []),
    );
  }

  // Method to convert a UserProfile to a Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'username': username,
      'userType': userType,
      'bio': bio,
      'profileImageUrl': profileImageUrl,
      'nickname': nickname,
      'isAvailable': isAvailable,
      'friendUids': friendUids,
      'postCount': postCount,
      'profileViewCount': profileViewCount,
      'instruments': instruments,
    };
  }
}
