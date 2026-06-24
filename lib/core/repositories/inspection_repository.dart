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

  /// Persists a completed DVI checklist to Supabase.
  Future<void> saveInspectionReport(String jobId, InspectionReport report) async {
    final technicianId = report.technicianId.isNotEmpty
        ? report.technicianId
        : _userId;
    final vehicleId = report.vehicleId;

    if (vehicleId.isEmpty) {
      throw Exception('Vehicle id is required to save an inspection report');
    }

    try {
      final row = {
        ...report.toSupabaseRow(),
        'job_id': jobId,
        'technician_id': technicianId,
        'vehicle_id': vehicleId,
      };

      final existing = await _supabase
          .from('inspections')
          .select('id')
          .eq('job_id', jobId)
          .order('created_at', ascending: false)
          .maybeSingle();

      if (existing != null) {
        await _supabase.from('inspections').update(row).eq('id', existing['id']);
      } else {
        await _supabase.from('inspections').insert(row);
      }

      if (kDebugMode) {
        debugPrint('--- SAVED INSPECTION REPORT (Supabase) ---');
        debugPrint('jobId: $jobId, items: ${report.items.length}');
        debugPrint('------------------------------------------');
      }
    } catch (e) {
      throw Exception('Failed to save inspection report: $e');
    }
  }

  Future<void> submitInspection(InspectionReport report) async {
    await saveInspectionReport(report.jobId, report);
  }
}
