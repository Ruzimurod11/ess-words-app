/// API base URL. Override at build/run time with:
///   flutter run --dart-define=API_URL=https://backend-mibi.onrender.com
///
/// Note: Android emulator cannot reach the host machine's `localhost` — use
/// 10.0.2.2 instead. iOS simulator can use localhost directly.
const String kApiUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://10.0.2.2:3000',
);

String get apiRoot {
  final u = kApiUrl.trim();
  return u.endsWith('/') ? u.substring(0, u.length - 1) : u;
}
