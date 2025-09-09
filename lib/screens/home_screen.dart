import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:musiconnect/providers/post_provider.dart';
import 'package:musiconnect/routes.dart';
import 'package:musiconnect/widgets/video_player_widget.dart';
import 'package:musiconnect/widgets/audio_player_widget.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final _auth = FirebaseAuth.instance;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _fetchInitialPosts();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
  }

  Future<void> _fetchInitialPosts() async {
    try {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (mounted) {
          await Provider.of<PostProvider>(context, listen: false).fetchPosts();
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar posts iniciais: ${e.toString()}')),
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() async {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      final postProvider = Provider.of<PostProvider>(context, listen: false);
      if (postProvider.hasMorePosts && !postProvider.isLoadingPosts) {
        try {
          await postProvider.fetchPosts();
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao carregar mais posts: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final postProvider = Provider.of<PostProvider>(context);
    final currentUser = _auth.currentUser;

    return Column(
      children: [
        // Stories and LIVES sections can be kept here or moved to a different screen
        // For now, we will keep them to not break the UI completely
        const Divider(),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 5, // Placeholder
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
            controller: _scrollController,
            itemCount: postProvider.posts.length +
                (postProvider.isLoadingPosts && postProvider.hasMorePosts ? 1 : 0),
            itemBuilder: (ctx, index) {
              if (index == postProvider.posts.length) {
                return const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final post = postProvider.posts[index];
              final bool isLiked =
                  currentUser != null && post.likes.contains(currentUser.uid);

              return Card(
                elevation: 4.0,
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundImage: post.userProfileImageUrl != null &&
                                post.userProfileImageUrl!.isNotEmpty
                            ? NetworkImage(post.userProfileImageUrl!)
                            : null,
                        child: post.userProfileImageUrl == null ||
                                post.userProfileImageUrl!.isEmpty
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(post.username, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(DateFormat.yMMMd().add_jm().format(post.timestamp.toDate())),
                      trailing: (currentUser != null && post.userId == currentUser.uid)
                          ? IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => postProvider.deletePost(post.id),
                            )
                          : null,
                    ),
                    if (post.content != null && post.content!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Text(post.content!),
                      ),
                    if (post.mediaUrl != null && post.mediaUrl!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: post.mediaType == 'video'
                            ? VideoPlayerWidget(videoUrl: post.mediaUrl!)
                            : post.mediaType == 'audio'
                                ? AudioPlayerWidget(audioUrl: post.mediaUrl!)
                                : Image.network(
                                    post.mediaUrl!,
                                    height: 250,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                              : null,
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Center(child: Icon(Icons.error));
                                    },
                                  ),
                      ),
                    const Divider(height: 1),
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
                            color: isLiked
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey,
                          ),
                          label: Text('Like (${post.likes.length})'),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.of(context).pushNamed(
                              AppRoutes.comments,
                              arguments: post.id,
                            );
                          },
                          icon: const Icon(Icons.comment_outlined),
                          label: const Text('Comment'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}