/// Project URL and anon/publishable key for the Supabase backend that
/// serves base-deck content. The anon key is safe to embed client-side --
/// it is not a secret, and all writes are blocked by Row Level Security
/// (see supabase/schema.sql). Never put the service_role key here.
class SupabaseConfig {
  static const String url = 'https://wkqzhtwzumdgeqdiriwl.supabase.co';
  static const String anonKey = 'sb_publishable_JXiHimDlvvOxCWVFfP0N6g_XUWj-OsM';
}
