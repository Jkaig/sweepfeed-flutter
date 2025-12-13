import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:sweepfeed/core/services/dust_bunnies_service.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/entry_model.dart';
import '../../../core/models/sweepstake.dart';
import '../../../core/utils/logger.dart';
import '../../challenges/models/daily_challenge_model.dart';
import '../../challenges/services/daily_challenge_service.dart';

class EntryManagementService {
  EntryManagementService(this._dustBunniesService, this._challengeService);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();
  final DustBunniesService _dustBunniesService;
  final DailyChallengeService _challengeService;

  // Collections
  CollectionReference get _entriesCollection =>
      _firestore.collection('contest_entries');
  CollectionReference get _receiptsCollection =>
      _firestore.collection('entry_receipts');
  CollectionReference get _bulkEntriesCollection =>
      _firestore.collection('bulk_entries');

  /// Submit a single contest entry
  Future<ContestEntry> submitEntry({
    required Sweepstakes sweepstake,
    required EntryMethod method,
    Map<String, dynamic> additionalData = const {},
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to submit entries');
    }

    final now = DateTime.now();
    final confirmationCode = _generateConfirmationCode();

    // Check if user can enter (for daily entries)
    if (sweepstake.isDailyEntry == true) {
      final canEnter = await _canUserEnterDaily(user.uid, sweepstake.id);
      if (!canEnter) {
        throw Exception('You have already entered this contest today');
      }
    }

    final entry = ContestEntry(
      id: '',
      userId: user.uid,
      contestId: sweepstake.id,
      contestTitle: sweepstake.title,
      entryDate: now,
      status: EntryStatus.pending,
      method: method,
      entryData: {
        'prizeValue': sweepstake.value,
        'sponsor': sweepstake.sponsor,
        'entryUrl': sweepstake.entryUrl,
        ...additionalData,
      },
      confirmationCode: confirmationCode,
      isDailyEntry: sweepstake.isDailyEntry ?? false,
      nextEntryAllowed:
          sweepstake.isDailyEntry == true ? now.add(const Duration(days: 1)) : null,
      createdAt: now,
      updatedAt: now,
    );

    // Save entry to Firestore
    final docRef = await _entriesCollection.add(entry.toFirestore());
    final savedEntry = entry.copyWith(id: docRef.id);

    // Generate and save receipt
    await _generateEntryReceipt(savedEntry);

    // Update entry status to confirmed (in real app, this might be done after external verification)
    await _updateEntryStatus(docRef.id, EntryStatus.confirmed);

    // Award DustBunnies for contest entry
    try {
      await _dustBunniesService.awardDustBunnies(
        userId: user.uid,
        action: 'contest_entry',
      );
      logger.i('Awarded contest entry DustBunnies to user ${user.uid}');
    } catch (e) {
      logger.e('Failed to award contest entry DustBunnies', error: e);
    }

    // Update daily challenge progress
    try {
      await _challengeService.updateChallengeProgress(
        userId: user.uid,
        actionType: ChallengeType.enterContest,
      );
      logger.i('Updated daily challenge progress for contest entry');
    } catch (e) {
      logger.e('Failed to update daily challenge progress', error: e);
    }

    return savedEntry.copyWith(status: EntryStatus.confirmed);
  }

