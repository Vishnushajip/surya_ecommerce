import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String feedbackId;
  final String productId;
  final int rating;
  final String feedback;
  final String title;
  final Timestamp createdAt;
  final String? customerName;
  final String? customerEmail;

  const ReviewModel({
    required this.feedbackId,
    required this.productId,
    required this.rating,
    required this.feedback,
    required this.title,
    required this.createdAt,
    this.customerName,
    this.customerEmail,
  });

  // Factory constructor to create ReviewModel from Firestore document
  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ReviewModel(
      feedbackId: doc.id,
      productId: data['productId'] as String,
      rating: data['rating'] as int,
      feedback: data['feedback'] as String,
      title: data['title'] as String,
      createdAt: data['createdAt'] as Timestamp,
      customerName: data['customerName'] as String?,
      customerEmail: data['customerEmail'] as String?,
    );
  }

  // Factory constructor to create ReviewModel from JSON
  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      feedbackId: json['feedbackId'] as String,
      productId: json['productId'] as String,
      rating: json['rating'] as int,
      feedback: json['feedback'] as String,
      title: json['title'] as String,
      createdAt: Timestamp.fromDate(DateTime.parse(json['createdAt'] as String)),
      customerName: json['customerName'] as String?,
      customerEmail: json['customerEmail'] as String?,
    );
  }

  // Method to convert ReviewModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'rating': rating,
      'feedback': feedback,
      'title': title,
      'createdAt': createdAt,
      if (customerName != null) 'customerName': customerName,
      if (customerEmail != null) 'customerEmail': customerEmail,
    };
  }

  // Method to convert ReviewModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'feedbackId': feedbackId,
      'productId': productId,
      'rating': rating,
      'feedback': feedback,
      'title': title,
      'createdAt': createdAt.toDate().toIso8601String(),
      'customerName': customerName,
      'customerEmail': customerEmail,
    };
  }

  // Create a copy with updated fields
  ReviewModel copyWith({
    String? feedbackId,
    String? productId,
    int? rating,
    String? feedback,
    String? title,
    Timestamp? createdAt,
    String? customerName,
    String? customerEmail,
  }) {
    return ReviewModel(
      feedbackId: feedbackId ?? this.feedbackId,
      productId: productId ?? this.productId,
      rating: rating ?? this.rating,
      feedback: feedback ?? this.feedback,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
    );
  }

  // Getters for computed properties
  String get formattedDate => '${createdAt.toDate().day}-${createdAt.toDate().month}-${createdAt.toDate().year}';
  String get ratingStars => '⭐' * rating;
  bool get isValid => rating >= 1 && rating <= 5 && feedback.isNotEmpty;
  String get displayName => customerName?.isNotEmpty == true ? customerName! : 'Anonymous';

  @override
  String toString() {
    return 'ReviewModel(feedbackId: $feedbackId, productId: $productId, rating: $rating, title: $title)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReviewModel && other.feedbackId == feedbackId;
  }

  @override
  int get hashCode => feedbackId.hashCode;
}

// Extension for review utility methods
extension ReviewModelExtension on ReviewModel {
  // Check if review is recent (within last 30 days)
  bool get isRecent {
    final now = DateTime.now();
    final reviewDate = createdAt.toDate();
    return now.difference(reviewDate).inDays <= 30;
  }

