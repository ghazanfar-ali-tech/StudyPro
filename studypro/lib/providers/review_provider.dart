import 'package:flutter/material.dart';
import 'package:studypro/models/review_model.dart';
import 'package:studypro/services/review_serivces.dart';


class ReviewProvider with ChangeNotifier {
  final ReviewService _reviewService = ReviewService();
  
  List<Review> _reviews = [];
  Review? _userReview;
  bool _isLoading = false;
  String _error = '';
  Map<String, dynamic> _ratingStats = {};

  List<Review> get reviews => _reviews;
  Review? get userReview => _userReview;
  bool get isLoading => _isLoading;
  String get error => _error;
  Map<String, dynamic> get ratingStats => _ratingStats;


  void clearError() {
    _error = '';
    notifyListeners();
  }


  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }


  void _setError(String error) {
    _error = error;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadCourseReviews(String courseId) async {
    _setLoading(true);
    clearError();
    
    try {
      _reviews = await _reviewService.getCourseReviews(courseId);
      _ratingStats = await _reviewService.getCourseRatingStats(courseId);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }


  Future<void> loadUserReview(String courseId, String userId) async {
    try {
      _userReview = await _reviewService.getUserReviewForCourse(courseId, userId);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

 
  Future<bool> addReview(Review review) async {
    _setLoading(true);
    clearError();
    
    try {
      await _reviewService.addReview(review);
      
   
      await loadCourseReviews(review.courseId);
      await loadUserReview(review.courseId, review.userId);
      
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }


  Future<bool> updateReview(String reviewId, Review updatedReview) async {
    _setLoading(true);
    clearError();
    
    try {
      await _reviewService.updateReview(reviewId, updatedReview);
      

      await loadCourseReviews(updatedReview.courseId);
      await loadUserReview(updatedReview.courseId, updatedReview.userId);
      
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteReview(String reviewId, String courseId, String userId) async {
    _setLoading(true);
    clearError();
    
    try {
      await _reviewService.deleteReview(reviewId);
      
    
      await loadCourseReviews(courseId);
      await loadUserReview(courseId, userId);
      
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  String getFormattedAverageRating() {
    if (_ratingStats.isEmpty || _ratingStats['averageRating'] == 0.0) {
      return '0.0';
    }
    return _ratingStats['averageRating'].toStringAsFixed(1);
  }

  int getTotalReviews() {
    return _ratingStats.isEmpty ? 0 : _ratingStats['totalReviews'];
  }


  Map<int, int> getRatingDistribution() {
    if (_ratingStats.isEmpty) {
      return {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    }
    return Map<int, int>.from(_ratingStats['ratingDistribution']);
  }

  bool hasUserReviewed() {
    return _userReview != null;
  }

  void clearData() {
    _reviews.clear();
    _userReview = null;
    _ratingStats.clear();
    _error = '';
    _isLoading = false;
    notifyListeners();
  }
  
}