  /// Submit bulk entries for multiple contests
  Future<List<ContestEntry>> submitBulkEntries({
    required List<Sweepstakes> contests,
    required EntryMethod method,
    Map<String, dynamic> globalData = const {},
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to submit entries');
    }

    final now = DateTime.now();
    final bulkId = _uuid.v4();
    final entries = <ContestEntry>[];
    final batch = _firestore.batch();

    // Create bulk entry record
    final bulkEntryDoc = _bulkEntriesCollection.doc(bulkId);
    batch.set(bulkEntryDoc, {
      'userId': user.uid,
      'contestCount': contests.length,
      'method': method.toString().split('.').last,
      'status': 'processing',
      'createdAt': FieldValue.serverTimestamp(),
    });

    for (final sweepstake in contests) {
      // Check daily entry limits
      if (sweepstake.isDailyEntry == true) {
        final canEnter = await _canUserEnterDaily(user.uid, sweepstake.id);
        if (!canEnter) {
          continue; // Skip this contest
        }
      }

      final confirmationCode = _generateConfirmationCode();
      final entryDoc = _entriesCollection.doc();

      final entry = ContestEntry(
        id: entryDoc.id,
        userId: user.uid,
        contestId: sweepstake.id,
        contestTitle: sweepstake.title,
        entryDate: now,
        status: EntryStatus.pending,
        method: method,
        entryData: {
          'prizeValue': sweepstake.value,
          'sponsor': sweepstake.sponsor,
          'entryUrl': sweepstake.entryUrl,
          'bulkId': bulkId,
          ...globalData,
        },
        confirmationCode: confirmationCode,
        isDailyEntry: sweepstake.isDailyEntry ?? false,
        nextEntryAllowed:
            sweepstake.isDailyEntry == true ? now.add(const Duration(days: 1)) : null,
        createdAt: now,
        updatedAt: now,
      );

      batch.set(entryDoc, entry.toFirestore());
      entries.add(entry);
    }

    // Commit all entries
    await batch.commit();

    // Generate bulk receipt
    await _generateBulkReceipt(bulkId, entries);

    // Update bulk status
    await bulkEntryDoc.update({
      'status': 'completed',
      'successfulEntries': entries.length,
      'completedAt': FieldValue.serverTimestamp(),
    });

    // Award DustBunnies for bulk entries
    try {
      final totalDBReward = entries.length * 25;
      await _dustBunniesService.awardDustBunnies(
        userId: user.uid,
        action: 'contest_entry',
        customAmount: totalDBReward,
      );
      logger.i(
          'Awarded $totalDBReward DustBunnies for ${entries.length} bulk entries to user ${user.uid}',);
    } catch (e) {
      logger.e('Failed to award bulk entry DustBunnies', error: e);
    }

    // Update daily challenge progress for bulk entries
    try {
      await _challengeService.updateChallengeProgress(
        userId: user.uid,
        actionType: ChallengeType.enterContest,
        incrementBy: entries.length,
      );
      logger.i(
          'Updated daily challenge progress for ${entries.length} bulk entries',);
    } catch (e) {
      logger.e('Failed to update daily challenge progress for bulk entries',
          error: e,);
    }

    // Update individual entry statuses
    for (final entry in entries) {
      await _updateEntryStatus(entry.id, EntryStatus.confirmed);
    }

    return entries
        .map((e) => e.copyWith(status: EntryStatus.confirmed))
        .toList();
  }

