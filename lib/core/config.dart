/// API base URL. Defaults to the production backend so a plain
/// `flutter build apk` produces a working release. Override for local dev:
///   flutter run --dart-define=API_URL=http://10.0.2.2:3000
///
/// Note: Android emulator cannot reach the host machine's `localhost` — use
/// 10.0.2.2 instead. iOS simulator can use localhost directly. A real device
/// (installed APK) cannot reach 10.0.2.2 at all, which is why the default must
/// point at the deployed backend.
const String kApiUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'https://backend-mibi.onrender.com',
);

String get apiRoot {
  final u = kApiUrl.trim();
  return u.endsWith('/') ? u.substring(0, u.length - 1) : u;
}
