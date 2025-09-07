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

    // Check if a request already exists
    final existingRequest = await _firestore
        .collection('chat_requests')
        .where('senderId', isEqualTo: currentUser.uid)
        .where('receiverId', isEqualTo: receiverId)
        .get();

    if (existingRequest.docs.isNotEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Solicitação de chat já enviada.')),
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
    ).showSnackBar(SnackBar(content: Text('Solicitação de chat enviada!')));
  }

  Future<void> _acceptChatRequest(String requestId) async {
    await _firestore.collection('chat_requests').doc(requestId).update({
      'status': 'accepted',
    });
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Solicitação de chat aceita!')));
  }

  Future<void> _rejectChatRequest(String requestId) async {
    await _firestore.collection('chat_requests').doc(requestId).update({
      'status': 'rejected',
    });
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Solicitação de chat recusada.')));
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      return Center(child: Text('Faça login para ver a lista de usuários.'));
    }

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Buscar usuários...',
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
            return Center(child: CircularProgressIndicator());
          }
          if (!userSnapshot.hasData || userSnapshot.data!.docs.isEmpty) {
            return Center(child: Text('Nenhum usuário encontrado.'));
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
                return Center(child: CircularProgressIndicator());
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
                    return Center(child: CircularProgressIndicator());
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
                          trailingWidget = Text('Solicitação Enviada');
                        } else {
                          trailingWidget = Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.check, color: Colors.green),
                                onPressed: () => _acceptChatRequest(requestId!),
                              ),
                              IconButton(
                                icon: Icon(Icons.close, color: Colors.red),
                                onPressed: () => _rejectChatRequest(requestId!),
                              ),
                            ],
                          );
                        }
                      } else if (requestStatus == 'accepted') {
                        trailingWidget = Icon(Icons.chat);
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
                        trailingWidget = Text('Solicitação Recusada');
                      } else {
                        // No request or rejected, allow sending new request
                        trailingWidget = ElevatedButton(
                          onPressed: () => _sendChatRequest(userProfile.uid),
                          child: Text('Enviar Solicitação'),
                        );
                      }

                      return Card(
                        margin: EdgeInsets.symmetric(
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
                                ? 'Músico'
                                : 'Banda',
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
