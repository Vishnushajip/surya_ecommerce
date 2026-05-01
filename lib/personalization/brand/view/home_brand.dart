import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BrandModel {
  final String id;
  final String name;
  final String imageUrl;
  final bool isActive;
  final int productCount;

  const BrandModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.isActive = true,
    this.productCount = 0,
  });

  BrandModel copyWith({int? productCount}) {
    return BrandModel(
      id: id,
      name: name,
      imageUrl: imageUrl,
      isActive: isActive,
      productCount: productCount ?? this.productCount,
    );
  }

  factory BrandModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BrandModel(
      id: (data['id'] as String?) ?? doc.id,
      name: (data['name'] as String?) ?? '',
      imageUrl: (data['imageUrl'] as String?) ?? '',
      isActive: (data['isActive'] as bool?) ?? true,
    );
  }
}

final brandsProvider = FutureProvider<List<BrandModel>>((ref) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('brands')
      .where('isActive', isEqualTo: true)
      .get();

  return snapshot.docs.map((doc) => BrandModel.fromFirestore(doc)).toList();
});

final brandsByCategoryProvider =
    FutureProvider.family<List<BrandModel>, String>((ref, categoryId) async {
      final productsSnap = await FirebaseFirestore.instance
          .collection('products')
          .where('productCategory', isEqualTo: categoryId)
          .where('isActive', isEqualTo: true)
          .get();

      final brandIds = <String>{};
      final brandNames = <String, String>{};
      for (final doc in productsSnap.docs) {
        final data = doc.data();
        final bId = data['brandId'] as String?;
        final bName = data['brandName'] as String?;
        if (bId == null || bId.isEmpty) continue;
        brandIds.add(bId);
        if (bName != null && bName.isNotEmpty) brandNames[bId] = bName;
      }

      if (brandIds.isEmpty) return [];

      final allBrands = await ref.watch(brandsProvider.future);
      final byId = {for (final b in allBrands) b.id: b};

      final result = <BrandModel>[];
      for (final id in brandIds) {
        final base = byId[id];
        if (base != null) {
          result.add(base);
        } else {
          result.add(
            BrandModel(id: id, name: brandNames[id] ?? '', imageUrl: ''),
          );
        }
      }

      result.sort((a, b) => a.name.compareTo(b.name));
      return result;
    });
