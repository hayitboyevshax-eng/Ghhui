# PixCompact

Offline Flutter ilova: rasm siqish + ZIP, tiniqlashtirish, PDF, rasm muharriri, video muharriri, audio konvertor (MP3/AAC/WAV/FLAC + bitrate).
Versiya: 1.17.858+1

## Ishga tushirish (kompyuterda)
```
flutter create --org com.oldv2 --project-name pixcompact --platforms=android .
flutter pub get
flutter run
```
Audio bo'limi (ffmpeg_kit) uchun Android `minSdk` kamida 24 bo'lishi kerak
(`android/app/build.gradle(.kts)` da `minSdk = 24`). GitHub workflow buni o'zi sozlaydi.
`flutter create` bizning fayllarni (pubspec, lib/main.dart, AndroidManifest, MainActivity, ikonkalar) ustidan yozmaydi.

## APK ni GitHub orqali olish (telefondan)
1. Shu papkani GitHub repoga yuklang (push).
2. Repo > Actions > "Build APK" tugagach, Artifacts ichidan `PixCompact-apk` ni yuklab oling.
