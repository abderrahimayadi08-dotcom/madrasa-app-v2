import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:madrasa_app/core/models/request_model.dart';
import 'package:madrasa_app/core/services/logger.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createRequest(RequestModel request) async {
    try {
      await _firestore
          .collection('requests')
          .doc(request.id)
          .set(request.toMap());
      Logger.info('Request created: ${request.id}');
    } catch (e) {
      Logger.error('Failed to create request: $e');
      rethrow;
    }
  }

  Stream<QuerySnapshot> getRequestsByUser(String userId) {
    return _firestore
        .collection('requests')
        .where('userId', isEqualTo: userId)
        .snapshots();
  }

  Stream<QuerySnapshot> getRequestsByRole(String role) {
    return _firestore
        .collection('requests')
        .where('assignedRole', isEqualTo: role)
        .snapshots();
  }

  Stream<QuerySnapshot> getAllRequests() {
    return _firestore.collection('requests').snapshots();
  }

  Future<void> updateRequestStatus(
      String requestId, String status, String? comment) async {
    try {
      await _firestore.collection('requests').doc(requestId).update({
        'status': status,
        'comment': comment,
        'reviewedAt': DateTime.now().toIso8601String(),
      });
      Logger.info('Request $requestId updated to $status');
    } catch (e) {
      Logger.error('Failed to update request: $e');
      rethrow;
    }
  }
}
