/// DSN for the Sentry project that collects crash/error reports. Like the
/// Supabase anon key, a Sentry DSN is safe to embed client-side -- it can
/// only submit events, not read data (see supabase_config.dart).
class SentryConfig {
  static const String dsn = 'https://07e7249011ddce53ebe8361af931bcc0@o4511960229937152.ingest.de.sentry.io/4511960242913360';
}
