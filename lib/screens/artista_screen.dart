import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:musiconnect/providers/user_profile_provider.dart';
import 'package:musiconnect/models/user_profile.dart';
import 'package:musiconnect/screens/edit_profile_screen.dart';

class ArtistaScreen extends StatefulWidget {
  const ArtistaScreen({super.key});

  @override
  ArtistaScreenState createState() => ArtistaScreenState();
}

class ArtistaScreenState extends State<ArtistaScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      return Center(child: Text('Por favor, faça login para ver seu perfil.'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<UserProfileProvider>(
        builder: (context, userProfileProvider, child) {
          final UserProfile? userProfile = userProfileProvider.userProfile;

          if (userProfile == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        backgroundImage: (userProfile.profileImageUrl != null && userProfile.profileImageUrl!.isNotEmpty)
                            ? NetworkImage(userProfile.profileImageUrl!)
                            : null,
                        child: (userProfile.profileImageUrl == null || userProfile.profileImageUrl!.isEmpty)
                            ? const Icon(Icons.person, size: 60, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(height: 10),
                                            Text(
                        userProfile.username,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      if (userProfile.nickname != null && userProfile.nickname!.isNotEmpty)
                        Text(
                          '@${userProfile.nickname}',
                          style: const TextStyle(fontSize: 18, color: Colors.grey),
                        )
                      else
                        Text(
                          '@${userProfile.username.toLowerCase().replaceAll(' ', '')}',
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      const SizedBox(height: 10),
                      if (userProfile.bio != null && userProfile.bio!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            userProfile.bio!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      const SizedBox(height: 10),
                      Text(
                        'Tipo: ${userProfile.userType == 'musician' ? 'Músico' : 'Banda'}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      if (userProfile.isAvailable != null)
                        Text(
                          userProfile.userType == 'musician'
                              ? (userProfile.isAvailable! ? 'Disponível para banda' : 'Não disponível para banda')
                              : (userProfile.isAvailable! ? 'Com vagas abertas' : 'Sem vagas abertas'),
                          style: const TextStyle(fontSize: 14, color: Colors.blueGrey),
                        ),
                      if (userProfile.instruments != null && userProfile.instruments!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 5.0),
                          child: Text(
                            'Instrumentos: ${userProfile.instruments!.join(', ')}',
                            style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                          ),
                        ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Text(
                                (userProfile.friendUids?.length ?? 0).toString(),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const Text('Amigos'),
                            ],
                          ),
                          Column(
                            children: [ 
                              Text(
                                (userProfile.postCount ?? 0).toString(),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const Text('Postagens'),
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                (userProfile.profileViewCount ?? 0).toString(),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const Text('Visualizações'),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(),
                // Placeholder for content tabs (Video, Photo, Music)
                DefaultTabController(
                  length: 3,
                  child: Column(
                    children: [
                      const TabBar(
                        tabs: [
                          Tab(icon: Icon(Icons.videocam), text: 'Vídeos'),
                          Tab(icon: Icon(Icons.photo), text: 'Fotos'),
                          Tab(icon: Icon(Icons.music_note), text: 'Músicas'),
                        ],
                      ),
                      SizedBox(
                        height: 300, // Adjust height as needed
                        child: TabBarView(
                          children: [
                            const Center(child: Text('Conteúdo de Vídeos aqui')),
                            const Center(child: Text('Conteúdo de Fotos aqui')),
                            const Center(child: Text('Conteúdo de Músicas aqui')),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                const Text(
                  'Minhas Postagens',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('posts')
                      .where('userId', isEqualTo: currentUser.uid)
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (ctx, postSnapshot) {
                    if (postSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!postSnapshot.hasData || postSnapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('Nenhuma postagem sua ainda.'));
                    }

                    final posts = postSnapshot.data!.docs;

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
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
                                  post['username'] ?? 'Usuário Desconhecido',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(post['content']),
                                const SizedBox(height: 4),
                                Text(
                                  (post['timestamp'] as Timestamp).toDate().toString(),
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
      },
      )
    );
  }
}

 