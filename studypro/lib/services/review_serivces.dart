import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:studypro/models/review_model.dart';

class ReviewService {
  final CollectionReference _reviewsCollection = 
      FirebaseFirestore.instance.collection('reviews');

  Future<String> addReview(Review review) async {
    try {
      final existingReview = await getUserReviewForCourse(
        review.courseId, 
        review.userId
      );
      
      if (existingReview != null) {
        throw Exception('You have already reviewed this course');
      }

      final docRef = await _reviewsCollection.add(review.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add review: $e');
    }
  }

  Future<void> updateReview(String reviewId, Review updatedReview) async {
    try {
      await _reviewsCollection.doc(reviewId).update({
        'rating': updatedReview.rating,
        'comment': updatedReview.comment,
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      throw Exception('Failed to update review: $e');
    }
  }

  Future<void> deleteReview(String reviewId) async {
    try {
      await _reviewsCollection.doc(reviewId).delete();
    } catch (e) {
      throw Exception('Failed to delete review: $e');
    }
  }

  Future<List<Review>> getCourseReviews(String courseId) async {
    try {
      final querySnapshot = await _reviewsCollection
          .where('courseId', isEqualTo: courseId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Review.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch reviews: $e');
    }
  }

  Stream<List<Review>> getCourseReviewsStream(String courseId) {
    return _reviewsCollection
        .where('courseId', isEqualTo: courseId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Review.fromFirestore(doc))
            .toList());
  }

  Future<Review?> getUserReviewForCourse(String courseId, String userId) async {
    try {
      final querySnapshot = await _reviewsCollection
          .where('courseId', isEqualTo: courseId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return Review.fromFirestore(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> getCourseRatingStats(String courseId) async {
    try {
      final querySnapshot = await _reviewsCollection
          .where('courseId', isEqualTo: courseId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return {
          'averageRating': 0.0,
          'totalReviews': 0,
          'ratingDistribution': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
        };
      }

      List<int> ratings = querySnapshot.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['rating'] as int)
          .toList();

      double averageRating = ratings.reduce((a, b) => a + b) / ratings.length;
      
      Map<int, int> ratingDistribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
      for (int rating in ratings) {
        ratingDistribution[rating] = (ratingDistribution[rating] ?? 0) + 1;
      }

      return {
        'averageRating': averageRating,
        'totalReviews': ratings.length,
        'ratingDistribution': ratingDistribution,
      };
    } catch (e) {
      return {
        'averageRating': 0.0,
        'totalReviews': 0,
        'ratingDistribution': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
      };
    }
  }

  Future<List<Review>> getUserReviews(String userId) async {
    try {
      final querySnapshot = await _reviewsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Review.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch user reviews: $e');
    }
  }

  Future<List<Review>> getPaginatedCourseReviews({
    required String courseId,
    DocumentSnapshot? lastDocument,
    int limit = 10,
  }) async {
    try {
      Query query = _reviewsCollection
          .where('courseId', isEqualTo: courseId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final querySnapshot = await query.get();
      return querySnapshot.docs
          .map((doc) => Review.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch paginated reviews: $e');
    }
  }
}