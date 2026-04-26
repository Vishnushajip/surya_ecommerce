import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../../core/services/firebase_service.dart';
import '../../core/constants/app_constants.dart';

class ProductRepository {
  final FirebaseFirestore _firestore;

  ProductRepository(FirebaseService firebaseService)
    : _firestore = firebaseService.firestore;

  static ProductsPage productsPage({
    required List<ProductModel> items,
    required DocumentSnapshot? lastDocument,
    required bool hasMore,
  }) =>
      ProductsPage(items: items, lastDocument: lastDocument, hasMore: hasMore);

  Future<void> addProduct(ProductModel product) async {
    try {
      await _firestore
          .collection(AppConstants.productsCollection)
          .doc(product.id)
          .set(product.toFirestore());
    } catch (e) {
      throw Exception('Failed to add product: $e');
    }
  }

  Future<List<ProductModel>> getProducts({
    int limit = AppConstants.defaultPageSize,
    DocumentSnapshot? startAfter,
    String? category,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    String sortBy = 'listedDate',
    bool descending = true,
    bool? featured,
  }) async {
    final page = await getProductsPage(
      limit: limit,
      startAfter: startAfter,
      category: category,
      minPrice: minPrice,
      maxPrice: maxPrice,
      minRating: minRating,
      sortBy: sortBy,
      descending: descending,
      featured: featured,
    );
    return page.items;
  }

  Future<ProductsPage> getProductsPage({
    int limit = AppConstants.defaultPageSize,
    DocumentSnapshot? startAfter,
    String? category,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    String sortBy = 'listedDate',
    bool descending = true,
    bool? featured,
  }) async {
    try {
      Query query = _firestore
          .collection(AppConstants.productsCollection)
          .where('isActive', isEqualTo: true);

      if (featured != null) {
        query = query.where('featured', isEqualTo: featured);
      }

      if (category != null && category.isNotEmpty) {
        query = query.where('productCategory', isEqualTo: category);
      }

      if (minPrice != null) {
        query = query.where('price', isGreaterThanOrEqualTo: minPrice);
      }

      if (maxPrice != null) {
        query = query.where('price', isLessThanOrEqualTo: maxPrice);
      }

      if (minRating != null) {
        query = query.where('ratingAverage', isGreaterThanOrEqualTo: minRating);
      }

      query = query.orderBy(sortBy, descending: descending);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final pageLimit = limit.clamp(1, AppConstants.maxPageSize);
      final querySnapshot = await query.limit(pageLimit + 1).get();

      final docs = querySnapshot.docs;
      final hasMore = docs.length > pageLimit;
      final pageDocs = hasMore ? docs.take(pageLimit).toList() : docs;

      final items = pageDocs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
      final lastDocument = pageDocs.isEmpty ? startAfter : pageDocs.last;

      return ProductsPage(
        items: items,
        lastDocument: lastDocument,
        hasMore: hasMore,
      );
    } catch (e) {
      throw Exception('Failed to get products page: $e');
    }
  }

