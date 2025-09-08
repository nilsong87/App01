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
        SnackBar(
          content: Text('Por favor, preencha o nome e a descrição do grupo.'),
        ),
      );
      return;
    }

    await _firestore.collection('groups').add({
      'name': _groupNameController.text.trim(),
      'description': _groupDescriptionController.text.trim(),
      'adminId': user.uid,
      'members': [user.uid], // Current user is the first member
      'createdAt': Timestamp.now(),
    });

    _groupNameController.clear();
    _groupDescriptionController.clear();
  }

  void _joinLeaveGroup(Group group) async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (group.members.contains(user.uid)) {
      // Leave group
      await _firestore.collection('groups').doc(group.id).update({
        'members': FieldValue.arrayRemove([user.uid]),
      });
    } else {
      // Join group
      await _firestore.collection('groups').doc(group.id).update({
        'members': FieldValue.arrayUnion([user.uid]),
      });
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
                  Text(
                    'Criar Novo Grupo',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: _groupNameController,
                    decoration: InputDecoration(
                      labelText: 'Nome do Grupo',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: _groupDescriptionController,
                    decoration: InputDecoration(
                      labelText: 'Descrição do Grupo',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _createGroup,
                    child: Text('Criar Grupo'),
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
                return Center(child: CircularProgressIndicator());
              }
              if (!groupSnapshot.hasData || groupSnapshot.data!.docs.isEmpty) {
                return Center(child: Text('Nenhum grupo encontrado.'));
              }

              final groups = groupSnapshot.data!.docs;

              return ListView.builder(
                itemCount: groups.length,
                itemBuilder: (ctx, index) {
                  final group = Group.fromFirestore(groups[index]);
                  final isMember =
                      user != null && group.members.contains(user.uid);

                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(group.description),
                            SizedBox(height: 4),
                            Text('Membros: ${group.members.length}'),
                            SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () => _joinLeaveGroup(group),
                              child: Text(
                                isMember ? 'Sair do Grupo' : 'Entrar no Grupo',
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
