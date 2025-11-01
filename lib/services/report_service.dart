import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report_model.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Submit a report
  Future<void> submitReport({
    required String reporterId,
    required String reportedUserId,
    required ReportReason reason,
    String? description,
  }) async {
    try {
      Report report = Report(
        id: '',
        reporterId: reporterId,
        reportedUserId: reportedUserId,
        reason: reason,
        description: description,
        timestamp: DateTime.now(),
      );

      await _firestore.collection('reports').add(report.toMap());
    } catch (e) {
      print('Error submitting report: $e');
      rethrow;
    }
  }

  // Get reports for a user (admin functionality)
  Stream<List<Report>> getReportsForUser(String userId) {
    return _firestore
        .collection('reports')
        .where('reportedUserId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Report.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get all reports (admin functionality)
  Stream<List<Report>> getAllReports() {
    return _firestore
        .collection('reports')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Report.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Mark report as resolved
  Future<void> markReportAsResolved(String reportId) async {
    try {
      await _firestore.collection('reports').doc(reportId).update({
        'isResolved': true,
      });
    } catch (e) {
      print('Error marking report as resolved: $e');
      rethrow;
    }
  }

  // Check if user has been reported multiple times
  Future<int> getReportCount(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('reports')
          .where('reportedUserId', isEqualTo: userId)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('Error getting report count: $e');
      return 0;
    }
  }
}
