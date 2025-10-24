import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:studypro/models/progress_model.dart';

class ProgressService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String? get _currentUserId => _auth.currentUser?.uid;

  static Future<void> updateVideoProgress({
    required String videoId,
    required String videoTitle,
    required String courseId,
    required String courseTitle,
    required Duration watchedDuration,
    required Duration totalDuration,
    required List<String> skillsLearned,
  }) async {
    try {
      final currentUserId = _currentUserId;
      if (currentUserId == null) {
        debugPrint('No user logged in - cannot update video progress');
        return;
      }

      final progressPercentage = (watchedDuration.inSeconds / totalDuration.inSeconds * 100).clamp(0.0, 100.0);
      
      final progress = VideoProgress(
        videoId: videoId,
        videoTitle: videoTitle,
        courseId: courseId,
        courseTitle: courseTitle,
        watchedAt: DateTime.now(),
        watchedDuration: watchedDuration,
        totalDuration: totalDuration,
        progressPercentage: progressPercentage,
        skillsLearned: skillsLearned,
      );

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('videoProgress')
          .doc('${courseId}_$videoId')
          .set(progress.toMap(), SetOptions(merge: true));
      
      debugPrint('Video progress updated successfully');
    } catch (e) {
      debugPrint('Error updating video progress: $e');
    }
  }

  static Stream<List<VideoProgress>> getVideoProgressStream() {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      debugPrint('No user logged in - returning empty stream');
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('videoProgress')
        .orderBy('watchedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VideoProgress.fromMap(doc.data()))
            .toList())
        .handleError((error) {
          debugPrint('Error in video progress stream: $error');
          return <VideoProgress>[];
        });
  }

  static Future<Map<String, dynamic>> getProgressSummary() async {
    try {
      await _waitForAuth();
      
      final currentUserId = _currentUserId;
      if (currentUserId == null) {
        debugPrint('No user logged in - returning empty progress summary');
        return _getEmptyProgressSummary();
      }

      debugPrint('Getting progress summary for user: $currentUserId');

      final snapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('videoProgress')
          .get();
      
      debugPrint('Found ${snapshot.docs.length} video progress documents');
      
      if (snapshot.docs.isEmpty) {
        debugPrint('No video progress found');
        return _getEmptyProgressSummary();
      }

      final progressList = snapshot.docs
          .map((doc) {
            try {
              return VideoProgress.fromMap(doc.data());
            } catch (e) {
              debugPrint('Error parsing progress document ${doc.id}: $e');
              return null;
            }
          })
          .whereType<VideoProgress>()
          .toList();

      if (progressList.isEmpty) {
        debugPrint('No valid video progress data found');
        return _getEmptyProgressSummary();
      }

      final totalVideos = progressList.length;
      final totalSeconds = progressList.fold<int>(
          0, (sum, progress) => sum + progress.watchedDuration.inSeconds);
      final totalHours = totalSeconds / 3600;
      
      final uniqueCourses = progressList.map((p) => p.courseId).toSet();
      final coursesInProgress = uniqueCourses.length;
      
      final averageProgress = progressList.fold<double>(
          0, (sum, progress) => sum + progress.progressPercentage) / totalVideos;
      
      final allSkills = progressList
          .expand((progress) => progress.skillsLearned)
          .toSet()
          .toList();

      final result = {
        'totalVideos': totalVideos,
        'totalHours': totalHours,
        'coursesInProgress': coursesInProgress,
        'averageProgress': averageProgress,
        'skillsLearned': allSkills,
      };

      debugPrint('Progress summary result: $result');
      return result;

    } catch (e) {
      debugPrint('Error getting progress summary: $e');
      return _getEmptyProgressSummary();
    }
  }

  static Future<void> _waitForAuth() async {
    if (_auth.currentUser != null) {
      return;
    }

    final completer = Completer<void>();
    late StreamSubscription subscription;
    
    final timer = Timer(const Duration(seconds: 3), () {
      if (!completer.isCompleted) {
        subscription.cancel();
        completer.complete();
      }
    });

    subscription = _auth.authStateChanges().listen((user) {
      if (user != null && !completer.isCompleted) {
        timer.cancel();
        subscription.cancel();
        completer.complete();
      }
    });

    await completer.future;
  }

  static Map<String, dynamic> _getEmptyProgressSummary() {
    return {
      'totalVideos': 0,
      'totalHours': 0.0,
      'coursesInProgress': 0,
      'averageProgress': 0.0,
      'skillsLearned': <String>[],
    };
  }

  static bool get isUserAuthenticated => _currentUserId != null;

  static Future<String?> getCurrentUserId() async {
    await _waitForAuth();
    return _currentUserId;
  }
}