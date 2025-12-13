import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/logger.dart';
import '../models/support_ticket_model.dart';

final supportServiceProvider = Provider<SupportService>((ref) => SupportService());

class SupportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'support_tickets';

  Future<void> createTicket({
    required String userId,
    required String userName,
    required String userEmail,
    required String message,
  }) async {
    try {
      await _firestore.collection(_collection).add({
        'userId': userId,
        'userName': userName,
        'userEmail': userEmail,
        'message': message,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      logger.i('Support ticket created for user: $userEmail');
    } catch (e) {
      logger.e('Error creating support ticket', error: e);
      rethrow;
    }
  }

  Stream<List<SupportTicket>> getTickets() => _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(SupportTicket.fromFirestore).toList());

  Future<void> updateTicketStatus(String ticketId, String status) async {
    try {
      await _firestore.collection(_collection).doc(ticketId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      logger.i('Support ticket $ticketId status updated to $status');
    } catch (e) {
      logger.e('Error updating support ticket status', error: e);
      rethrow;
    }
  }

  Future<void> addAdminNote(String ticketId, String note) async {
    try {
      await _firestore.collection(_collection).doc(ticketId).update({
        'adminNotes': note,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      logger.i('Admin note added to ticket $ticketId');
    } catch (e) {
      logger.e('Error adding admin note', error: e);
      rethrow;
    }
  }
}
