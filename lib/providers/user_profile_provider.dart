import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Added for debugPrint
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:musiconnect/models/user_profile.dart';

class UserProfileProvider with ChangeNotifier {
  UserProfile? _userProfile;

  UserProfile? get userProfile => _userProfile;

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Future<void> fetchUserProfile(String uid) async {
    _isLoading = true;
    notifyListeners(); // Notify listeners that loading has started
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists) {
        _userProfile = UserProfile.fromFirestore(doc);
      }
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners(); // Notify listeners that loading has finished
    }
  }

  void clearUserProfile() {
    _userProfile = null;
    notifyListeners();
  }

  Future<void> createUserProfile(UserProfile userProfile) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userProfile.uid)
          .set(userProfile.toFirestore());
      _userProfile = userProfile;
      notifyListeners();
    } catch (e) {
      debugPrint('Error creating user profile: $e');
    }
  }

  Future<void> updateUserProfile(UserProfile updatedProfile) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(updatedProfile.uid)
          .update(updatedProfile.toFirestore());
      _userProfile = updatedProfile; // Update the local profile
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating user profile: $e');
    }
  }
}
