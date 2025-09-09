import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:musiconnect/models/message.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverUsername;

  const ChatScreen({
    super.key,
    required this.receiverId,
    required this.receiverUsername,
  });

  @override
  ChatScreenState createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _chatRoomId {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return 'invalid_chat_id';

    final List<String> ids = [currentUser.uid, widget.receiverId];
    ids.sort();
    return ids.join('_');
  }

  void _sendMessage() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || _messageController.text.trim().isEmpty) {
      return;
    }

    final String senderId = currentUser.uid;
    final String receiverId = widget.receiverId;
    final String messageContent = _messageController.text.trim();

    await _firestore
        .collection('chats')
        .doc(_chatRoomId)
        .collection('messages')
        .add({
          'senderId': senderId,
          'receiverId': receiverId,
          'content': messageContent,
          'timestamp': Timestamp.now(),
        });

    _messageController.clear();
  }

  Future<void> _clearChat() async {
    final bool confirm =
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Clear Chat'), // Placeholder for localization
            content: const Text(
              'Are you sure you want to clear all messages in this conversation?', // Placeholder for localization
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop(false);
                },
                child: const Text('Cancel'), // Placeholder for localization
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop(true);
                },
                child: const Text('Clear'), // Placeholder for localization
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      try {
        final messages = await _firestore
            .collection('chats')
            .doc(_chatRoomId)
            .collection('messages')
            .get();

        final batch = _firestore.batch();
        for (var doc in messages.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();

        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Chat cleared successfully!'))); // Placeholder for localization
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error clearing chat: $e'))); // Placeholder for localization
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receiverUsername),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearChat,
            tooltip: 'Clear Chat', // Placeholder for localization
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .doc(_chatRoomId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (ctx, chatSnapshot) {
                if (chatSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!chatSnapshot.hasData || chatSnapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No messages yet.')); // Placeholder for localization
                }

                final messages = chatSnapshot.data!.docs;

                return ListView.builder(
                  reverse: true, // Show latest messages at the bottom
                  itemCount: messages.length,
                  itemBuilder: (ctx, index) {
                    final message = Message.fromFirestore(messages[index]);
                    final isMe = message.senderId == currentUser?.uid;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Card(
                        color: isMe
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey[300],
                        margin: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 8,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column( // Changed to Column to add timestamp
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message.content,
                                style: TextStyle(
                                  color: isMe ? Colors.white : Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                // Placeholder for timestamp display
                                message.timestamp.toDate().toString(),
                                style: TextStyle(
                                  color: isMe ? Colors.white70 : Colors.black54,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Send message...', // Placeholder for localization
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0), // Added border radius
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(icon: const Icon(Icons.send), onPressed: _sendMessage),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
