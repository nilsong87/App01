import 'package:cloud_firestore/cloud_firestore.dart';

class Vaga {
  final String id;
  final String userId;
  final String username;
  final String userType;
  final String title;
  final String description;
  final String instrument; // e.g., 'vocal', 'guitarra', 'bateria'
  final Timestamp timestamp;

  Vaga({
    required this.id,
    required this.userId,
    required this.username,
    required this.userType,
    required this.title,
    required this.description,
    required this.instrument,
    required this.timestamp,
  });

  factory Vaga.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Vaga(
      id: doc.id,
      userId: data['userId'] ?? '',
      username: data['username'] ?? '',
      userType: data['userType'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      instrument: data['instrument'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'username': username,
      'userType': userType,
      'title': title,
      'description': description,
      'instrument': instrument,
      'timestamp': timestamp,
    };
  }
}
