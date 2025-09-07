import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:provider/provider.dart';
import 'package:musiconnect/providers/user_profile_provider.dart';
import 'package:musiconnect/models/user_profile.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _profileImageUrlController = TextEditingController();
  String? _userType;
  final _auth = FirebaseAuth.instance;

  final _nicknameController = TextEditingController();
  final _instrumentsController = TextEditingController();
  bool _isAvailable = false;

  @override
  void initState() {
    super.initState();
    final UserProfile? userProfile = Provider.of<UserProfileProvider>(
      context,
      listen: false,
    ).userProfile;
    if (userProfile != null) {
      _usernameController.text = userProfile.username;
      _userType = userProfile.userType;
      _bioController.text = userProfile.bio ?? '';
      _profileImageUrlController.text = userProfile.profileImageUrl ?? '';
      _nicknameController.text = userProfile.nickname ?? '';
      _isAvailable = userProfile.isAvailable ?? false;
      _instrumentsController.text = userProfile.instruments?.join(', ') ?? '';
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    _profileImageUrlController.dispose();
    _nicknameController.dispose();
    _instrumentsController.dispose();
    super.dispose();
  }

  void _updateProfile() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    if (_usernameController.text.trim().isEmpty || _userType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Por favor, preencha o nome de usuário e selecione o tipo de usuário.',
          ),
        ),
      );
      return;
    }

    try {
      final userProfileProvider = Provider.of<UserProfileProvider>(context, listen: false);
      final currentProfile = userProfileProvider.userProfile;

      UserProfile updatedProfile = UserProfile(
        uid: currentUser.uid,
        email: currentProfile?.email ?? currentUser.email!,
        username: _usernameController.text.trim(),
        userType: _userType!,
        bio: _bioController.text.trim(),
        profileImageUrl: _profileImageUrlController.text.trim(),
        nickname: _nicknameController.text.trim(),
        isAvailable: _isAvailable,
        friendUids: currentProfile?.friendUids,
        postCount: currentProfile?.postCount,
        profileViewCount: currentProfile?.profileViewCount,
        instruments: _instrumentsController.text.trim().split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      );

      await userProfileProvider.updateUserProfile(updatedProfile);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Perfil atualizado com sucesso!')));
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao atualizar perfil: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Perfil')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Nome de Usuário',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _bioController,
                decoration: InputDecoration(
                  labelText: 'Bio',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 12),
              TextField(
                controller: _profileImageUrlController,
                decoration: InputDecoration(
                  labelText: 'URL da Imagem de Perfil',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _nicknameController,
                decoration: InputDecoration(
                  labelText: 'Apelido (@)',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _instrumentsController,
                decoration: InputDecoration(
                  labelText: 'Instrumentos (separados por vírgula)',
                  hintText: 'Ex: vocal, guitarra, bateria',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Text('Disponível para banda/vagas:'),
                  Switch(
                    value: _isAvailable,
                    onChanged: (value) {
                      setState(() {
                        _isAvailable = value;
                      });
                    },
                  ),
                ],
              ),
              SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _userType,
                decoration: InputDecoration(
                  labelText: 'Tipo de Usuário',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'musician', child: Text('Músico')),
                  DropdownMenuItem(value: 'band', child: Text('Banda')),
                ],
                onChanged: (value) {
                  setState(() {
                    _userType = value;
                  });
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateProfile,
                child: Text('Salvar Alterações'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}