  /// Get user's entry history
  Future<List<ContestEntry>> getUserEntries({
    required String userId,
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
    EntryStatus? status,
  }) async {
    var query = _entriesCollection
        .where('userId', isEqualTo: userId)
        .orderBy('entryDate', descending: true);

    if (startDate != null) {
      query = query.where(
        'entryDate',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
      );
    }

    if (endDate != null) {
      query = query.where(
        'entryDate',
        isLessThanOrEqualTo: Timestamp.fromDate(endDate),
      );
    }

    if (status != null) {
      query =
          query.where('status', isEqualTo: status.toString().split('.').last);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    final snapshot = await query.get();
    return snapshot.docs.map(ContestEntry.fromFirestore).toList();
  }

  /// Get entries for a specific contest
  Future<List<ContestEntry>> getContestEntries({
    required String contestId,
    required String userId,
  }) async {
    final snapshot = await _entriesCollection
        .where('contestId', isEqualTo: contestId)
        .where('userId', isEqualTo: userId)
        .orderBy('entryDate', descending: true)
        .get();

    return snapshot.docs.map(ContestEntry.fromFirestore).toList();
  }

  /// Get stream of entered contest IDs for a user
  Stream<Set<String>> getEnteredContestIdsStream(String userId) {
    return _entriesCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['contestId'] as String)
          .toSet();
    });
  }

  /// Get entry by ID
  Future<ContestEntry?> getEntry(String entryId) async {
    final doc = await _entriesCollection.doc(entryId).get();
    if (doc.exists) {
      return ContestEntry.fromFirestore(doc);
    }
    return null;
  }

  /// Get entry receipt
  Future<EntryReceipt?> getEntryReceipt(String entryId) async {
    final snapshot = await _receiptsCollection
        .where('entryId', isEqualTo: entryId)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return EntryReceipt.fromFirestore(snapshot.docs.first);
    }
    return null;
  }

  /// Get user's entry receipts
  Future<List<EntryReceipt>> getUserReceipts(String userId) async {
    final snapshot = await _receiptsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map(EntryReceipt.fromFirestore).toList();
  }

  /// Get entry statistics for user
  Future<Map<String, dynamic>> getUserEntryStatistics(String userId) async {
    final snapshot =
        await _entriesCollection.where('userId', isEqualTo: userId).get();

    final entries = snapshot.docs.map(ContestEntry.fromFirestore).toList();

    final totalEntries = entries.length;
    final confirmedEntries = entries.where((e) => e.isConfirmed).length;
    final pendingEntries = entries.where((e) => e.isPending).length;
    final failedEntries = entries.where((e) => e.isFailed).length;

    final thisMonth = DateTime.now().month;
    final thisYear = DateTime.now().year;
    final thisMonthEntries = entries
        .where(
          (e) => e.entryDate.month == thisMonth && e.entryDate.year == thisYear,
        )
        .length;

    final last7Days = DateTime.now().subtract(const Duration(days: 7));
    final recentEntries =
        entries.where((e) => e.entryDate.isAfter(last7Days)).length;

    final totalPrizeValue = entries.fold<double>(
      0,
      (sum, entry) => sum + (entry.entryData['prizeValue'] as double? ?? 0),
    );

    return {
      'totalEntries': totalEntries,
      'confirmedEntries': confirmedEntries,
      'pendingEntries': pendingEntries,
      'failedEntries': failedEntries,
      'thisMonthEntries': thisMonthEntries,
      'recentEntries': recentEntries,
      'totalPrizeValue': totalPrizeValue,
      'successRate':
          totalEntries > 0 ? (confirmedEntries / totalEntries) * 100 : 0,
    };
  }

  /// Check if user can enter a daily contest
  Future<bool> _canUserEnterDaily(String userId, String contestId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await _entriesCollection
        .where('userId', isEqualTo: userId)
        .where('contestId', isEqualTo: contestId)
        .where(
          'entryDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where('entryDate', isLessThan: Timestamp.fromDate(endOfDay))
        .limit(1)
        .get();

    return snapshot.docs.isEmpty;
  }

  /// Update entry status
  Future<void> _updateEntryStatus(
    String entryId,
    EntryStatus status, {
    String? errorMessage,
  }) async {
    await _entriesCollection.doc(entryId).update({
      'status': status.toString().split('.').last,
      'updatedAt': FieldValue.serverTimestamp(),
      if (errorMessage != null) 'errorMessage': errorMessage,
    });
  }

  /// Generate confirmation code
  String _generateConfirmationCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    var result = '';
    for (var i = 0; i < 8; i++) {
      result += chars[(random + i) % chars.length];
    }
    return result;
  }

  /// Generate entry receipt
  Future<void> _generateEntryReceipt(ContestEntry entry) async {
    final html = _generateReceiptHtml(entry);
    final pdfBytes = await _generateReceiptPdf(entry);

    // Upload PDF to Firebase Storage
    final fileName =
        'receipt_${entry.id}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final ref = _storage.ref().child('receipts/${entry.userId}/$fileName');

    final uploadTask = await ref.putData(pdfBytes);
    final pdfUrl = await uploadTask.ref.getDownloadURL();

    // Save receipt to Firestore
    final receipt = EntryReceipt(
      id: '',
      entryId: entry.id,
      userId: entry.userId,
      contestId: entry.contestId,
      contestTitle: entry.contestTitle,
      entryDate: entry.entryDate,
      confirmationCode: entry.confirmationCode ?? '',
      receiptData: {
        'prizeValue': entry.entryData['prizeValue'],
        'sponsor': entry.entryData['sponsor'],
        'method': entry.methodDisplayText,
      },
      receiptHtml: html,
      receiptPdfUrl: pdfUrl,
      createdAt: DateTime.now(),
    );

    await _receiptsCollection.add(receipt.toFirestore());
  }

  /// Generate bulk receipt
  Future<void> _generateBulkReceipt(
    String bulkId,
    List<ContestEntry> entries,
  ) async {
    if (entries.isEmpty) return;

    final html = _generateBulkReceiptHtml(bulkId, entries);
    final pdfBytes = await _generateBulkReceiptPdf(bulkId, entries);

    // Upload PDF to Firebase Storage
    final fileName =
        'bulk_receipt_${bulkId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final ref =
        _storage.ref().child('receipts/${entries.first.userId}/$fileName');

    final uploadTask = await ref.putData(pdfBytes);
    final pdfUrl = await uploadTask.ref.getDownloadURL();

    // Save bulk receipt
    final receipt = EntryReceipt(
      id: '',
      entryId: bulkId,
      userId: entries.first.userId,
      contestId: 'bulk',
      contestTitle: 'Bulk Entry - ${entries.length} Contests',
      entryDate: entries.first.entryDate,
      confirmationCode: 'BULK-${_generateConfirmationCode()}',
      receiptData: {
        'contestCount': entries.length,
        'totalPrizeValue': entries.fold<double>(
          0,
          (sum, e) => sum + (e.entryData['prizeValue'] as double? ?? 0),
        ),
        'contests': entries
            .map(
              (e) => {
                'title': e.contestTitle,
                'confirmationCode': e.confirmationCode,
              },
            )
            .toList(),
      },
      receiptHtml: html,
      receiptPdfUrl: pdfUrl,
      createdAt: DateTime.now(),
    );

    await _receiptsCollection.add(receipt.toFirestore());
  }

  /// Generate receipt HTML
  String _generateReceiptHtml(ContestEntry entry) => '''
    <!DOCTYPE html>
    <html>
    <head>
        <title>Entry Receipt</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 20px; }
            .header { text-align: center; color: #2196F3; }
            .confirmation { background: #f0f0f0; padding: 15px; margin: 20px 0; }
            .details { margin: 20px 0; }
            .footer { text-align: center; color: #666; margin-top: 30px; }
        </style>
    </head>
    <body>
        <div class="header">
            <h1>🎉 SweepFeed Entry Receipt 🎉</h1>
        </div>
        
        <div class="confirmation">
            <h2>Confirmation Code: ${entry.confirmationCode}</h2>
            <p><strong>Status:</strong> ${entry.statusDisplayText}</p>
        </div>
        
        <div class="details">
            <h3>Contest Details</h3>
            <p><strong>Contest:</strong> ${entry.contestTitle}</p>
            <p><strong>Prize Value:</strong> \$${entry.entryData['prizeValue']}</p>
            <p><strong>Sponsor:</strong> ${entry.entryData['sponsor']}</p>
            <p><strong>Entry Date:</strong> ${_formatDate(entry.entryDate)}</p>
            <p><strong>Entry Method:</strong> ${entry.methodDisplayText}</p>
        </div>
        
        <div class="footer">
            <p>Thank you for using SweepFeed!</p>
            <p>Keep this receipt for your records.</p>
        </div>
    </body>
    </html>
    ''';

  /// Generate bulk receipt HTML
  String _generateBulkReceiptHtml(String bulkId, List<ContestEntry> entries) {
    final contestsHtml = entries
        .map(
          (entry) => '''
        <tr>
            <td>${entry.contestTitle}</td>
            <td>${entry.confirmationCode}</td>
            <td>\$${entry.entryData['prizeValue']}</td>
        </tr>
    ''',
        )
        .join();

    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <title>Bulk Entry Receipt</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 20px; }
            .header { text-align: center; color: #2196F3; }
            .summary { background: #f0f0f0; padding: 15px; margin: 20px 0; }
            table { width: 100%; border-collapse: collapse; margin: 20px 0; }
            th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
            th { background-color: #f2f2f2; }
            .footer { text-align: center; color: #666; margin-top: 30px; }
        </style>
    </head>
    <body>
        <div class="header">
            <h1>🎉 SweepFeed Bulk Entry Receipt 🎉</h1>
        </div>
        
        <div class="summary">
            <h2>Bulk Entry Summary</h2>
            <p><strong>Bulk ID:</strong> $bulkId</p>
            <p><strong>Total Contests:</strong> ${entries.length}</p>
            <p><strong>Entry Date:</strong> ${_formatDate(entries.first.entryDate)}</p>
            <p><strong>Total Prize Value:</strong> \$${entries.fold<double>(0, (sum, e) => sum + (e.entryData['prizeValue'] as double? ?? 0)).toStringAsFixed(2)}</p>
        </div>
        
        <h3>Contest Details</h3>
        <table>
            <tr>
                <th>Contest</th>
                <th>Confirmation Code</th>
                <th>Prize Value</th>
            </tr>
            $contestsHtml
        </table>
        
        <div class="footer">
            <p>Thank you for using SweepFeed!</p>
            <p>Keep this receipt for your records.</p>
        </div>
    </body>
    </html>
    ''';
  }

  /// Generate receipt PDF
  Future<Uint8List> _generateReceiptPdf(ContestEntry entry) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Text(
                '🎉 SweepFeed Entry Receipt 🎉',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 30),
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Confirmation Code: ${entry.confirmationCode}',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text('Status: ${entry.statusDisplayText}'),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Contest Details',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text('Contest: ${entry.contestTitle}'),
            pw.Text('Prize Value: \$${entry.entryData['prizeValue']}'),
            pw.Text('Sponsor: ${entry.entryData['sponsor']}'),
            pw.Text('Entry Date: ${_formatDate(entry.entryDate)}'),
            pw.Text('Entry Method: ${entry.methodDisplayText}'),
            pw.Spacer(),
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text('Thank you for using SweepFeed!'),
                  pw.Text('Keep this receipt for your records.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  /// Generate bulk receipt PDF
  Future<Uint8List> _generateBulkReceiptPdf(
    String bulkId,
    List<ContestEntry> entries,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Text(
                '🎉 SweepFeed Bulk Entry Receipt 🎉',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 30),
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Bulk Entry Summary',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text('Bulk ID: $bulkId'),
                  pw.Text('Total Contests: ${entries.length}'),
                  pw.Text(
                    'Entry Date: ${_formatDate(entries.first.entryDate)}',
                  ),
                  pw.Text(
                    'Total Prize Value: \$${entries.fold<double>(0, (sum, e) => sum + (e.entryData['prizeValue'] as double? ?? 0)).toStringAsFixed(2)}',
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Contest Details',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        'Contest',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        'Confirmation',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        'Prize Value',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                ...entries.map(
                  (entry) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(entry.contestTitle),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(entry.confirmationCode ?? ''),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          '\$${entry.entryData['prizeValue']}',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.Spacer(),
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text('Thank you for using SweepFeed!'),
                  pw.Text('Keep this receipt for your records.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  /// Track entry analytics
  Future<void> _trackEntryAnalytics(ContestEntry entry) async {
    await _firestore.collection('entry_analytics').add({
      'userId': entry.userId,
      'contestId': entry.contestId,
      'method': entry.method.toString().split('.').last,
      'prizeValue': entry.entryData['prizeValue'],
      'timestamp': FieldValue.serverTimestamp(),
      'date': Timestamp.fromDate(
        DateTime(
          entry.entryDate.year,
          entry.entryDate.month,
          entry.entryDate.day,
        ),
      ),
    });
  }

  /// Format date for display
  String _formatDate(DateTime date) =>
      '${date.month}/${date.day}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';

  /// Delete entry (admin function)
  Future<void> deleteEntry(String entryId) async {
    await _entriesCollection.doc(entryId).delete();
  }

  /// Get total entry count for user
  Future<int> getUserEntryCount(String userId) async {
    final snapshot =
        await _entriesCollection.where('userId', isEqualTo: userId).get();

    return snapshot.docs.length;
  }

  /// Get daily entry limit status
  Future<Map<String, dynamic>> getDailyEntryStatus(
    String userId,
    String contestId,
  ) async {
    final canEnter = await _canUserEnterDaily(userId, contestId);

    if (canEnter) {
      return {
        'canEnter': true,
        'nextEntryTime': null,
        'message': 'You can enter this contest today!',
      };
    } else {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final nextEntry = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);

      return {
        'canEnter': false,
        'nextEntryTime': nextEntry,
        'message':
            'You have already entered this contest today. Come back tomorrow!',
      };
    }
  }
}
