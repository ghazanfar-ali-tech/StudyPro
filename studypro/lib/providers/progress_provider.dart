import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProgressProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _progressData = [];
  bool _isLoading = false;
  String _error = '';

  List<Map<String, dynamic>> get progressData => _progressData;
  bool get isLoading => _isLoading;
  String get error => _error;
  int get totalVideosWatched => _progressData.length;
  int get totalCoursesInProgress => _progressData.map((e) => e['courseId']).toSet().length;

  Future<void> fetchProgress() async {
    if (_auth.currentUser == null) {
      _error = 'Please log in to view progress';
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      _error = '';
      notifyListeners();

      final snapshot = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('courseProgress')
          .get();

      _progressData = await Future.wait(snapshot.docs.map((doc) async {
        final data = doc.data();
        final courseSnapshot = await _firestore.collection('courses').doc(data['courseId']).get();
        final courseData = courseSnapshot.data();
        return {
          'courseId': data['courseId'],
          'courseTitle': courseData?['title'] ?? 'Unknown Course',
          'videoId': data['videoId'],
          'videoTitle': data['videoTitle'] ?? 'Unknown Video',
          'watchedAt': (data['watchedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'skills': data['skills'] ?? [],
        };
      }));

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load progress: $e';
      _isLoading = false;
      notifyListeners();
      print('Error fetching progress: $e');
    }
  }

  void clearError() {
    _error = '';
    notifyListeners();
  }
}