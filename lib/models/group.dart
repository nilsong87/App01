import 'package:cloud_firestore/cloud_firestore.dart';

class Group {
  final String id;
  final String name;
  final String description;
  final String adminId;
  final List<String> members;
  final Timestamp createdAt;

  Group({
    required this.id,
    required this.name,
    required this.description,
    required this.adminId,
    required this.members,
    required this.createdAt,
  });

  factory Group.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Group(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      adminId: data['adminId'] ?? '',
      members: List<String>.from(data['members'] ?? []),
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'adminId': adminId,
      'members': members,
      'createdAt': createdAt,
    };
  }
}
