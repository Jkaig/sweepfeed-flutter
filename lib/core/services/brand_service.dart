import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/brand_model.dart';
import '../utils/logger.dart';

class BrandService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Brand>> getAllBrands() async {
    try {
      final querySnapshot =
          await _firestore.collection('brands').orderBy('name').get();

      return querySnapshot.docs.map(Brand.fromFirestore).toList();
    } catch (e) {
      logger.e('Error fetching brands', error: e);
      return [];
    }
  }

  Future<List<Brand>> getBrandsFromSponsors() async {
    try {
      final contestsSnapshot = await _firestore.collection('contests').get();

      final uniqueBrands = <String, Brand>{};

      for (final doc in contestsSnapshot.docs) {
        final data = doc.data();
        final sponsor = data['sponsor'] as String?;
        final sponsorWebsite = data['sponsorWebsite'] as String?;
        final imageUrl = data['imageUrl'] as String?;

        if (sponsor != null && sponsor.isNotEmpty) {
          final brandId = sponsor.toLowerCase().replaceAll(' ', '_');

          if (!uniqueBrands.containsKey(brandId)) {
            uniqueBrands[brandId] = Brand(
              id: brandId,
              name: sponsor,
              logoUrl: imageUrl,
              website: sponsorWebsite,
              contestCount: 1,
            );
          } else {
            final existing = uniqueBrands[brandId]!;
            uniqueBrands[brandId] = existing.copyWith(
              contestCount: existing.contestCount + 1,
            );
          }
        }
      }

      final brands = uniqueBrands.values.toList();
      brands.sort((a, b) => a.name.compareTo(b.name));
      return brands;
    } catch (e) {
      logger.e('Error fetching brands from sponsors', error: e);
      return [];
    }
  }

  Future<List<Brand>> searchBrands(String query) async {
    if (query.isEmpty) {
      return getAllBrands();
    }

    try {
      final brands = await getBrandsFromSponsors();

      return brands
          .where(
              (brand) => brand.name.toLowerCase().contains(query.toLowerCase()),)
          .toList();
    } catch (e) {
      logger.e('Error searching brands', error: e);
      return [];
    }
  }

  Future<Brand?> getBrandById(String brandId) async {
    try {
      final doc = await _firestore.collection('brands').doc(brandId).get();

      if (doc.exists) {
        return Brand.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      logger.e('Error fetching brand', error: e);
      return null;
    }
  }

  Stream<List<Brand>> watchBrands() =>
      _firestore.collection('brands').orderBy('name').snapshots().map(
            (snapshot) => snapshot.docs.map(Brand.fromFirestore).toList(),
          );
}
