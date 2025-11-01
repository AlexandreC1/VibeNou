import 'package:cloud_firestore/cloud_firestore.dart';

enum ReportReason {
  harassment,
  inappropriateContent,
  spam,
  fakeProfile,
  other,
}

class Report {
  final String id;
  final String reporterId;
  final String reportedUserId;
  final ReportReason reason;
  final String? description;
  final DateTime timestamp;
  final bool isResolved;

  Report({
    required this.id,
    required this.reporterId,
    required this.reportedUserId,
    required this.reason,
    this.description,
    required this.timestamp,
    this.isResolved = false,
  });

  factory Report.fromMap(Map<String, dynamic> map, String id) {
    return Report(
      id: id,
      reporterId: map['reporterId'] ?? '',
      reportedUserId: map['reportedUserId'] ?? '',
      reason: ReportReason.values.firstWhere(
        (e) => e.toString() == 'ReportReason.${map['reason']}',
        orElse: () => ReportReason.other,
      ),
      description: map['description'],
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isResolved: map['isResolved'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reporterId': reporterId,
      'reportedUserId': reportedUserId,
      'reason': reason.toString().split('.').last,
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
      'isResolved': isResolved,
    };
  }
}
