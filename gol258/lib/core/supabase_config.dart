import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = 'https://rhkwuoqxadjpmcqzdlqy.supabase.co';
const supabaseAnonKey =
    'sb_publishable_ba3whxNkZzI1pEkwUTysNQ_2OppwQ77';

SupabaseClient get supabase => Supabase.instance.client;
