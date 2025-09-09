import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:musiconnect/providers/user_profile_provider.dart';
import 'package:musiconnect/models/group.dart';
import 'package:musiconnect/models/user_profile.dart';

class GroupDetailScreen extends StatefulWidget {
  final Group group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  final _postController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  void _createGroupPost() async {
    final user = _auth.currentUser;
    final UserProfile? userProfile = Provider.of<UserProfileProvider>(
      context,
      listen: false,
    ).userProfile;

    if (user == null ||
        userProfile == null ||
        _postController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write something to post in the group.'), // Placeholder for localization
        ),
      );
      return;
    }

    try {
      await _firestore.collection('posts').add({
        'content': _postController.text.trim(),
        'timestamp': Timestamp.now(),
        'userId': user.uid,
        'username': userProfile.username,
        'userType': userProfile.userType,
        'groupId': widget.group.id, // Associate post with this group
      });

      _postController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post created successfully!')), // Placeholder for localization
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating post: $e')), // Placeholder for localization
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.group.name)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.group.description,
                  style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 8),
                Text('Members: ${widget.group.members.length}'), // Placeholder for localization
                const SizedBox(height: 16),
                TextField(
                  controller: _postController,
                  decoration: InputDecoration(
                    hintText: 'Write something for the group...', // Placeholder for localization
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0), // Added border radius
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _createGroupPost,
                  child: const Text('Post to Group'), // Placeholder for localization
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('posts')
                  .where(
                    'groupId',
                    isEqualTo: widget.group.id,
                  ) // Filter posts by groupId
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (ctx, postSnapshot) {
                if (postSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!postSnapshot.hasData || postSnapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No posts in this group yet.'), // Placeholder for localization
                  );
                }

                final posts = postSnapshot.data!.docs;

                return ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (ctx, index) {
                    final post = posts[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post['username'] ?? 'Unknown User', // Placeholder for localization
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(post['content']),
                            const SizedBox(height: 4),
                            Text(
                              (post['timestamp'] as Timestamp)
                                  .toDate()
                                  .toString(),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
