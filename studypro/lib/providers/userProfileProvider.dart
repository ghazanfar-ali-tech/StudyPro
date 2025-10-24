import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloudinary_public/cloudinary_public.dart';

class UserProfileProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final CloudinaryPublic _cloudinary = CloudinaryPublic('ds7vlzkev', 'cloud_storage', cache: false);

  String? _profilePhotoUrl;
  String? _username;
  String? _country;
  int? _learningStreak;
  int? _longestStreak;
  DateTime? _lastStreakDate;
  
  bool _isLoading = false;
  String? _error;

  String? get profilePhotoUrl => _profilePhotoUrl;
  String? get username => _username;
  String? get country => _country;
  int? get learningStreak => _learningStreak;
  int? get longestStreak => _longestStreak;
  DateTime? get lastStreakDate => _lastStreakDate;
  bool get isLoading => _isLoading;
  String? get error => _error;

  static const String _profilePhotoKey = 'cached_profile_photo';

  Future<void> fetchUserProfile() async {
    if (_auth.currentUser == null) return;

    try {
      _error = null;
      notifyListeners();

      final doc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        _username = data['username'];
        _country = data['country'];
        _learningStreak = data['learningStreak'];
        _longestStreak = data['longestStreak'];
        _lastStreakDate = (data['lastStreakDate'] as Timestamp?)?.toDate();
        _profilePhotoUrl = data['profilePhotoUrl'];
        
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to load profile: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> updateUserProfile({
    String? username,
    String? country,
  }) async {
    if (_auth.currentUser == null) {
      _error = 'Please log in to update profile';
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final updateData = <String, dynamic>{};
      
      if (username != null && username.isNotEmpty) {
        updateData['username'] = username;
      }
      
      if (country != null && country.isNotEmpty) {
        updateData['country'] = country;
      }

      if (updateData.isNotEmpty) {
        await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .update(updateData);

        if (username != null) _username = username;
        if (country != null) _country = country;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update profile: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchProfilePhoto() async {
    if (_auth.currentUser == null) return;

    try {
      _error = null;
      notifyListeners();

      final doc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();

      if (doc.exists) {
        _profilePhotoUrl = doc.data()?['profilePhotoUrl'];
        
        if (_profilePhotoUrl != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_profilePhotoKey, _profilePhotoUrl!);
        }
        
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to load profile photo: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> loadCachedPhoto() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _profilePhotoUrl = prefs.getString(_profilePhotoKey);
      if (_profilePhotoUrl != null) {
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading cached photo: $e');
    }
  }

  Future<void> uploadProfilePhoto(XFile imageFile) async {
    if (_auth.currentUser == null) {
      _error = 'Please log in to upload a profile photo';
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          folder: 'profile_photos',
          publicId: _auth.currentUser!.uid,
        ),
      );

      final downloadUrl = response.secureUrl;

      await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
        'profilePhotoUrl': downloadUrl,
      });

      _profilePhotoUrl = downloadUrl;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_profilePhotoKey, downloadUrl);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to upload profile photo: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> clearCachedPhoto() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_profilePhotoKey);
      _profilePhotoUrl = null;
      _username = null;
      _country = null;
      _learningStreak = null;
      _longestStreak = null;
      _lastStreakDate = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing cached data: $e');
    }
  }

  Future<void> updateLearningStreak() async {
    if (_auth.currentUser == null) return;

    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      final doc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final lastStreakDate = (data['lastStreakDate'] as Timestamp?)?.toDate();
        final currentStreak = data['learningStreak'] ?? 0;
        final longestStreak = data['longestStreak'] ?? 0;

        if (lastStreakDate == null || 
            DateTime(lastStreakDate.year, lastStreakDate.month, lastStreakDate.day) != today) {
          
          final newStreak = currentStreak + 1;
          final newLongestStreak = newStreak > longestStreak ? newStreak : longestStreak;

          await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
            'learningStreak': newStreak,
            'longestStreak': newLongestStreak,
            'lastStreakDate': Timestamp.fromDate(today),
          });

          _learningStreak = newStreak;
          _longestStreak = newLongestStreak;
          _lastStreakDate = today;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error updating learning streak: $e');
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}