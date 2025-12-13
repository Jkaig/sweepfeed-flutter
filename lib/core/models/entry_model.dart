import 'package:cloud_firestore/cloud_firestore.dart';

enum EntryStatus {
  pending,
  confirmed,
  failed,
  invalid,
}

enum EntryMethod {
  website,
  email,
  social,
  app,
  phone,
  mail,
}

class ContestEntry {
  ContestEntry({
    required this.id,
    required this.userId,
    required this.contestId,
    required this.contestTitle,
    required this.entryDate,
    required this.status,
    required this.method,
    required this.createdAt,
    required this.updatedAt,
    this.entryData = const {},
    this.confirmationCode,
    this.receiptUrl,
    this.isDailyEntry = false,
    this.nextEntryAllowed,
    this.entryCount = 1,
    this.errorMessage,
  });

  factory ContestEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;

    return ContestEntry(
      id: doc.id,
      userId: data['userId'] ?? '',
      contestId: data['contestId'] ?? '',
      contestTitle: data['contestTitle'] ?? '',
      entryDate: (data['entryDate'] as Timestamp).toDate(),
      status: EntryStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => EntryStatus.pending,
      ),
      method: EntryMethod.values.firstWhere(
        (e) => e.toString().split('.').last == data['method'],
        orElse: () => EntryMethod.website,
      ),
      entryData: Map<String, dynamic>.from(data['entryData'] ?? {}),
      confirmationCode: data['confirmationCode'],
      receiptUrl: data['receiptUrl'],
      isDailyEntry: data['isDailyEntry'] ?? false,
      nextEntryAllowed: data['nextEntryAllowed'] != null
          ? (data['nextEntryAllowed'] as Timestamp).toDate()
          : null,
      entryCount: data['entryCount'] ?? 1,
      errorMessage: data['errorMessage'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }
  final String id;
  final String userId;
  final String contestId;
  final String contestTitle;
  final DateTime entryDate;
  final EntryStatus status;
  final EntryMethod method;
  final Map<String, dynamic> entryData;
  final String? confirmationCode;
  final String? receiptUrl;
  final bool isDailyEntry;
  final DateTime? nextEntryAllowed;
  final int entryCount;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'contestId': contestId,
        'contestTitle': contestTitle,
        'entryDate': Timestamp.fromDate(entryDate),
        'status': status.toString().split('.').last,
        'method': method.toString().split('.').last,
        'entryData': entryData,
        'confirmationCode': confirmationCode,
        'receiptUrl': receiptUrl,
        'isDailyEntry': isDailyEntry,
        'nextEntryAllowed': nextEntryAllowed != null
            ? Timestamp.fromDate(nextEntryAllowed!)
            : null,
        'entryCount': entryCount,
        'errorMessage': errorMessage,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  ContestEntry copyWith({
    String? id,
    String? userId,
    String? contestId,
    String? contestTitle,
    DateTime? entryDate,
    EntryStatus? status,
    EntryMethod? method,
    Map<String, dynamic>? entryData,
    String? confirmationCode,
    String? receiptUrl,
    bool? isDailyEntry,
    DateTime? nextEntryAllowed,
    int? entryCount,
    String? errorMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      ContestEntry(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        contestId: contestId ?? this.contestId,
        contestTitle: contestTitle ?? this.contestTitle,
        entryDate: entryDate ?? this.entryDate,
        status: status ?? this.status,
        method: method ?? this.method,
        entryData: entryData ?? this.entryData,
        confirmationCode: confirmationCode ?? this.confirmationCode,
        receiptUrl: receiptUrl ?? this.receiptUrl,
        isDailyEntry: isDailyEntry ?? this.isDailyEntry,
        nextEntryAllowed: nextEntryAllowed ?? this.nextEntryAllowed,
        entryCount: entryCount ?? this.entryCount,
        errorMessage: errorMessage ?? this.errorMessage,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  bool get isPending => status == EntryStatus.pending;
  bool get isConfirmed => status == EntryStatus.confirmed;
  bool get isFailed => status == EntryStatus.failed;
  bool get isInvalid => status == EntryStatus.invalid;

  bool get canEnterAgain {
    if (!isDailyEntry) return false;
    if (nextEntryAllowed == null) return true;
    return DateTime.now().isAfter(nextEntryAllowed!);
  }

  Duration? get timeUntilNextEntry {
    if (!isDailyEntry || nextEntryAllowed == null) return null;
    final now = DateTime.now();
    if (now.isAfter(nextEntryAllowed!)) return null;
    return nextEntryAllowed!.difference(now);
  }

  String get statusDisplayText {
    switch (status) {
      case EntryStatus.pending:
        return 'Processing...';
      case EntryStatus.confirmed:
        return 'Entry Confirmed';
      case EntryStatus.failed:
        return 'Entry Failed';
      case EntryStatus.invalid:
        return 'Invalid Entry';
    }
  }

  String get methodDisplayText {
    switch (method) {
      case EntryMethod.website:
        return 'Website';
      case EntryMethod.email:
        return 'Email';
      case EntryMethod.social:
        return 'Social Media';
      case EntryMethod.app:
        return 'Mobile App';
      case EntryMethod.phone:
        return 'Phone';
      case EntryMethod.mail:
        return 'Mail';
    }
  }
}

class EntryReceipt {
  EntryReceipt({
    required this.id,
    required this.entryId,
    required this.userId,
    required this.contestId,
    required this.contestTitle,
    required this.entryDate,
    required this.confirmationCode,
    required this.receiptHtml,
    required this.receiptPdfUrl,
    required this.createdAt,
    this.receiptData = const {},
  });

  factory EntryReceipt.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;

    return EntryReceipt(
      id: doc.id,
      entryId: data['entryId'] ?? '',
      userId: data['userId'] ?? '',
      contestId: data['contestId'] ?? '',
      contestTitle: data['contestTitle'] ?? '',
      entryDate: (data['entryDate'] as Timestamp).toDate(),
      confirmationCode: data['confirmationCode'] ?? '',
      receiptData: Map<String, dynamic>.from(data['receiptData'] ?? {}),
      receiptHtml: data['receiptHtml'] ?? '',
      receiptPdfUrl: data['receiptPdfUrl'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
  final String id;
  final String entryId;
  final String userId;
  final String contestId;
  final String contestTitle;
  final DateTime entryDate;
  final String confirmationCode;
  final Map<String, dynamic> receiptData;
  final String receiptHtml;
  final String receiptPdfUrl;
  final DateTime createdAt;

  Map<String, dynamic> toFirestore() => {
        'entryId': entryId,
        'userId': userId,
        'contestId': contestId,
        'contestTitle': contestTitle,
        'entryDate': Timestamp.fromDate(entryDate),
        'confirmationCode': confirmationCode,
        'receiptData': receiptData,
        'receiptHtml': receiptHtml,
        'receiptPdfUrl': receiptPdfUrl,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
