import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FeedbackProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isSubmitting = false;
  String? _error;

  bool get isSubmitting => _isSubmitting;
  String? get error => _error;

Future<void> submitFeedback({
  required String type,
  required String message,
}) async {
  if (_auth.currentUser == null) {
    _error = 'Please log in to submit feedback';
    notifyListeners();
    return;
  }
  print('Authenticated user UID: ${_auth.currentUser!.uid}');
  try {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    final feedbackData = {
      'userId': _auth.currentUser!.uid,
      'userEmail': _auth.currentUser!.email,
      'type': type,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending',
    };

    await _firestore.collection('feedback').add(feedbackData);

    _isSubmitting = false;
    _error = null;
    notifyListeners();
  } catch (e) {
    _error = 'Failed to submit feedback: ${e.toString()}';
    _isSubmitting = false;
    notifyListeners();
    print('Error submitting feedback: $e');
  }
}
  Future<List<Map<String, dynamic>>> getUserFeedback() async {
    if (_auth.currentUser == null) {
      _error = 'Please log in to view feedback';
      notifyListeners();
      return [];
    }

    try {
      _error = null;
      notifyListeners();

      final querySnapshot = await _firestore
          .collection('feedback')
          .where('userId', isEqualTo: _auth.currentUser!.uid)
          .orderBy('timestamp', descending: true)
          .get().timeout(const Duration(seconds: 10), onTimeout: () {
      throw Exception('Request timed out');
    });;

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      _error = 'Failed to load feedback: ${e.toString()}';
      notifyListeners();
      return [];
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}