  Future<List<ProductModel>> getFeaturedProducts({int limit = 10}) async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.productsCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('ratingAverage', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get featured products: $e');
    }
  }

  Future<ProductModel?> getProductById(String productId) async {
    try {
      final docSnapshot = await _firestore
          .collection(AppConstants.productsCollection)
          .doc(productId)
          .get();

      if (!docSnapshot.exists) return null;

      final product = ProductModel.fromFirestore(docSnapshot);
      return product.isActive ? product : null;
    } catch (e) {
      throw Exception('Failed to get product: $e');
    }
  }

  Future<List<ProductModel>> searchProducts({
    required String query,
    int limit = AppConstants.maxSearchResults,
    String? category,
  }) async {
    try {
      Query firestoreQuery = _firestore
          .collection(AppConstants.productsCollection)
          .where('isActive', isEqualTo: true);

      if (category != null && category.isNotEmpty) {
        firestoreQuery = firestoreQuery.where(
          'productCategory',
          isEqualTo: category,
        );
      }

      final querySnapshot = await firestoreQuery
          .orderBy('productName')
          .limit(AppConstants.maxPageSize * 2)
          .get();

      final products = querySnapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .where((product) => _matchesSearchQuery(product, query.toLowerCase()))
          .take(limit)
          .toList();

      return products;
    } catch (e) {
      throw Exception('Failed to search products: $e');
    }
  }

  Future<List<ProductModel>> getProductsByCategory(
    String id, {
    int limit = 10,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore
          .collection(AppConstants.productsCollection)
          .where('productCategory', isEqualTo: id);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      query = query.limit(limit);

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print("ERROR => $e");
      throw Exception('Failed to get products by category: $e');
    }
  }

  Future<List<ProductModel>> getProductsBySubCategory(
    String subCategoryId, {
    int limit = 10,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore
          .collection(AppConstants.productsCollection)
          .where('subCategoryId', isEqualTo: subCategoryId);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      query = query.limit(limit);

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print("ERROR => $e");
      throw Exception('Failed to get products by sub-category: $e');
    }
  }

  Future<List<ProductModel>> getRelatedProducts(
    String productId,
    String category, {
    int limit = 6,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.productsCollection)
          .where('isActive', isEqualTo: true)
          .where('productCategory', isEqualTo: category)
          .where(FieldPath.documentId, isNotEqualTo: productId)
          .orderBy('ratingAverage', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get related products: $e');
    }
  }

  Future<List<String>> getAllCategories() async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.productsCollection)
          .where('isActive', isEqualTo: true)
          .get();

      final categories = querySnapshot.docs
          .map((doc) => doc['productCategory'] as String)
          .toSet()
          .toList();

      categories.sort();
      return categories;
    } catch (e) {
      throw Exception('Failed to get categories: $e');
    }
  }

  Future<Map<String, double>> getPriceRange({String? category}) async {
    try {
      Query query = _firestore
          .collection(AppConstants.productsCollection)
          .where('isActive', isEqualTo: true);

      if (category != null && category.isNotEmpty) {
        query = query.where('productCategory', isEqualTo: category);
      }

      final querySnapshot = await query.get();

      if (querySnapshot.docs.isEmpty) {
        return {'min': 0.0, 'max': 0.0};
      }

      final prices = querySnapshot.docs
          .map((doc) => (doc['price'] as num).toDouble())
          .toList();

      final minPrice = prices.reduce((a, b) => a < b ? a : b);
      final maxPrice = prices.reduce((a, b) => a > b ? a : b);

      return {'min': minPrice, 'max': maxPrice};
    } catch (e) {
      throw Exception('Failed to get price range: $e');
    }
  }

  Stream<List<ProductModel>> streamProducts({
    String? category,
    int limit = AppConstants.defaultPageSize,
  }) {
    Query query = _firestore
        .collection(AppConstants.productsCollection)
        .where('isActive', isEqualTo: true)
        .orderBy('listedDate', descending: true)
        .limit(limit);

    if (category != null && category.isNotEmpty) {
      query = query.where('productCategory', isEqualTo: category);
    }

    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => ProductModel.fromFirestore(doc)).toList(),
    );
  }

  Stream<List<ProductModel>> streamFeaturedProducts({int limit = 10}) {
    return _firestore
        .collection(AppConstants.productsCollection)
        .where('isActive', isEqualTo: true)
        .where('featured', isEqualTo: true)
        .orderBy('ratingAverage', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ProductModel.fromFirestore(doc))
              .toList(),
        );
  }

  Stream<ProductModel?> streamProduct(String productId) {
    return _firestore
        .collection(AppConstants.productsCollection)
        .doc(productId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          final product = ProductModel.fromFirestore(doc);
          return product.isActive ? product : null;
        });
  }

  Future<void> updateProduct(ProductModel product) async {
    try {
      await _firestore
          .collection(AppConstants.productsCollection)
          .doc(product.id)
          .update(product.toFirestore());
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      await _firestore
          .collection(AppConstants.productsCollection)
          .doc(productId)
          .update({'isActive': false});
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  Future<void> seedDummyProducts(List<ProductModel> products) async {
    try {
      final batch = _firestore.batch();

      for (final product in products) {
        final docRef = _firestore
            .collection(AppConstants.productsCollection)
            .doc(product.id);
        batch.set(docRef, product.toFirestore());
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to seed dummy products: $e');
    }
  }

  bool _matchesSearchQuery(ProductModel product, String query) {
    return product.productName.toLowerCase().contains(query) ||
        product.productCategory.toLowerCase().contains(query) ||
        product.description.toLowerCase().contains(query);
  }

  Future<Map<String, dynamic>> getProductStatistics() async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.productsCollection)
          .where('isActive', isEqualTo: true)
          .get();

      final totalProducts = querySnapshot.docs.length;
      final featuredProducts = querySnapshot.docs
          .where((doc) => doc['featured'] == true)
          .length;

      final totalStock = querySnapshot.docs.fold<int>(
        0,
        (sum, doc) => sum + (doc['quantity'] as int),
      );

      final averagePrice = querySnapshot.docs.isEmpty
          ? 0.0
          : querySnapshot.docs.fold<double>(
                  0,
                  (sum, doc) => sum + (doc['price'] as num).toDouble(),
                ) /
                totalProducts;

      final averageRating = querySnapshot.docs.isEmpty
          ? 0.0
          : querySnapshot.docs.fold<double>(
                  0,
                  (sum, doc) => sum + (doc['ratingAverage'] as num).toDouble(),
                ) /
                totalProducts;

      return {
        'totalProducts': totalProducts,
        'featuredProducts': featuredProducts,
        'totalStock': totalStock,
        'averagePrice': averagePrice,
        'averageRating': averageRating,
      };
    } catch (e) {
      throw Exception('Failed to get product statistics: $e');
    }
  }
}

class ProductsPage {
  final List<ProductModel> items;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;

  const ProductsPage({
    required this.items,
    required this.lastDocument,
    required this.hasMore,
  });
}
