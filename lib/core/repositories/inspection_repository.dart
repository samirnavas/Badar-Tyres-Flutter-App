import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/inspection.dart';
import '../services/sync_manager.dart';

class InspectionRepository {
  final _syncManager = SyncManager();

  Future<bool> submitInspection(InspectionReport report) async {
    try {
      await _syncManager.enqueueDviInspection(report);
      
      // Print JSON payload to console for verification
      final jsonPayload = jsonEncode(report.toJson());
      debugPrint('--- QUEUED INSPECTION REPORT OFFLINE ---');
      debugPrint(jsonPayload);
      debugPrint('------------------------------------');
      
      return true;
    } catch (e) {
      debugPrint('Failed to queue inspection: $e');
      return false;
    }
  }
}
