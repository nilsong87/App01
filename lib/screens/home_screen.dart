import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:musiconnect/providers/user_profile_provider.dart';
import 'package:musiconnect/providers/post_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:musiconnect/screens/comments_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final _postController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  XFile? _selectedMedia;
  String? _selectedMediaType;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    Provider.of<PostProvider>(context, listen: false).fetchPosts();
  }

  Future<void> _pickMedia(ImageSource source, {bool isVideo = false, bool isAudio = false}) async {
    final picker = ImagePicker();
    XFile? pickedFile;

    if (isVideo) {
      pickedFile = await picker.pickVideo(source: source);
    } else if (isAudio) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleção de áudio não implementada ainda.')),
      );
      return;
    } else {
      pickedFile = await picker.pickImage(source: source);
    }

    setState(() {
      _selectedMedia = pickedFile;
      if (pickedFile != null) {
        if (isVideo) {
          _selectedMediaType = 'video';
        } else if (isAudio) {
          _selectedMediaType = 'audio';
        } else {
          _selectedMediaType = 'image';
        }
      } else {
        _selectedMediaType = null;
      }
    });
  }

  void _createPost() async {
    final user = _auth.currentUser;
    final userProfileProvider = Provider.of<UserProfileProvider>(context, listen: false);
    final postProvider = Provider.of<PostProvider>(context, listen: false);

    final userProfile = userProfileProvider.userProfile;

    if (user == null ||
        userProfile == null ||
        (_postController.text.trim().isEmpty && _selectedMedia == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, escreva algo ou selecione uma mídia.')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      await postProvider.createPost(
        currentUserProfile: userProfile,
        content: _postController.text.trim().isEmpty ? null : _postController.text.trim(),
        mediaFile: _selectedMedia,
        mediaType: _selectedMediaType,
      );

      _postController.clear();
      setState(() {
        _selectedMedia = null;
        _selectedMediaType = null;
        _isUploading = false;
      });
      await postProvider.fetchPosts();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao criar post: $e')),
      );
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final postProvider = Provider.of<PostProvider>(context);
    final currentUser = _auth.currentUser;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _postController,
                      decoration: const InputDecoration(
                        hintText: 'O que você está pensando?',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _isUploading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _createPost,
                          child: const Text('Postar'),
                        ),
                ],
              ),
              if (_selectedMedia != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: _selectedMediaType == 'video'
                      ? const Text('Vídeo selecionado (player em breve)')
                      : Image.file(
                          File(_selectedMedia!.path),
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  TextButton.icon(
                    onPressed: () => _pickMedia(ImageSource.gallery),
                    icon: const Icon(Icons.image),
                    label: const Text('Imagem'),
                  ),
                  TextButton.icon(
                    onPressed: () => _pickMedia(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Câmera'),
                  ),
                  TextButton.icon(
                    onPressed: () => _pickMedia(ImageSource.gallery, isVideo: true),
                    icon: const Icon(Icons.video_library),
                    label: const Text('Vídeo'),
                  ),
                  TextButton.icon(
                    onPressed: () => _pickMedia(ImageSource.gallery, isAudio: true),
                    icon: const Icon(Icons.audiotrack),
                    label: const Text('Música'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            itemBuilder: (ctx, index) {
              return Container(
                width: 80,
                margin: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: Text('Story ${index + 1}')),
              );
            },
          ),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Text(
                'LIVES',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Funcionalidade de LIVE em desenvolvimento!')),
                  );
                },
                icon: const Icon(Icons.live_tv),
                label: const Text('Iniciar LIVE'),
              ),
              const SizedBox(height: 10),
              Container(
                height: 100,
                color: Colors.grey[200],
                child: const Center(child: Text('LIVES Ativas aqui')),
              ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: ListView.builder(
            itemCount: postProvider.posts.length,
            itemBuilder: (ctx, index) {
              final post = postProvider.posts[index];
              final bool isLiked = currentUser != null && post.likes.contains(currentUser.uid);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: post.userProfileImageUrl != null && post.userProfileImageUrl!.isNotEmpty
                                ? NetworkImage(post.userProfileImageUrl!)
                                : null,
                            child: post.userProfileImageUrl == null || post.userProfileImageUrl!.isEmpty
                                ? const Icon(Icons.person, size: 20, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            post.username,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          if (currentUser != null && post.userId == currentUser.uid)
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => postProvider.deletePost(post.id),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (post.content != null && post.content!.isNotEmpty)
                        Text(post.content!),
                      if (post.mediaUrl != null && post.mediaUrl!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: post.mediaType == 'video'
                              ? const Text('Vídeo (player em breve)')
                              : post.mediaType == 'audio'
                                  ? const Text('Áudio (player em breve)')
                                  : Image.network(
                                      post.mediaUrl!,
                                      height: 200,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        post.timestamp.toDate().toString(),
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              if (currentUser != null) {
                                postProvider.likePost(post.id, currentUser.uid);
                              }
                            },
                            icon: Icon(
                              isLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                              color: isLiked ? Theme.of(context).colorScheme.primary : Colors.grey,
                            ),
                            label: Text('Like (${post.likes.length})'),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => CommentsScreen(postId: post.id),
                                ),
                              );
                            },
                            icon: const Icon(Icons.comment_outlined),
                            label: const Text('Comment'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
