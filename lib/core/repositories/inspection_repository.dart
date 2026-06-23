import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/inspection.dart';

class InspectionRepository {
  Future<bool> submitInspection(InspectionReport report) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));
    
    // Print JSON payload to console for verification
    final jsonPayload = jsonEncode(report.toJson());
    debugPrint('--- SUBMITTING INSPECTION REPORT ---');
    debugPrint(jsonPayload);
    debugPrint('------------------------------------');
    
    // Return true on success
    return true;
  }
}
