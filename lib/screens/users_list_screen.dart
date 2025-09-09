import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:musiconnect/models/user_profile.dart';
import 'package:musiconnect/screens/chat_screen.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _sendChatRequest(String receiverId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      // Check if a request already exists
      final existingRequest = await _firestore
          .collection('chat_requests')
          .where('senderId', isEqualTo: currentUser.uid)
          .where('receiverId', isEqualTo: receiverId)
          .get();

      if (existingRequest.docs.isNotEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chat request already sent.')), // Placeholder for localization
        );
        return;
      }

      await _firestore.collection('chat_requests').add({
        'senderId': currentUser.uid,
        'receiverId': receiverId,
        'status': 'pending',
        'timestamp': Timestamp.now(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Chat request sent!'))); // Placeholder for localization
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending chat request: $e')), // Placeholder for localization
      );
    }
  }

  Future<void> _acceptChatRequest(String requestId) async {
    try {
      await _firestore.collection('chat_requests').doc(requestId).update({
        'status': 'accepted',
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Chat request accepted!'))); // Placeholder for localization
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error accepting chat request: $e')), // Placeholder for localization
      );
    }
  }

  Future<void> _rejectChatRequest(String requestId) async {
    try {
      await _firestore.collection('chat_requests').doc(requestId).update({
        'status': 'rejected',
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Chat request rejected.'))); // Placeholder for localization
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error rejecting chat request: $e')), // Placeholder for localization
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      return const Center(child: Text('Please log in to see the user list.')); // Placeholder for localization
    }

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search users...', // Placeholder for localization
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white70),
          ),
          style: TextStyle(color: Colors.white),
          cursorColor: Colors.white,
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _searchText.isEmpty
            ? _firestore.collection('users').snapshots()
            : _firestore
                  .collection('users')
                  .where('username', isGreaterThanOrEqualTo: _searchText)
                  .where('username', isLessThan: '$_searchText\uf8ff')
                  .snapshots(),
        builder: (ctx, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!userSnapshot.hasData || userSnapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No users found.')); // Placeholder for localization
          }

          final users = userSnapshot.data!.docs;

          return StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('chat_requests')
                .where('senderId', isEqualTo: currentUser.uid)
                .snapshots(),
            builder: (ctx, sentRequestsSnapshot) {
              if (sentRequestsSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final sentRequests = sentRequestsSnapshot.data!.docs
                  .map(
                    (doc) => {
                      'id': doc.id,
                      'receiverId': doc['receiverId'],
                      'status': doc['status'],
                    },
                  )
                  .toList();

              return StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('chat_requests')
                    .where('receiverId', isEqualTo: currentUser.uid)
                    .snapshots(),
                builder: (ctx, receivedRequestsSnapshot) {
                  if (receivedRequestsSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final receivedRequests = receivedRequestsSnapshot.data!.docs
                      .map(
                        (doc) => {
                          'id': doc.id,
                          'senderId': doc['senderId'],
                          'status': doc['status'],
                        },
                      )
                      .toList();

                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (ctx, index) {
                      final userProfile = UserProfile.fromFirestore(
                        users[index],
                      );

                      // Don't show current user in the list
                      if (userProfile.uid == currentUser.uid) {
                        return Container();
                      }

                      // Check request status
                      String? requestStatus;
                      String? requestId;
                      bool isSender = false;

                      // Check if current user sent a request to this user
                      final sent = sentRequests.firstWhereOrNull(
                        (req) => req['receiverId'] == userProfile.uid,
                      );
                      if (sent != null) {
                        requestStatus = sent['status'];
                        requestId = sent['id'];
                        isSender = true;
                      }

                      // Check if this user sent a request to current user
                      final received = receivedRequests.firstWhereOrNull(
                        (req) => req['senderId'] == userProfile.uid,
                      );
                      if (received != null) {
                        requestStatus = received['status'];
                        requestId = received['id'];
                        isSender = false;
                      }

                      Widget? trailingWidget;
                      Function()? onTapAction;

                      if (requestStatus == 'pending') {
                        if (isSender) {
                          trailingWidget = const Text('Request Sent'); // Placeholder for localization
                        } else {
                          trailingWidget = Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check, color: Colors.green),
                                onPressed: () => _acceptChatRequest(requestId!),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.red),
                                onPressed: () => _rejectChatRequest(requestId!),
                              ),
                            ],
                          );
                        }
                      } else if (requestStatus == 'accepted') {
                        trailingWidget = const Icon(Icons.chat);
                        onTapAction = () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (ctx) => ChatScreen(
                                receiverId: userProfile.uid,
                                receiverUsername: userProfile.username,
                              ),
                            ),
                          );
                        };
                      } else if (requestStatus == 'rejected') {
                        trailingWidget = const Text('Request Rejected'); // Placeholder for localization
                      } else {
                        // No request or rejected, allow sending new request
                        trailingWidget = ElevatedButton(
                          onPressed: () => _sendChatRequest(userProfile.uid),
                          child: const Text('Send Request'), // Placeholder for localization
                        );
                      }

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(userProfile.username[0].toUpperCase()),
                          ),
                          title: Text(userProfile.username),
                          subtitle: Text(
                            userProfile.userType == 'musician'
                                ? 'Musician' // Placeholder for localization
                                : 'Band', // Placeholder for localization
                          ),
                          trailing: trailingWidget,
                          onTap: onTapAction,
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// Extension to easily find elements in a list
extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (T element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
