import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';
import 'package:flutter/foundation.dart'; // For debugPrint

Future<void> main() async {
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    publishableKey:
        dotenv.env['SUPABASE_ANON_KEY'] ?? dotenv.env['SUPABASE_ANON_KEY']!,
  );

  final supabase = Supabase.instance.client;

  try {
    final jobs = await supabase.from('jobs').select('*, vehicles(*)').limit(1);
    debugPrint("----- JOBS -----");
    debugPrint(jobs.toString());
  } catch (e) {
    debugPrint("Error: $e");
  }
  exit(0);
}
