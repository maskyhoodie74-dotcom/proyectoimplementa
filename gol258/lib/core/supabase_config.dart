import 'package:supabase_flutter/supabase_flutter.dart';

/// ⚠️ Credenciales cargadas desde secrets.json via --dart-define-from-file
/// Nunca escribir valores reales directamente aquí.
const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

SupabaseClient get supabase => Supabase.instance.client;
