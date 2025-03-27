import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shift_model.dart';
import '../constants/app_constants.dart';
import 'package:uuid/uuid.dart';

class ShiftService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = Uuid();

  // Create a new shift
  Future<ShiftModel> createShift({
    required String eventId,
    required String eventName,
    required DateTime date,
    required String shiftType,
    required String assignedToId,
    required String assignedToName,
  }) async {
    try {
      String shiftId = _uuid.v4();
      ShiftModel shift = ShiftModel(
        id: shiftId,
        eventId: eventId,
        eventName: eventName,
        date: date,
        shiftType: shiftType,
        assignedToId: assignedToId,
        assignedToName: assignedToName,
        status: 'assigned',
      );

      await _firestore
          .collection(AppConstants.shiftsCollection)
          .doc(shiftId)
          .set(shift.toMap());

      return shift;
    } catch (e) {
      throw Exception('Failed to create shift: ${e.toString()}');
    }
  }

  // Get shifts for a specific user
  Stream<List<ShiftModel>> getUserShiftsStream(String userId) {
    return _firestore
        .collection(AppConstants.shiftsCollection)
        .where('assignedToId', isEqualTo: userId)
        .orderBy('date')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ShiftModel.fromFirestore(doc))
            .toList());
  }

  // Get all shifts for an event
  Stream<List<ShiftModel>> getEventShiftsStream(String eventId) {
    return _firestore
        .collection(AppConstants.shiftsCollection)
        .where('eventId', isEqualTo: eventId)
        .orderBy('date')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ShiftModel.fromFirestore(doc))
            .toList());
  }

  // Get all shifts
  Stream<List<ShiftModel>> getAllShiftsStream() {
    return _firestore
        .collection(AppConstants.shiftsCollection)
        .orderBy('date')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ShiftModel.fromFirestore(doc))
            .toList());
  }

  // Request shift change
  Future<void> requestShiftChange(
      String shiftId, String reason) async {
    try {
      await _firestore
          .collection(AppConstants.shiftsCollection)
          .doc(shiftId)
          .update({
        'status': 'requested_change',
        'changeRequestReason': reason,
        'changeOffers': [],
      });
    } catch (e) {
      throw Exception('Failed to request shift change: ${e.toString()}');
    }
  }

  // Offer to take shift
  Future<void> offerToTakeShift(
      String shiftId, String userId, String userName, String? message) async {
    try {
      // Get current shift
      DocumentSnapshot doc = await _firestore
          .collection(AppConstants.shiftsCollection)
          .doc(shiftId)
          .get();
      
      if (!doc.exists) {
        throw Exception('Shift not found');
      }
      
      ShiftModel shift = ShiftModel.fromFirestore(doc);
      
      if (shift.status != 'requested_change') {
        throw Exception('Shift is not available for change');
      }
      
      // Create offer
      ShiftChangeOffer offer = ShiftChangeOffer(
        userId: userId,
        userName: userName,
        offerDate: DateTime.now(),
        message: message,
      );
      
      // Add to shift
      List<ShiftChangeOffer> offers = shift.changeOffers ?? [];
      offers.add(offer);
      
      await _firestore
          .collection(AppConstants.shiftsCollection)
          .doc(shiftId)
          .update({'changeOffers': offers.map((o) => o.toMap()).toList()});
    } catch (e) {
      throw Exception('Failed to offer to take shift: ${e.toString()}');
    }
  }

  // Approve shift change
  Future<void> approveShiftChange(
      String shiftId, String newUserId, String newUserName) async {
    try {
      // Get current shift
      DocumentSnapshot doc = await _firestore
          .collection(AppConstants.shiftsCollection)
          .doc(shiftId)
          .get();
      
      if (!doc.exists) {
        throw Exception('Shift not found');
      }
      
      ShiftModel shift = ShiftModel.fromFirestore(doc);
      
      // Update shift
      await _firestore
          .collection(AppConstants.shiftsCollection)
          .doc(shiftId)
          .update({
        'status': 'change_approved',
        'originalAssignedToId': shift.assignedToId,
        'originalAssignedToName': shift.assignedToName,
        'assignedToId': newUserId,
        'assignedToName': newUserName,
      });
    } catch (e) {
      throw Exception('Failed to approve shift change: ${e.toString()}');
    }
  }

  // Reject shift change
  Future<void> rejectShiftChange(String shiftId) async {
    try {
      await _firestore
          .collection(AppConstants.shiftsCollection)
          .doc(shiftId)
          .update({
        'status': 'assigned',
        'changeRequestReason': null,
        'changeOffers': null,
      });
    } catch (e) {
      throw Exception('Failed to reject shift change: ${e.toString()}');
    }
  }

  // Delete shift
  Future<void> deleteShift(String shiftId) async {
    try {
      await _firestore
          .collection(AppConstants.shiftsCollection)
          .doc(shiftId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete shift: ${e.toString()}');
    }
  }
}

