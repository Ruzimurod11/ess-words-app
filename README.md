# Essential English Words — Flutter

`fullstack-app` loyihasining **frontend** qismi Flutter'ga ko'chirildi (Android + iOS).
Backend (Node/Express API) **o'zgarishsiz** qoladi — bu ilova o'sha REST API'ni ishlatadi.

## Nima ko'chirildi

To'liq funksional parity:

- **Kitoblar** (Books grid) → **Bo'limlar** (Unit tabs) → **So'zlar** (pagination bilan)
- **Vocabulary** bo'limi (avto-tag bilan so'z qo'shish)
- **Global qidiruv** (sahifalash bilan)
- **Test / Quiz**: `topic` va `general` rejimlar, `easy` (variant tanlash) / `hard` (yozib javob berish) darajalar, `all` / `half` / `full` qamrovlar, yo'nalish almashtirish (UZ↔EN), rag'bat (cheer) va natija ekrani
- **Admin**: parol bilan kirish, so'z qo'shish/tahrirlash/o'chirish, drag bilan qayta tartiblash, transkripsiya backfill
- **3 til** (uz/en/ru) — veb ilovaning aynan JSON tarjimalari (`assets/i18n/`)
- **Light / Dark** tema (rang tokenlari veb Tailwind temasidan aynan ko'chirilgan)

Til, tema va admin token `shared_preferences` orqali saqlanadi (veb'dagi `localStorage` o'rnida).

## Ishga tushirish

Bu mashinada Flutter o'rnatilmagan edi, shuning uchun `lib/`, `pubspec.yaml` va
assetlar tayyor holda berilgan. Native platforma papkalarini (`android/`, `ios/`)
Flutter o'zi generatsiya qiladi:

```bash
# 1. Flutter o'rnating: https://docs.flutter.dev/get-started/install

# 2. Loyiha papkasida native scaffolding'ni yarating (lib/ va pubspec saqlanadi):
cd "ess-words-flutter"
flutter create .

# 3. Bog'liqliklarni oling:
flutter pub get

# 4. App ikonka va splash screen'ni generatsiya qiling (native papkalarga yozadi):
dart run flutter_launcher_icons
dart run flutter_native_splash:create

# 5. Statik tekshiruv (majburiy — build oldidan):
flutter analyze

# 6. Ishga tushiring:
flutter run
```

## Backend URL (muhim)

Standart qiymat `lib/core/config.dart` da: `http://10.0.2.2:3000`.

- **Android emulyator** host mashinaning `localhost`iga `10.0.2.2` orqali murojaat qiladi.
- **iOS simulyator** to'g'ridan-to'g'ri `localhost` ishlatadi.
- Backend dev portingiz `3007` (fullstack-app/backend/.env), production esa Render'da.

URL'ni build/run paytida override qiling:

```bash
# Android emulyator, lokal backend 3007-portda:
flutter run --dart-define=API_URL=http://10.0.2.2:3007

# iOS simulyator:
flutter run --dart-define=API_URL=http://localhost:3007

# Production backend:
flutter run --dart-define=API_URL=https://backend-mibi.onrender.com
```

## HTTP cleartext (Android)

Lokal backend HTTP (HTTPS emas) bo'lgani uchun Android cleartext trafikka ruxsat
kerak. Bu allaqachon qo'shilgan: `android/app/src/main/AndroidManifest.xml`

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<application ... android:usesCleartextTraffic="true">
```

> ⚠️ **Tartib muhim.** `android/` papkasini `flutter create .` yaratadi va u
> `AndroidManifest.xml`ni **ustidan qayta yozib yuborishi mumkin**. Ikki holat:
>
> - **Agar create manifestni saqlab qolsa** — hech nima qilish shart emas, yuqoridagi
>   sozlama joyida qoladi.
> - **Agar create ustidan yozsa** — quyidagi ikki qatorni qayta qo'shing:
>   `<manifest>` ichiga `<uses-permission android:name="android.permission.INTERNET"/>`
>   va `<application>` tegiga `android:usesCleartextTraffic="true"`.
>
> Ishonch uchun `flutter create .` dan **keyin** faylni bir marta tekshiring.

**Production (xavfsizroq) variant** — barcha HTTP'ga emas, faqat dev host'larga ruxsat.
`usesCleartextTraffic` o'rniga scoped config ishlating:

`android/app/src/main/res/xml/network_security_config.xml`:
```xml
<network-security-config>
  <domain-config cleartextTrafficPermitted="true">
    <domain includeSubdomains="true">10.0.2.2</domain>
    <domain includeSubdomains="true">localhost</domain>
  </domain-config>
</network-security-config>
```
so'ng `<application>` tegida: `android:networkSecurityConfig="@xml/network_security_config"`
(va `usesCleartextTraffic`ni olib tashlang).

## HTTP cleartext (iOS)

Bu ham allaqachon qo'shilgan: `ios/Runner/Info.plist`

```xml
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSAllowsLocalNetworking</key><true/>
</dict>
```

`NSAllowsLocalNetworking` lokal host'larga (`localhost`, `10.0.2.2`) HTTP'ga ruxsat
beradi — dev uchun kifoya. Barcha HTTP'ga ruxsat kerak bo'lsa uni
`<key>NSAllowsArbitraryLoads</key><true/>` bilan almashtiring. Production HTTPS
uchun bu blok umuman kerak emas.

> ⚠️ **Android'dagi kabi tartib muhim.** `ios/` papkasini `flutter create .` yaratadi
> va `Info.plist`ni ustidan yozishi mumkin. `flutter create .` dan **keyin** faylni
> tekshiring; yo'qolgan bo'lsa yuqoridagi `NSAppTransportSecurity` blokini `</dict></plist>`
> dan oldin qayta qo'shing.

## App ikonka & Splash

Manba rasmlar (veb logotipga mos — indigo→violet gradient + oq "graduation cap"):

- `assets/icon/icon.png` — asosiy ikonka (iOS + eski Android)
- `assets/icon/icon_foreground.png` / `icon_background.png` — Android adaptive ikonka (fg cap + gradient bg)
- `assets/splash/splash_logo.png` — splash markazidagi logotip (light/dark'da ham ko'rinadi)

Sozlama `pubspec.yaml`da (`flutter_launcher_icons` va `flutter_native_splash` bloklari):
splash foni light `#F6F7FD`, dark `#0B0B15` (ilova temalariga mos).

Generatsiya qilish (**`flutter create .` dan keyin**, native papkalar mavjud bo'lganda):

```bash
dart run flutter_launcher_icons          # android/ios ikonkalarini yozadi
dart run flutter_native_splash:create    # android/ios splash'ini yozadi
```

> Boshqa rasm ishlatmoqchi bo'lsangiz — `assets/icon/icon.png` (1024×1024) va
> `assets/splash/splash_logo.png` ni almashtiring, so'ng yuqoridagi ikki buyruqni
> qayta ishga tushiring. Rasmlarni qayta yaratish uchun `tools/gen_icons.py` skripti
> ham bor (PIL kerak).

## Tuzilma

```
lib/
  core/        config, session (token/til holder), api_client (dio interceptorlar), quiz_logic
  models/      book, word, quiz
  api/         api.dart — barcha endpoint chaqiruvlari
  i18n/        i18n.dart — JSON yuklovchi + t() interpolatsiya
  state/       app_state (locale/theme/auth providerlar) + data (fetch providerlar)
  ui/
    theme.dart, app_shell.dart
    widgets/   common, loader, confirm_dialog
    components/ books_grid, unit_tabs, words_table, word_form, header_actions
    screens/   home, book, vocabulary, search, test/(test_screen, quiz_game)
assets/i18n/   uz.json, en.json, ru.json  (veb ilova bilan bir xil)
```

State management: **flutter_riverpod** (veb'dagi TanStack Query kesh/invalidatsiya
semantikasiga mos). HTTP: **dio**. Routing: **go_router**.
