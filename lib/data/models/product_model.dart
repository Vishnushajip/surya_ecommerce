import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String productName;
  final String productCategory;
  final String? categoryId;
  final String description;
  final double price;
  final List<String> imageUrls;
  final int quantity;
  final Timestamp createdDate;
  final Timestamp listedDate;
  final double ratingAverage;
  final int ratingCount;
  final Timestamp? manufacturingDate;
  final Timestamp? expiryDate;
  final bool featured;
  final bool isActive;

  const ProductModel({
    required this.id,
    required this.productName,
    required this.productCategory,
    this.categoryId,
    required this.description,
    required this.price,
    required this.imageUrls,
    required this.quantity,
    required this.createdDate,
    required this.listedDate,
    required this.ratingAverage,
    required this.ratingCount,
    this.manufacturingDate,
    this.expiryDate,
    required this.featured,
    required this.isActive,
  });

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ProductModel(
      id: doc.id,
      productName: data['productName'] ?? '',
      productCategory: data['categoryName'] ?? '',
      categoryId: data['productCategory'],
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      quantity: data['quantity'] ?? 0,
      createdDate: data['createdDate'] ?? Timestamp.now(),
      listedDate: data['listedDate'] ?? Timestamp.now(),
      ratingAverage: (data['ratingAverage'] ?? 0).toDouble(),
      ratingCount: data['ratingCount'] ?? 0,
      manufacturingDate: data['manufacturingDate'] != null
          ? data['manufacturingDate'] as Timestamp
          : null,
      expiryDate: data['expiryDate'] != null
          ? data['expiryDate'] as Timestamp
          : null,
      featured: data['featured'] ?? false,
      isActive: data['isActive'] ?? true,
    );
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: (json['id'] as String?) ?? '',
      productName: (json['productName'] as String?) ?? '',
      productCategory: (json['categoryName'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      imageUrls: json['imageUrls'] != null
          ? List<String>.from(json['imageUrls'] as List)
          : [],
      quantity: (json['quantity'] as int?) ?? 0,
      createdDate: json['createdDate'] != null
          ? Timestamp.fromDate(DateTime.parse(json['createdDate'] as String))
          : Timestamp.now(),
      listedDate: json['listedDate'] != null
          ? Timestamp.fromDate(DateTime.parse(json['listedDate'] as String))
          : Timestamp.now(),
      ratingAverage: (json['ratingAverage'] as num?)?.toDouble() ?? 0.0,
      ratingCount: (json['ratingCount'] as int?) ?? 0,
      manufacturingDate: json['manufacturingDate'] != null
          ? Timestamp.fromDate(
              DateTime.parse(json['manufacturingDate'] as String),
            )
          : null,
      expiryDate: json['expiryDate'] != null
          ? Timestamp.fromDate(DateTime.parse(json['expiryDate'] as String))
          : null,
      featured: (json['featured'] as bool?) ?? false,
      isActive: (json['isActive'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'productName': productName,
      'productCategory': productCategory,
      'categoryId': categoryId,
      'description': description,
      'price': price,
      'imageUrls': imageUrls,
      'quantity': quantity,
      'createdDate': createdDate,
      'listedDate': listedDate,
      'ratingAverage': ratingAverage,
      'ratingCount': ratingCount,
      if (manufacturingDate != null) 'manufacturingDate': manufacturingDate,
      if (expiryDate != null) 'expiryDate': expiryDate,
      'featured': featured,
      'isActive': isActive,
    };
  }

  ProductModel copyWith({
    String? id,
    String? productName,
    String? productCategory,
    String? description,
    double? price,
    List<String>? imageUrls,
    int? quantity,
    Timestamp? createdDate,
    Timestamp? listedDate,
    double? ratingAverage,
    int? ratingCount,
    Timestamp? manufacturingDate,
    Timestamp? expiryDate,
    bool? featured,
    bool? isActive,
  }) {
    return ProductModel(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      productCategory: productCategory ?? this.productCategory,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrls: imageUrls ?? this.imageUrls,
      quantity: quantity ?? this.quantity,
      createdDate: createdDate ?? this.createdDate,
      listedDate: listedDate ?? this.listedDate,
      ratingAverage: ratingAverage ?? this.ratingAverage,
      ratingCount: ratingCount ?? this.ratingCount,
      manufacturingDate: manufacturingDate ?? this.manufacturingDate,
      expiryDate: expiryDate ?? this.expiryDate,
      featured: featured ?? this.featured,
      isActive: isActive ?? this.isActive,
    );
  }

  String get formattedPrice => '₹${price.toStringAsFixed(2)}';
  String get formattedRating => ratingAverage.toStringAsFixed(1);
  bool get hasImages => imageUrls.isNotEmpty;
  String get firstImageUrl => imageUrls.isNotEmpty ? imageUrls.first : '';
  bool get isInStock => quantity > 0 && isActive;
  bool get isExpired =>
      expiryDate != null && expiryDate!.toDate().isBefore(DateTime.now());
  bool get hasManufacturingDate => manufacturingDate != null;
  bool get hasExpiryDate => expiryDate != null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productName': productName,
      'categoryName': productCategory,
      'description': description,
      'price': price,
      'imageUrls': imageUrls,
      'quantity': quantity,
      'createdDate': createdDate.toDate().toIso8601String(),
      'listedDate': listedDate.toDate().toIso8601String(),
      'ratingAverage': ratingAverage,
      'ratingCount': ratingCount,
      'manufacturingDate': manufacturingDate?.toDate().toIso8601String(),
      'expiryDate': expiryDate?.toDate().toIso8601String(),
      'featured': featured,
      'isActive': isActive,
      'formattedPrice': formattedPrice,
      'formattedRating': formattedRating,
      'hasImages': hasImages,
      'firstImageUrl': firstImageUrl,
      'isInStock': isInStock,
      'isExpired': isExpired,
    };
  }

  @override
  String toString() {
    return 'ProductModel(id: $id, productName: $productName, productCategory: $productCategory, price: $price)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

extension ProductModelExtension on ProductModel {
  double getSearchRelevance(String query) {
    final lowerQuery = query.toLowerCase();
    double score = 0;

    if (productName.toLowerCase() == lowerQuery) score += 100;

    if (productName.toLowerCase().contains(lowerQuery)) score += 50;
    if (productCategory.toLowerCase().contains(lowerQuery)) score += 30;

    if (description.toLowerCase().contains(lowerQuery)) score += 20;

    return score;
  }

  bool matchesAnyCategory(List<String> categories) {
    return categories.any(
      (category) => productCategory.toLowerCase() == category.toLowerCase(),
    );
  }

  bool isInPriceRange(double minPrice, double maxPrice) {
    return price >= minPrice && price <= maxPrice;
  }

  bool hasMinimumRating(double minRating) {
    return ratingAverage >= minRating;
  }

  String get formattedCreatedDate {
    return '${createdDate.toDate().day}-${createdDate.toDate().month}-${createdDate.toDate().year}';
  }

  String get formattedListedDate {
    return '${listedDate.toDate().day}-${listedDate.toDate().month}-${listedDate.toDate().year}';
  }

  String? get formattedManufacturingDate {
    if (manufacturingDate == null) return null;
    final date = manufacturingDate!.toDate();
    return '${date.day}-${date.month}-${date.year}';
  }

  String? get formattedExpiryDate {
    if (expiryDate == null) return null;
    final date = expiryDate!.toDate();
    return '${date.day}-${date.month}-${date.year}';
  }
}
