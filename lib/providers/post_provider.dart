import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:musiconnect/models/post.dart';
import 'package:musiconnect/models/user_profile.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class PostProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final List<Post> _posts = [];
  List<Post> get posts => _posts;

  DocumentSnapshot? _lastDocument;
  bool _hasMorePosts = true;
  bool get hasMorePosts => _hasMorePosts;
  bool _isLoadingPosts = false;
  bool get isLoadingPosts => _isLoadingPosts;

  Future<void> createPost({
    required UserProfile currentUserProfile,
    String? content,
    XFile? mediaFile,
    String? mediaType,
  }) async {
    if (content == null && mediaFile == null) {
      return;
    }

    String? mediaUrl;
    if (mediaFile != null) {
      try {
        File file = File(mediaFile.path);
        String filePath = 'post_media/${DateTime.now().millisecondsSinceEpoch}_${mediaFile.name}';
        UploadTask uploadTask = _storage.ref().child(filePath).putFile(file);
        TaskSnapshot snapshot = await uploadTask;
        mediaUrl = await snapshot.ref.getDownloadURL();
      } catch (e) {
        debugPrint('Error uploading media: $e');
        throw Exception('Failed to upload media: $e'); // Throw exception
      }
    }

    final newPost = Post(
      id: _firestore.collection('posts').doc().id,
      userId: currentUserProfile.uid,
      username: currentUserProfile.username,
      userProfileImageUrl: currentUserProfile.profileImageUrl,
      content: content,
      mediaUrl: mediaUrl,
      mediaType: mediaType,
      timestamp: Timestamp.now(),
    );

    try {
      await _firestore.collection('posts').doc(newPost.id).set(newPost.toFirestore());
      // When a new post is created, we should reset the pagination
      // and fetch posts again to ensure the new post appears at the top.
      resetPosts();
      await fetchPosts();
      debugPrint('Post created successfully!');
    } catch (e) {
      debugPrint('Error creating post: $e');
      throw Exception('Failed to create post: $e'); // Throw exception
    }
  }

  Future<void> fetchPosts({int limit = 10}) async {
    if (!_hasMorePosts || _isLoadingPosts) {
      return;
    }

    _isLoadingPosts = true;
    notifyListeners();

    try {
      Query query = _firestore
          .collection('posts')
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      QuerySnapshot snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        _hasMorePosts = false;
      } else {
        _lastDocument = snapshot.docs.last;
        _posts.addAll(snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList());
        _hasMorePosts = snapshot.docs.length == limit;
      }
    } catch (e) {
      debugPrint('Error fetching posts: $e');
      throw Exception('Failed to fetch posts: $e'); // Throw exception
    } finally {
      _isLoadingPosts = false;
      notifyListeners();
    }
  }

  void resetPosts() {
    _posts.clear();
    _lastDocument = null;
    _hasMorePosts = true;
    notifyListeners();
  }

  Future<void> likePost(String postId, String userId) async {
    try {
      DocumentReference postRef = _firestore.collection('posts').doc(postId);
      DocumentSnapshot postSnapshot = await postRef.get();
      List<String> likes = List<String>.from(postSnapshot.get('likes') ?? []);

      if (likes.contains(userId)) {
        likes.remove(userId);
      } else {
        likes.add(userId);
      }

      await postRef.update({'likes': likes});

      // Update the specific post in the local list without refetching all posts
      final postIndex = _posts.indexWhere((post) => post.id == postId);
      if (postIndex != -1) {
        _posts[postIndex] = Post.fromFirestore(await postRef.get());
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error liking post: $e');
      throw Exception('Failed to like post: $e'); // Throw exception
    }
  }

  Future<void> addComment(String postId, String userId, String username, String comment) async {
    try {
      await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .add({
        'userId': userId,
        'username': username,
        'comment': comment,
        'timestamp': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('Error adding comment: $e');
      throw Exception('Failed to add comment: $e'); // Throw exception
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      DocumentSnapshot postSnapshot = await _firestore.collection('posts').doc(postId).get();
      final post = Post.fromFirestore(postSnapshot);

      if (post.mediaUrl != null) {
        await _storage.refFromURL(post.mediaUrl!).delete();
      }

      await _firestore.collection('posts').doc(postId).delete();

      _posts.removeWhere((p) => p.id == postId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting post: $e');
      throw Exception('Failed to delete post: $e'); // Throw exception
    }
  }
}