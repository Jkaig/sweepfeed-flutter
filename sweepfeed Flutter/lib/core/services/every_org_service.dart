import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../utils/logger.dart';

class EveryOrgService {
  static const String baseUrl = 'https://partners.every.org/v0.2';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String get _publicKey => dotenv.env['EVERY_ORG_PUBLIC_KEY'] ?? '';
  String get _privateKey => dotenv.env['EVERY_ORG_PRIVATE_KEY'] ?? '';

  String get _authHeader {
    final credentials = base64Encode(utf8.encode('$_publicKey:$_privateKey'));
    return 'Basic $credentials';
  }

  Future<List<Map<String, dynamic>>> searchNonprofits(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/search/$query'),
        headers: {
          'Authorization': _authHeader,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['nonprofits'] ?? []);
      } else {
        throw Exception('Failed to search nonprofits: ${response.statusCode}');
      }
    } catch (e) {
      logger.e('Error searching nonprofits', error: e);
      return [];
    }
  }

  /// Get detailed nonprofit information including verification status
  Future<Map<String, dynamic>?> getNonprofitDetails(
    String nonprofitSlug,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/nonprofit/$nonprofitSlug'),
        headers: {
          'Authorization': _authHeader,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'slug': data['slug'],
          'name': data['name'],
          'description': data['description'],
          'logoUrl': data['logoUrl'],
          'coverImageUrl': data['coverImageUrl'],
          'websiteUrl': data['websiteUrl'],
          'ein': data['ein'], // Tax ID number
          'classification': data['nteeCode'], // NTEE classification
          'tags': data['tags'] ?? [],
          'locationAddress': data['locationAddress'],
          'primaryCategory': data['primaryCategory'],
          'isVerified': data['ein'] != null, // Has EIN = verified 501(c)(3)
          'matchedTerms': data['matchedTerms'] ?? [],
        };
      } else {
        throw Exception(
          'Failed to get nonprofit details: ${response.statusCode}',
        );
      }
    } catch (e) {
      logger.e('Error getting nonprofit details', error: e);
      return null;
    }
  }

  Future<String?> createFundraiser({
    required String nonprofitSlug,
    required String fundraiserTitle,
    String? description,
    double? goalAmount,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/fundraiser'),
        headers: {
          'Authorization': _authHeader,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'nonprofitSlug': nonprofitSlug,
          'title': fundraiserTitle,
          if (description != null) 'description': description,
          if (goalAmount != null) 'goalAmount': goalAmount,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['fundraiser']?['id'];
      } else {
        throw Exception('Failed to create fundraiser: ${response.statusCode}');
      }
    } catch (e) {
      logger.e('Error creating fundraiser', error: e);
      return null;
    }
  }

  Future<double> getFundraiserAmount({
    required String nonprofitSlug,
    required String fundraiserSlug,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/nonprofit/$nonprofitSlug/fundraiser/$fundraiserSlug/raised',
        ),
        headers: {
          'Authorization': _authHeader,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['amountRaised'] as num?)?.toDouble() ?? 0.0;
      } else {
        throw Exception(
          'Failed to get fundraiser amount: ${response.statusCode}',
        );
      }
    } catch (e) {
      logger.e('Error getting fundraiser amount', error: e);
      return 0.0;
    }
  }

  Future<void> processDonation({
    required String userId,
    required String nonprofitSlug,
    required double amount,
    required String source,
  }) async {
    try {
      final batch = _firestore.batch();

      final donationRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('donations')
          .doc();

      batch.set(donationRef, {
        'nonprofitSlug': nonprofitSlug,
        'amount': amount,
        'source': source,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'completed',
      });

      final userRef = _firestore.collection('users').doc(userId);
      batch.update(userRef, {
        'totalCharityContributed': FieldValue.increment(amount),
      });

      final nonprofitRef =
          _firestore.collection('every_org_nonprofits').doc(nonprofitSlug);
      batch.set(
        nonprofitRef,
        {
          'slug': nonprofitSlug,
          'totalDonated': FieldValue.increment(amount),
          'donationCount': FieldValue.increment(1),
          'lastDonationAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      final communityRef = _firestore.collection('stats').doc('community');
      batch.set(
        communityRef,
        {
          'totalDonated': FieldValue.increment(amount),
          'donationCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await batch.commit();
      logger.i(
          'Donation processed: \$$amount to $nonprofitSlug for user $userId');
    } catch (e) {
      logger.e('Error processing donation', error: e);
      rethrow;
    }
  }

  String getDonateUrl({
    required String nonprofitSlug,
    double? amount,
    String? frequency,
    String? privateNote,
  }) {
    final params = <String, String>{};
    if (amount != null) params['amount'] = amount.toString();
    if (frequency != null) params['frequency'] = frequency;
    if (privateNote != null) params['privateNote'] = privateNote;

    final queryString = params.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');

    return 'https://www.every.org/$nonprofitSlug${queryString.isNotEmpty ? '?$queryString' : ''}';
  }
}
