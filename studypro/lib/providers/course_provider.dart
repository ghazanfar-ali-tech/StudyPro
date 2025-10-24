import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:studypro/models/courseModel.dart';


class CourseProvider with ChangeNotifier {
  Course? _selectedCourse;
  bool _isLoading = false;
  String _error = '';
  List<Course> _allCourses = [];
  List<Course> _courses = [];

  Course? get selectedCourse => _selectedCourse;
  bool get isLoading => _isLoading;
  String get error => _error;
  List<Course> get allCourses => _allCourses;

  List<Course> get courses => _courses;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Future<void> fetchCourseById(String courseId) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final QuerySnapshot querySnapshot = await _firestore
          .collection('courses')
          .where('courseId', isEqualTo: courseId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        _selectedCourse = Course.fromJson(doc.data() as Map<String, dynamic>);
      } else {
        _error = 'Course not found';
        _selectedCourse = null;
      }
    } catch (e) {
      _error = 'Failed to fetch course: ${e.toString()}';
      _selectedCourse = null;
      debugPrint('Error fetching course: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  Future<void> fetchCourseByDocId(String docId) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final DocumentSnapshot doc = await _firestore
          .collection('courses')
          .doc(docId)
          .get();

      if (doc.exists) {
        _selectedCourse = Course.fromJson(doc.data() as Map<String, dynamic>);
      } else {
        _error = 'Course not found';
        _selectedCourse = null;
      }
    } catch (e) {
      _error = 'Failed to fetch course: ${e.toString()}';
      _selectedCourse = null;
      debugPrint('Error fetching course: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  Future<void> fetchCoursesByCategory(String category) async {
    try {
      setLoading(true);
      final querySnapshot = await FirebaseFirestore.instance
          .collection('courses')
          .where('category', isEqualTo: category)
          .get();
      _courses = querySnapshot.docs.map((doc) => Course.fromJson(doc.data())).toList();
      _error = '';
    } catch (e) {
      _error = e.toString();
    } finally {
      setLoading(false);
    }
  }

  Future<void> fetchAllCourses() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final QuerySnapshot querySnapshot = await _firestore
          .collection('courses')
          .orderBy('createdAt', descending: true)
          .get();

      _allCourses = querySnapshot.docs
          .map((doc) => Course.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = 'Failed to fetch courses: ${e.toString()}';
      debugPrint('Error fetching courses: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCoursesByUser(String userEmail) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final QuerySnapshot querySnapshot = await _firestore
          .collection('courses')
          .where('createdBy', isEqualTo: userEmail)
          .orderBy('createdAt', descending: true)
          .get();

      _allCourses = querySnapshot.docs
          .map((doc) => Course.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = 'Failed to fetch user courses: ${e.toString()}';
      debugPrint('Error fetching user courses: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  void clearSelectedCourse() {
    _selectedCourse = null;
    _error = '';
    notifyListeners();
  }

  void clearError() {
    _error = '';
    notifyListeners();
  }

  Future<void> searchCourses(String searchQuery) async {
    if (searchQuery.isEmpty) {
      fetchAllCourses();
      return;
    }

    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final QuerySnapshot querySnapshot = await _firestore
          .collection('courses')
          .where('title', isGreaterThanOrEqualTo: searchQuery)
          .where('title', isLessThanOrEqualTo: '$searchQuery\uf8ff')
          .get();

      _allCourses = querySnapshot.docs
          .map((doc) => Course.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = 'Failed to search courses: ${e.toString()}';
      debugPrint('Error searching courses: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String getFormattedDuration() {
    if (_selectedCourse == null) return '';
    return _selectedCourse!.duration;
  }

  String getFormattedVideoCount() {
    if (_selectedCourse == null) return '0 videos';
    final count = _selectedCourse!.videoCount;
    return '$count video${count != 1 ? 's' : ''}';
  }

  String getFormattedRating() {
    if (_selectedCourse == null) return '0.0';
    return _selectedCourse!.rating.toStringAsFixed(1);
  }


  String getFormattedReviewCount() {
    if (_selectedCourse == null) return '(0 Reviews)';
    return '(${_selectedCourse!.reviewCount} Reviews)';
  }


}