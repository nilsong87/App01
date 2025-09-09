import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:musiconnect/providers/user_profile_provider.dart';
import 'package:musiconnect/models/group.dart';
// Import the new screen
import 'package:musiconnect/routes.dart'; // Import AppRoutes

class TrupeScreen extends StatefulWidget {
  const TrupeScreen({super.key});

  @override
  TrupeScreenState createState() => TrupeScreenState();
}

class TrupeScreenState extends State<TrupeScreen> {
  final _groupNameController = TextEditingController();
  final _groupDescriptionController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  void _createGroup() async {
    final user = _auth.currentUser;
    final userProfile = Provider.of<UserProfileProvider>(
      context,
      listen: false,
    ).userProfile;

    if (user == null ||
        userProfile == null ||
        _groupNameController.text.trim().isEmpty ||
        _groupDescriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in the group name and description.'), // Placeholder for localization
        ),
      );
      return;
    }

    try {
      await _firestore.collection('groups').add({
        'name': _groupNameController.text.trim(),
        'description': _groupDescriptionController.text.trim(),
        'adminId': user.uid,
        'members': [user.uid], // Current user is the first member
        'createdAt': Timestamp.now(),
      });

      _groupNameController.clear();
      _groupDescriptionController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group created successfully!')), // Placeholder for localization
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating group: $e')), // Placeholder for localization
      );
    }
  }

  void _joinLeaveGroup(Group group) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      if (group.members.contains(user.uid)) {
        // Leave group
        await _firestore.collection('groups').doc(group.id).update({
          'members': FieldValue.arrayRemove([user.uid]),
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Left group successfully!')), // Placeholder for localization
        );
      } else {
        // Join group
        await _firestore.collection('groups').doc(group.id).update({
          'members': FieldValue.arrayUnion([user.uid]),
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Joined group successfully!')), // Placeholder for localization
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error joining/leaving group: $e')), // Placeholder for localization
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create New Group', // Placeholder for localization
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _groupNameController,
                    decoration: InputDecoration(
                      labelText: 'Group Name', // Placeholder for localization
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0), // Added border radius
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _groupDescriptionController,
                    decoration: InputDecoration(
                      labelText: 'Group Description', // Placeholder for localization
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0), // Added border radius
                      ),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _createGroup,
                    child: const Text('Create Group'), // Placeholder for localization
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('groups')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (ctx, groupSnapshot) {
              if (groupSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!groupSnapshot.hasData || groupSnapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No groups found.')); // Placeholder for localization
              }

              final groups = groupSnapshot.data!.docs;

              return ListView.builder(
                itemCount: groups.length,
                itemBuilder: (ctx, index) {
                  final group = Group.fromFirestore(groups[index]);
                  final isMember =
                      user != null && group.members.contains(user.uid);

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).pushNamed(
                          AppRoutes.groupDetail,
                          arguments: group,
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              group.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(group.description),
                            const SizedBox(height: 4),
                            Text('Members: ${group.members.length}'), // Placeholder for localization
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () => _joinLeaveGroup(group),
                              child: Text(
                                isMember ? 'Leave Group' : 'Join Group', // Placeholder for localization
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
      ],
    );
  }
}
