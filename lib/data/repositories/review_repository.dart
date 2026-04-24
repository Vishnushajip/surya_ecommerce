import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review_model.dart';
import '../../core/services/firebase_service.dart';
import '../../core/constants/app_constants.dart';

class ReviewRepository {
  final FirebaseFirestore _firestore;

  ReviewRepository(FirebaseService firebaseService)
    : _firestore = firebaseService.firestore;

  // Add a review
  Future<void> addReview(ReviewModel review) async {
    try {
      await _firestore
          .collection(AppConstants.feedbackCollection)
          .doc(review.feedbackId)
          .set(review.toFirestore());

      // Update product rating
      await _updateProductRating(review.productId);
    } catch (e) {
      throw Exception('Failed to add review: $e');
    }
  }

  // Get reviews for a product
  Future<List<ReviewModel>> getReviewsForProduct(
    String productId, {
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore
          .collection(AppConstants.feedbackCollection)
          .where('productId', isEqualTo: productId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final querySnapshot = await query.get();
      return querySnapshot.docs
          .map((doc) => ReviewModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get reviews: $e');
    }
  }

  // Get review summary for a product
  Future<ReviewSummary> getReviewSummary(String productId) async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.feedbackCollection)
          .where('productId', isEqualTo: productId)
          .get();

      final reviews = querySnapshot.docs
          .map((doc) => ReviewModel.fromFirestore(doc))
          .toList();

      return ReviewSummary.fromReviews(reviews);
    } catch (e) {
      throw Exception('Failed to get review summary: $e');
    }
  }

  // Get reviews by customer
  Future<List<ReviewModel>> getReviewsByCustomer(
    String customerEmail, {
    int limit = 50,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.feedbackCollection)
          .where('customerEmail', isEqualTo: customerEmail)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => ReviewModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get customer reviews: $e');
    }
  }

  // Check if customer has reviewed a product
  Future<bool> hasCustomerReviewedProduct(
    String productId,
    String customerEmail,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.feedbackCollection)
          .where('productId', isEqualTo: productId)
          .where('customerEmail', isEqualTo: customerEmail)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check if customer reviewed product: $e');
    }
  }

  // Update a review
  Future<void> updateReview(ReviewModel review) async {
    try {
      await _firestore
          .collection(AppConstants.feedbackCollection)
          .doc(review.feedbackId)
          .update(review.toFirestore());

      // Update product rating
      await _updateProductRating(review.productId);
    } catch (e) {
      throw Exception('Failed to update review: $e');
    }
  }

  // Delete a review
  Future<void> deleteReview(String feedbackId, String productId) async {
    try {
      await _firestore
          .collection(AppConstants.feedbackCollection)
          .doc(feedbackId)
          .delete();

      // Update product rating
      await _updateProductRating(productId);
    } catch (e) {
      throw Exception('Failed to delete review: $e');
    }
  }

  // Get recent reviews across all products
  Future<List<ReviewModel>> getRecentReviews({int limit = 10}) async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.feedbackCollection)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => ReviewModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get recent reviews: $e');
    }
  }

  // Get top-rated products
  Future<List<Map<String, dynamic>>> getTopRatedProducts({
    int limit = 10,
  }) async {
    try {
      final productsSnapshot = await _firestore
          .collection(AppConstants.productsCollection)
          .where('isActive', isEqualTo: true)
          .where('ratingCount', isGreaterThan: 0)
          .orderBy('ratingAverage', descending: true)
          .orderBy('ratingCount', descending: true)
          .limit(limit)
          .get();

      return productsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'productId': doc.id,
          'productName': data['productName'] ?? '',
          'productCategory': data['productCategory'] ?? '',
          'ratingAverage': data['ratingAverage'] ?? 0.0,
          'ratingCount': data['ratingCount'] ?? 0,
          'imageUrls': data['imageUrls'] ?? [],
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to get top-rated products: $e');
    }
  }

  // Get reviews statistics
  Future<Map<String, dynamic>> getReviewStatistics() async {
    try {
      final reviewsSnapshot = await _firestore
          .collection(AppConstants.feedbackCollection)
          .get();

      final totalReviews = reviewsSnapshot.docs.length;

      if (totalReviews == 0) {
        return {
          'totalReviews': 0,
          'averageRating': 0.0,
          'ratingDistribution': {'5': 0, '4': 0, '3': 0, '2': 0, '1': 0},
        };
      }

      final totalRating = reviewsSnapshot.docs.fold<double>(
        0,
        (sum, doc) => sum + (doc['rating'] as num).toDouble(),
      );
      final averageRating = totalRating / totalReviews;

      final ratingDistribution = <String, int>{
        '5': 0,
        '4': 0,
        '3': 0,
        '2': 0,
        '1': 0,
      };

      for (final doc in reviewsSnapshot.docs) {
        final rating = doc['rating'] as int;
        ratingDistribution[rating.toString()] =
            (ratingDistribution[rating.toString()] ?? 0) + 1;
      }

      return {
        'totalReviews': totalReviews,
        'averageRating': averageRating,
        'ratingDistribution': ratingDistribution,
      };
    } catch (e) {
      throw Exception('Failed to get review statistics: $e');
    }
  }

  // Stream for real-time review updates
  Stream<List<ReviewModel>> streamReviewsForProduct(
    String productId, {
    int limit = 20,
  }) {
    return _firestore
        .collection(AppConstants.feedbackCollection)
        .where('productId', isEqualTo: productId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ReviewModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Stream for review summary
  Stream<ReviewSummary> streamReviewSummary(String productId) {
    return _firestore
        .collection(AppConstants.feedbackCollection)
        .where('productId', isEqualTo: productId)
        .snapshots()
        .map((snapshot) {
          final reviews = snapshot.docs
              .map((doc) => ReviewModel.fromFirestore(doc))
              .toList();
          return ReviewSummary.fromReviews(reviews);
        });
  }

  // Search reviews
  Future<List<ReviewModel>> searchReviews({
    String? query,
    String? productId,
    int? minRating,
    int? maxRating,
    int limit = 20,
  }) async {
    try {
      Query firestoreQuery = _firestore.collection(
        AppConstants.feedbackCollection,
      );

      if (productId != null && productId.isNotEmpty) {
        firestoreQuery = firestoreQuery.where(
          'productId',
          isEqualTo: productId,
        );
      }

      if (minRating != null) {
        firestoreQuery = firestoreQuery.where(
          'rating',
          isGreaterThanOrEqualTo: minRating,
        );
      }

      if (maxRating != null) {
        firestoreQuery = firestoreQuery.where(
          'rating',
          isLessThanOrEqualTo: maxRating,
        );
      }

      final querySnapshot = await firestoreQuery
          .orderBy('createdAt', descending: true)
          .limit(limit * 2) // Get more to filter client-side
          .get();

      List<ReviewModel> reviews = querySnapshot.docs
          .map((doc) => ReviewModel.fromFirestore(doc))
          .toList();

      // Filter by search query if provided
      if (query != null && query.isNotEmpty) {
        final lowerQuery = query.toLowerCase();
        reviews = reviews.where((review) {
          return review.title.toLowerCase().contains(lowerQuery) ||
              review.feedback.toLowerCase().contains(lowerQuery) ||
              (review.customerName?.toLowerCase().contains(lowerQuery) ??
                  false);
        }).toList();
      }

      return reviews.take(limit).toList();
    } catch (e) {
      throw Exception('Failed to search reviews: $e');
    }
  }

  // Get reviews that need attention (e.g., very low ratings)
  Future<List<ReviewModel>> getReviewsNeedingAttention({int limit = 20}) async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.feedbackCollection)
          .where('rating', isLessThanOrEqualTo: 2)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => ReviewModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get reviews needing attention: $e');
    }
  }

  // Private helper method to update product rating
  Future<void> _updateProductRating(String productId) async {
    try {
      final reviewsSnapshot = await _firestore
          .collection(AppConstants.feedbackCollection)
          .where('productId', isEqualTo: productId)
          .get();

      if (reviewsSnapshot.docs.isEmpty) return;

      final reviews = reviewsSnapshot.docs
          .map((doc) => ReviewModel.fromFirestore(doc))
          .toList();

      final totalRating = reviews.fold<double>(
        0,
        (sum, review) => sum + review.rating,
      );
      final averageRating = totalRating / reviews.length;
      final ratingCount = reviews.length;

      await _firestore
          .collection(AppConstants.productsCollection)
          .doc(productId)
          .update({'ratingAverage': averageRating, 'ratingCount': ratingCount});
    } catch (e) {
      // Don't throw here to avoid failing the main operation
      print('Warning: Failed to update product rating: $e');
    }
  }

  // Batch update product ratings (for maintenance)
  Future<void> batchUpdateProductRatings() async {
    try {
      final productsSnapshot = await _firestore
          .collection(AppConstants.productsCollection)
          .where('isActive', isEqualTo: true)
          .get();

      for (final productDoc in productsSnapshot.docs) {
        await _updateProductRating(productDoc.id);
      }
    } catch (e) {
      throw Exception('Failed to batch update product ratings: $e');
    }
  }

  // Export reviews for analysis
  Future<List<Map<String, dynamic>>> exportReviews({
    String? productId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore.collection(AppConstants.feedbackCollection);

      if (productId != null && productId.isNotEmpty) {
        query = query.where('productId', isEqualTo: productId);
      }

      if (startDate != null) {
        query = query.where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        );
      }

      if (endDate != null) {
        query = query.where(
          'createdAt',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate),
        );
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'feedbackId': doc.id,
          'productId': data['productId'] ?? '',
          'rating': data['rating'] ?? 0,
          'feedback': data['feedback'] ?? '',
          'title': data['title'] ?? '',
          'customerName': data['customerName'] ?? '',
          'customerEmail': data['customerEmail'] ?? '',
          'createdAt': (data['createdAt'] as Timestamp)
              .toDate()
              .toIso8601String(),
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to export reviews: $e');
    }
  }
}