  // Get relative time string
  String get relativeTime {
    final now = DateTime.now();
    final reviewDate = createdAt.toDate();
    final difference = now.difference(reviewDate);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year${(difference.inDays / 365).floor() > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month${(difference.inDays / 30).floor() > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  // Get rating percentage for UI display
  double get ratingPercentage => (rating / 5) * 100;

  // Check if feedback length is within limits
  bool get hasValidLength {
    return feedback.length >= 10 && feedback.length <= 500;
  }

  // Get feedback preview
  String get feedbackPreview {
    if (feedback.length <= 100) return feedback;
    return '${feedback.substring(0, 100)}...';
  }
}

class ReviewSummary {
  final double averageRating;
  final int totalReviews;
  final int fiveStarCount;
  final int fourStarCount;
  final int threeStarCount;
  final int twoStarCount;
  final int oneStarCount;
  final List<ReviewModel> recentReviews;

  const ReviewSummary({
    required this.averageRating,
    required this.totalReviews,
    required this.fiveStarCount,
    required this.fourStarCount,
    required this.threeStarCount,
    required this.twoStarCount,
    required this.oneStarCount,
    required this.recentReviews,
  });

  // Factory constructor to create empty review summary
  factory ReviewSummary.empty() {
    return const ReviewSummary(
      averageRating: 0.0,
      totalReviews: 0,
      fiveStarCount: 0,
      fourStarCount: 0,
      threeStarCount: 0,
      twoStarCount: 0,
      oneStarCount: 0,
      recentReviews: [],
    );
  }

  // Factory constructor to create ReviewSummary from list of reviews
  factory ReviewSummary.fromReviews(List<ReviewModel> reviews) {
    if (reviews.isEmpty) return ReviewSummary.empty();

    final totalReviews = reviews.length;
    final totalRating = reviews.fold<double>(0, (sum, review) => sum + review.rating);
    final averageRating = totalRating / totalReviews;

    final fiveStarCount = reviews.where((r) => r.rating == 5).length;
    final fourStarCount = reviews.where((r) => r.rating == 4).length;
    final threeStarCount = reviews.where((r) => r.rating == 3).length;
    final twoStarCount = reviews.where((r) => r.rating == 2).length;
    final oneStarCount = reviews.where((r) => r.rating == 1).length;

    // Sort reviews by date (newest first) and take recent ones
    final sortedReviews = List<ReviewModel>.from(reviews)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final recentReviews = sortedReviews.take(10).toList();

    return ReviewSummary(
      averageRating: averageRating,
      totalReviews: totalReviews,
      fiveStarCount: fiveStarCount,
      fourStarCount: fourStarCount,
      threeStarCount: threeStarCount,
      twoStarCount: twoStarCount,
      oneStarCount: oneStarCount,
      recentReviews: recentReviews,
    );
  }

  // Getters for computed properties
  String get formattedAverageRating => averageRating.toStringAsFixed(1);
  String get totalReviewsText => '$totalReviews review${totalReviews != 1 ? 's' : ''}';
  bool get hasReviews => totalReviews > 0;

  // Get percentage for each rating level
  double get fiveStarPercentage => totalReviews > 0 ? (fiveStarCount / totalReviews) * 100 : 0;
  double get fourStarPercentage => totalReviews > 0 ? (fourStarCount / totalReviews) * 100 : 0;
  double get threeStarPercentage => totalReviews > 0 ? (threeStarCount / totalReviews) * 100 : 0;
  double get twoStarPercentage => totalReviews > 0 ? (twoStarCount / totalReviews) * 100 : 0;
  double get oneStarPercentage => totalReviews > 0 ? (oneStarCount / totalReviews) * 100 : 0;

  @override
  String toString() {
    return 'ReviewSummary(averageRating: $formattedAverageRating, totalReviews: $totalReviews)';
  }
}

// Extension for review summary utility methods
extension ReviewSummaryExtension on ReviewSummary {
  // Get rating distribution for UI
  List<Map<String, dynamic>> get ratingDistribution {
    return [
      {'rating': 5, 'count': fiveStarCount, 'percentage': fiveStarPercentage},
      {'rating': 4, 'count': fourStarCount, 'percentage': fourStarPercentage},
      {'rating': 3, 'count': threeStarCount, 'percentage': threeStarPercentage},
      {'rating': 2, 'count': twoStarCount, 'percentage': twoStarPercentage},
      {'rating': 1, 'count': oneStarCount, 'percentage': oneStarPercentage},
    ];
  }

  // Get rating stars display
  String get ratingStarsDisplay {
    final fullStars = averageRating.floor();
    final hasHalfStar = (averageRating - fullStars) >= 0.5;
    final emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0);

    return '⭐' * fullStars + (hasHalfStar ? '⭐' : '') + '☆' * emptyStars;
  }

  // Check if rating is excellent (4.5+)
  bool get isExcellentRating => averageRating >= 4.5;

  // Check if rating is good (4.0+)
  bool get isGoodRating => averageRating >= 4.0;

  // Check if rating is average (3.0+)
  bool get isAverageRating => averageRating >= 3.0;

  // Check if rating is poor (below 3.0)
  bool get isPoorRating => averageRating < 3.0;
}
