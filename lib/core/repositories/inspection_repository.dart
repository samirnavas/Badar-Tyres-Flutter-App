import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/session_store.dart';
import '../models/inspection.dart';

class InspectionRepository {
  final _supabase = Supabase.instance.client;

  String get _userId {
    final id = SessionStore.currentUser?.id;
    if (id == null) throw Exception('User not logged in');
    return id;
  }

  /// Loads the latest inspection draft/submission for a job.
  Future<InspectionReport?> fetchInspectionForJob(String jobId) async {
    try {
      final data = await _supabase.rpc(
        'get_job_inspection',
        params: {
          'p_job_id': jobId,
          'p_technician_id': _userId,
        },
      );

      if (data == null) return null;
      final map = Map<String, dynamic>.from(data as Map);
      return InspectionReport.fromSupabaseRow(map);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('fetchInspectionForJob failed: $e');
      }
      return null;
    }
  }

  /// Persists a DVI checklist via SECURITY DEFINER RPC (bypasses RLS safely).
  Future<void> saveInspectionReport(String jobId, InspectionReport report) async {
    final technicianId =
        report.technicianId.isNotEmpty ? report.technicianId : _userId;
    final vehicleId = report.vehicleId;

    if (vehicleId.isEmpty) {
      throw Exception('Vehicle id is required to save an inspection report');
    }

    try {
      await _supabase.rpc(
        'upsert_job_inspection',
        params: {
          'p_job_id': jobId,
          'p_technician_id': technicianId,
          'p_vehicle_id': vehicleId,
          'p_status': report.status,
          'p_items': report.items.map((e) => e.toJson()).toList(),
        },
      );

      if (kDebugMode) {
        debugPrint('--- SAVED INSPECTION REPORT (RPC) ---');
        debugPrint('jobId: $jobId, items: ${report.items.length}');
        debugPrint('-------------------------------------');
      }
    } catch (e) {
      throw Exception('Failed to save inspection report: $e');
    }
  }

  Future<void> submitInspection(InspectionReport report) async {
    await saveInspectionReport(report.jobId, report);
  }
}
