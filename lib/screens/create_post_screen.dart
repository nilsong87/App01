import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:musiconnect/providers/post_provider.dart';
import 'package:musiconnect/providers/user_profile_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:musiconnect/widgets/video_player_widget.dart';
import 'package:musiconnect/widgets/audio_player_widget.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  CreatePostScreenState createState() => CreatePostScreenState();
}

class CreatePostScreenState extends State<CreatePostScreen> {
  final _postController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  XFile? _selectedMedia;
  String? _selectedMediaType;
  bool _isUploading = false;

  Future<void> _pickMedia(ImageSource source, {bool isVideo = false, bool isAudio = false}) async {
    final picker = ImagePicker();
    XFile? pickedFile;

    if (isVideo) {
      pickedFile = await picker.pickVideo(source: source);
    } else if (isAudio) {
      pickedFile = await picker.pickMedia();
      if (pickedFile != null && !pickedFile.path.endsWith('.mp3') && !pickedFile.path.endsWith('.wav') && !pickedFile.path.endsWith('.m4a')) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, selecione um arquivo de áudio (mp3, wav, m4a).')),
        );
        return;
      }
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
      if(mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao criar post: ${e.toString()}')),
      );
    } finally {
      if(mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Post'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _postController,
              decoration: const InputDecoration(
                hintText: 'O que você está pensando?',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            if (_selectedMedia != null)
              _selectedMediaType == 'video'
                  ? VideoPlayerWidget(videoUrl: _selectedMedia!.path)
                  : _selectedMediaType == 'audio'
                      ? AudioPlayerWidget(audioUrl: _selectedMedia!.path)
                      : Image.file(
                          File(_selectedMedia!.path),
                          height: 200,
                          fit: BoxFit.cover,
                        ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: () => _pickMedia(ImageSource.gallery),
                  icon: const Icon(Icons.image), tooltip: 'Imagem',
                ),
                IconButton(
                  onPressed: () => _pickMedia(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt), tooltip: 'Câmera',
                ),
                IconButton(
                  onPressed: () => _pickMedia(ImageSource.gallery, isVideo: true),
                  icon: const Icon(Icons.video_library), tooltip: 'Vídeo',
                ),
                IconButton(
                  onPressed: () => _pickMedia(ImageSource.gallery, isAudio: true),
                  icon: const Icon(Icons.audiotrack), tooltip: 'Música',
                ),
              ],
            ),
            const Spacer(),
            _isUploading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _createPost,
                    child: const Text('Postar'),
                  ),
          ],
        ),
      ),
    );
  }
}
