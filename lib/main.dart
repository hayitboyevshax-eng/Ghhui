// PixCompact — offline rasm, PDF va video vositalari
// Versiya: 1.17.858+1
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_compress/video_compress.dart';

import 'audio_screen.dart'; // Audio konvertor bo'limi

const String kAppVersion = '1.17.858+1';

/// Android bilan aloqa kanali (MainActivity.kt da shu nom bilan)
const MethodChannel _downloadsChannel = MethodChannel('pixcompact/downloads');

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PixCompactApp());
}

// ============================================================
// TILLAR (tizim tiliga moslashadi: uz / en / ru, boshqasi — en)
// ============================================================
const List<Locale> kSupportedLocales = [
  Locale('uz'),
  Locale('en'),
  Locale('ru'),
];

const Map<String, Map<String, String>> _strings = {
  'uz': {
    'title_compress': 'Rasm siqish & ZIP',
    'title_enhance': 'Tiniqlashtirish',
    'title_pdf': 'PDF yaratuvchi',
    'title_editor': 'Rasm muharriri',
    'title_video': 'Video muharrir',
    'nav_compress': 'Siqish',
    'nav_enhance': 'Tiniq',
    'nav_pdf': 'PDF',
    'nav_editor': 'Rasm',
    'nav_video': 'Video',
    'version': 'Versiya {v}',
    'offline_note':
        'Barcha amallar internetsiz, to\'liq qurilmangizning o\'zida bajariladi.',
    'pick_gallery': 'Galereyadan tanlash',
    'images_count': 'Rasmlar ({n}/{m})',
    'settings': 'Sozlamalar',
    'quality': 'Sifat (Quality): {v}%',
    'resolution': 'O\'lcham (Resolution): {v}%',
    'png_note': 'PNG yo\'qotishsiz format — sifat slayderi ta\'sir qilmaydi.',
    'max_images': 'Maksimum {m} ta rasm olinadi',
    'compress_btn': 'Siqish va ZIP yaratish',
    'processing': '{p}% — ishlanmoqda...',
    'done': 'Tayyor!',
    'sizes_info': 'Asl: {a}  →  Yangi: {b}',
    'zip_size': 'ZIP: {z}',
    'zip_fail': 'ZIP yaratilmadi',
    'error': 'Xatolik: {e}',
    'add_downloads': 'Yuklamalar jildiga qo\'shish',
    'share': 'Ulashish',
    'saved_downloads': 'Yuklamalar jildiga saqlandi: {p}',
    'save_failed': 'Saqlab bo\'lmadi: {e}',
    'link_fail': 'Havolani ochib bo\'lmadi',
    'sharpness': 'Keskinlik: {v}%',
    'contrast': 'Kontrast: {v}%',
    'enhance_btn': 'Tiniqlashtirish',
    'add_btn': 'Qo\'shish ({n}/{m})',
    'no_images': 'Rasmlar tanlanmagan',
    'page_n': '{n}-sahifa',
    'pdf_building': '{p}% — PDF yig\'ilmoqda...',
    'pdf_btn': 'PDF yaratish',
    // --- Rasm muharriri ---
    'pick_image': 'Rasm tanlash',
    'pick_other': 'Boshqa rasm tanlash',
    'tool_transform': 'Shakl',
    'tool_filters': 'Filtrlar',
    'tool_adjust': 'Sozlash',
    'tool_export': 'Saqlash',
    'rotate_left': 'Chapga',
    'rotate_right': 'O\'ngga',
    'op_flip_h': 'Gorizontal',
    'op_flip_v': 'Vertikal',
    'crop_title': 'Qirqish (nisbat)',
    'resize_title': 'O\'lcham: {v}%',
    'apply': 'Qo\'llash',
    'op_gray': 'Qora-oq',
    'op_sepia': 'Sepiya',
    'op_invert': 'Teskari',
    'op_blur': 'Xiralashtirish',
    'op_sharpen': 'Keskinlik',
    'op_vignette': 'Vinyetka',
    'brightness': 'Yorqinlik: {v}%',
    'saturation': 'To\'yinganlik: {v}%',
    'undo': 'Bekor qilish',
    'restore': 'Asl holiga',
    'format': 'Format',
    'image_info': '{w}×{h} px',
    // --- Video muharrir ---
    'video_section': 'Video',
    'pick_video': 'Galereyadan video tanlash',
    'file_label': 'Fayl: {f}',
    'size_label': 'Hajmi: {s}',
    'video_info': '{w}×{h}, {d}',
    'loading': 'Yuklanmoqda...',
    'trim_title': 'Qirqish (trim)',
    'trim_range': '{a} — {b}  (davomiyligi: {d})',
    'mute_audio': 'Ovozni o\'chirish',
    'fps_title': 'Kadr tezligi (FPS)',
    'save_frame': 'Kadrni rasm qilib saqlash',
    'level_title': 'Siqish darajasi',
    'level_strong': 'Kuchli',
    'level_medium': 'O\'rta',
    'level_light': 'Yengil',
    'level_hint':
        'Kuchli — eng kichik hajm, past sifat. Yengil — yaxshi sifat.',
    'video_progress': '{p}% — ishlanmoqda...',
    'video_btn': 'Videoni saqlash',
    'video_fail': 'Video qayta ishlanmadi',
  },
  'en': {
    'title_compress': 'Compress & ZIP',
    'title_enhance': 'Sharpen',
    'title_pdf': 'PDF Maker',
    'title_editor': 'Image Editor',
    'title_video': 'Video Editor',
    'nav_compress': 'Compress',
    'nav_enhance': 'Sharpen',
    'nav_pdf': 'PDF',
    'nav_editor': 'Image',
    'nav_video': 'Video',
    'version': 'Version {v}',
    'offline_note': 'Everything works offline, entirely on your device.',
    'pick_gallery': 'Pick from gallery',
    'images_count': 'Images ({n}/{m})',
    'settings': 'Settings',
    'quality': 'Quality: {v}%',
    'resolution': 'Resolution: {v}%',
    'png_note': 'PNG is lossless — the quality slider has no effect.',
    'max_images': 'Only the first {m} images are used',
    'compress_btn': 'Compress & create ZIP',
    'processing': '{p}% — processing...',
    'done': 'Done!',
    'sizes_info': 'Original: {a}  →  New: {b}',
    'zip_size': 'ZIP: {z}',
    'zip_fail': 'Could not create ZIP',
    'error': 'Error: {e}',
    'add_downloads': 'Add to Downloads',
    'share': 'Share',
    'saved_downloads': 'Saved to Downloads: {p}',
    'save_failed': 'Could not save: {e}',
    'link_fail': 'Could not open the link',
    'sharpness': 'Sharpness: {v}%',
    'contrast': 'Contrast: {v}%',
    'enhance_btn': 'Sharpen',
    'add_btn': 'Add ({n}/{m})',
    'no_images': 'No images selected',
    'page_n': 'Page {n}',
    'pdf_building': '{p}% — building PDF...',
    'pdf_btn': 'Create PDF',
    // --- Image editor ---
    'pick_image': 'Pick an image',
    'pick_other': 'Pick another image',
    'tool_transform': 'Shape',
    'tool_filters': 'Filters',
    'tool_adjust': 'Adjust',
    'tool_export': 'Save',
    'rotate_left': 'Left',
    'rotate_right': 'Right',
    'op_flip_h': 'Horizontal',
    'op_flip_v': 'Vertical',
    'crop_title': 'Crop (ratio)',
    'resize_title': 'Size: {v}%',
    'apply': 'Apply',
    'op_gray': 'Black & white',
    'op_sepia': 'Sepia',
    'op_invert': 'Invert',
    'op_blur': 'Blur',
    'op_sharpen': 'Sharpen',
    'op_vignette': 'Vignette',
    'brightness': 'Brightness: {v}%',
    'saturation': 'Saturation: {v}%',
    'undo': 'Undo',
    'restore': 'Reset',
    'format': 'Format',
    'image_info': '{w}×{h} px',
    // --- Video editor ---
    'video_section': 'Video',
    'pick_video': 'Pick video from gallery',
    'file_label': 'File: {f}',
    'size_label': 'Size: {s}',
    'video_info': '{w}×{h}, {d}',
    'loading': 'Loading...',
    'trim_title': 'Trim',
    'trim_range': '{a} — {b}  (length: {d})',
    'mute_audio': 'Remove audio',
    'fps_title': 'Frame rate (FPS)',
    'save_frame': 'Save frame as image',
    'level_title': 'Compression level',
    'level_strong': 'Strong',
    'level_medium': 'Medium',
    'level_light': 'Light',
    'level_hint':
        'Strong — smallest size, lower quality. Light — better quality.',
    'video_progress': '{p}% — processing...',
    'video_btn': 'Save video',
    'video_fail': 'Video could not be processed',
  },
  'ru': {
    'title_compress': 'Сжатие и ZIP',
    'title_enhance': 'Повышение резкости',
    'title_pdf': 'Создание PDF',
    'title_editor': 'Редактор фото',
    'title_video': 'Видеоредактор',
    'nav_compress': 'Сжатие',
    'nav_enhance': 'Резкость',
    'nav_pdf': 'PDF',
    'nav_editor': 'Фото',
    'nav_video': 'Видео',
    'version': 'Версия {v}',
    'offline_note': 'Всё работает офлайн, полностью на вашем устройстве.',
    'pick_gallery': 'Выбрать из галереи',
    'images_count': 'Изображения ({n}/{m})',
    'settings': 'Настройки',
    'quality': 'Качество: {v}%',
    'resolution': 'Разрешение: {v}%',
    'png_note': 'PNG — формат без потерь, ползунок качества не влияет.',
    'max_images': 'Будет использовано не более {m} изображений',
    'compress_btn': 'Сжать и создать ZIP',
    'processing': '{p}% — обработка...',
    'done': 'Готово!',
    'sizes_info': 'Было: {a}  →  Стало: {b}',
    'zip_size': 'ZIP: {z}',
    'zip_fail': 'Не удалось создать ZIP',
    'error': 'Ошибка: {e}',
    'add_downloads': 'Добавить в Загрузки',
    'share': 'Поделиться',
    'saved_downloads': 'Сохранено в Загрузки: {p}',
    'save_failed': 'Не удалось сохранить: {e}',
    'link_fail': 'Не удалось открыть ссылку',
    'sharpness': 'Резкость: {v}%',
    'contrast': 'Контраст: {v}%',
    'enhance_btn': 'Повысить резкость',
    'add_btn': 'Добавить ({n}/{m})',
    'no_images': 'Изображения не выбраны',
    'page_n': 'Страница {n}',
    'pdf_building': '{p}% — сборка PDF...',
    'pdf_btn': 'Создать PDF',
    // --- Редактор фото ---
    'pick_image': 'Выбрать изображение',
    'pick_other': 'Выбрать другое изображение',
    'tool_transform': 'Форма',
    'tool_filters': 'Фильтры',
    'tool_adjust': 'Настройка',
    'tool_export': 'Сохранить',
    'rotate_left': 'Влево',
    'rotate_right': 'Вправо',
    'op_flip_h': 'По горизонтали',
    'op_flip_v': 'По вертикали',
    'crop_title': 'Обрезка (пропорции)',
    'resize_title': 'Размер: {v}%',
    'apply': 'Применить',
    'op_gray': 'Чёрно-белое',
    'op_sepia': 'Сепия',
    'op_invert': 'Негатив',
    'op_blur': 'Размытие',
    'op_sharpen': 'Резкость',
    'op_vignette': 'Виньетка',
    'brightness': 'Яркость: {v}%',
    'saturation': 'Насыщенность: {v}%',
    'undo': 'Отменить',
    'restore': 'Сбросить',
    'format': 'Формат',
    'image_info': '{w}×{h} px',
    // --- Видеоредактор ---
    'video_section': 'Видео',
    'pick_video': 'Выбрать видео из галереи',
    'file_label': 'Файл: {f}',
    'size_label': 'Размер: {s}',
    'video_info': '{w}×{h}, {d}',
    'loading': 'Загрузка...',
    'trim_title': 'Обрезка',
    'trim_range': '{a} — {b}  (длительность: {d})',
    'mute_audio': 'Убрать звук',
    'fps_title': 'Частота кадров (FPS)',
    'save_frame': 'Сохранить кадр как фото',
    'level_title': 'Степень сжатия',
    'level_strong': 'Сильное',
    'level_medium': 'Среднее',
    'level_light': 'Лёгкое',
    'level_hint':
        'Сильное — минимальный размер, ниже качество. Лёгкое — лучше качество.',
    'video_progress': '{p}% — обработка...',
    'video_btn': 'Сохранить видео',
    'video_fail': 'Не удалось обработать видео',
  },
};

/// Tarjima: joriy tizim tiliga qarab matn qaytaradi.
/// Localizations.localeOf(context) tufayli til o'zgarsa, ekran avtomatik yangilanadi.
String tr(BuildContext context, String key, [Map<String, Object>? params]) {
  final code = Localizations.localeOf(context).languageCode;
  final table = _strings[code] ?? _strings['en']!;
  var s = table[key] ?? _strings['en']![key] ?? key;
  params?.forEach((k, v) => s = s.replaceAll('{$k}', '$v'));
  return s;
}

// ============================================================
// ILOVA (Material 3 mavzu)
// ============================================================
class PixCompactApp extends StatelessWidget {
  const PixCompactApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PixCompact',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF3F51B5),
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF3F51B5),
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      // Tizim tiliga moslash
      supportedLocales: kSupportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (locale, supported) {
        if (locale == null) return const Locale('en');
        for (final s in supported) {
          if (s.languageCode == locale.languageCode) return s;
        }
        return const Locale('en'); // qo'llab-quvvatlanmasa — inglizcha
      },
      home: const HomePage(),
    );
  }
}

// ============================================================
// UMUMIY YORDAMCHI FUNKSIYALAR
// ============================================================

/// Natija fayllari saqlanadigan papka (ilovaga tegishli)
Future<String> outDir() async {
  Directory? d;
  try {
    d = await getExternalStorageDirectory(); // Android
  } catch (_) {}
  d ??= await getApplicationDocumentsDirectory();
  final dir = Directory('${d.path}/PixCompact');
  if (!await dir.exists()) await dir.create(recursive: true);
  return dir.path;
}

/// Fayl nomi uchun vaqt tamg'asi
String stamp() => DateTime.now().millisecondsSinceEpoch.toString();

/// Hajmni o'qiladigan ko'rinishga o'tkazish
String fmtSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / 1024 / 1024).toStringAsFixed(2)} MB';
}

/// Soniyani mm:ss ko'rinishiga o'tkazish
String fmtTime(double seconds) {
  final t = seconds.round();
  final m = t ~/ 60;
  final s = t % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

void snack(BuildContext c, String m) {
  ScaffoldMessenger.of(c)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(m)));
}

/// Natijani ulashish
Future<void> shareFile(String path) async {
  await Share.shareXFiles([XFile(path)]);
}

String _mimeOf(String path) {
  final ext = path.split('.').last.toLowerCase();
  switch (ext) {
    case 'zip':
      return 'application/zip';
    case 'pdf':
      return 'application/pdf';
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'png':
      return 'image/png';
    case 'webp':
      return 'image/webp';
    case 'mp4':
      return 'video/mp4';
    case 'mp3':
      return 'audio/mpeg';
    case 'm4a':
      return 'audio/mp4';
    case 'aac':
      return 'audio/aac';
    case 'wav':
      return 'audio/wav';
    case 'flac':
      return 'audio/flac';
    default:
      return 'application/octet-stream';
  }
}

/// Faylni telefonning "Yuklamalar" (Downloads) jildiga ko'chirish.
/// Android tomonida MediaStore orqali amalga oshiriladi (MainActivity.kt).
Future<void> saveToDownloads(BuildContext context, String path) async {
  final name = path.split('/').last;
  try {
    final saved = await _downloadsChannel.invokeMethod<String>(
      'saveToDownloads',
      {'path': path, 'name': name, 'mime': _mimeOf(path)},
    );
    if (context.mounted) {
      snack(context, tr(context, 'saved_downloads', {'p': saved ?? name}));
    }
  } catch (e) {
    if (context.mounted) snack(context, tr(context, 'save_failed', {'e': e}));
  }
}

/// Telegram profilini ochish
Future<void> openSupport(BuildContext context) async {
  final uri = Uri.parse('https://t.me/oldv2');
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) snack(context, tr(context, 'link_fail'));
}

/// PNG sarlavhasidan o'lchamni o'qish (dekodlashsiz, tez)
List<int> pngSize(Uint8List b) {
  if (b.length < 24) return [0, 0];
  final d = ByteData.sublistView(b, 16, 24);
  return [d.getUint32(0), d.getUint32(4)];
}

// ============================================================
// ISOLATE (fon) ISHCHILARI — UI qotib qolmasligi uchun
// ============================================================

class _CompressArgs {
  final Uint8List bytes;
  final int scale; // 10..100 (%)
  final int quality; // 1..100
  final String fmt; // jpg | png | webp
  _CompressArgs(this.bytes, this.scale, this.quality, this.fmt);
}

/// Siqish: o'lchamni kichraytirib, tanlangan formatda kodlaydi.
/// WebP uchun avval PNG (yo'qotishsiz) qaytariladi, keyin native kodlanadi.
Uint8List? _compressWorker(_CompressArgs a) {
  var im = img.decodeImage(a.bytes);
  if (im == null) return null;
  im = img.bakeOrientation(im); // EXIF aylantirishni qo'llash
  if (a.scale < 100) {
    final w = (im.width * a.scale / 100).round().clamp(1, 100000);
    im = img.copyResize(im, width: w, interpolation: img.Interpolation.average);
  }
  switch (a.fmt) {
    case 'png':
      return Uint8List.fromList(img.encodePng(im, level: 6));
    case 'webp':
      return Uint8List.fromList(img.encodePng(im, level: 1));
    default:
      return Uint8List.fromList(img.encodeJpg(im, quality: a.quality));
  }
}

/// PNG baytlarini WebP ga aylantirish (o'lchamni o'zgartirmasdan).
/// minWidth/minHeight katta qilib berilgan — aks holda plagin rasmni kichraytirib yuboradi.
Future<Uint8List> toWebp(Uint8List pngBytes, int quality) {
  return FlutterImageCompress.compressWithList(
    pngBytes,
    quality: quality,
    format: CompressFormat.webp,
    minWidth: 20000,
    minHeight: 20000,
  );
}

class _SharpenArgs {
  final Uint8List bytes;
  final double sharp; // 0..1
  final double contrast; // 1.0..1.6
  _SharpenArgs(this.bytes, this.sharp, this.contrast);
}

/// Tiniqlashtirish: kontrast + keskinlik (konvolyutsiya)
Uint8List? _sharpenWorker(_SharpenArgs a) {
  var im = img.decodeImage(a.bytes);
  if (im == null) return null;
  im = img.bakeOrientation(im);
  if (im.width > 3000) im = img.copyResize(im, width: 3000);
  im = img.adjustColor(im, contrast: a.contrast);
  im = img.convolution(
    im,
    filter: [0, -1, 0, -1, 5, -1, 0, -1, 0],
    div: 1,
    offset: 0,
    amount: a.sharp,
  );
  return Uint8List.fromList(img.encodeJpg(im, quality: 95));
}

class _PdfPrepArgs {
  final Uint8List bytes;
  final int maxSide;
  _PdfPrepArgs(this.bytes, this.maxSide);
}

/// PDF uchun rasmni yengillashtirish (kichraytirish + JPG)
Uint8List? _pdfPrepWorker(_PdfPrepArgs a) {
  var im = img.decodeImage(a.bytes);
  if (im == null) return null;
  im = img.bakeOrientation(im);
  final longest = im.width > im.height ? im.width : im.height;
  if (longest > a.maxSide) {
    im = im.width >= im.height
        ? img.copyResize(im, width: a.maxSide)
        : img.copyResize(im, height: a.maxSide);
  }
  return Uint8List.fromList(img.encodeJpg(im, quality: 75));
}

// ---------- Rasm muharriri ishchilari ----------

/// Muharrirga yuklash: aylantirishni to'g'rilaydi, juda kattasini 2560px gacha
/// kichraytiradi (tezlik va xotira uchun) va tez PNG ko'rinishiga o'tkazadi.
Uint8List? _loadWorker(Uint8List bytes) {
  var im = img.decodeImage(bytes);
  if (im == null) return null;
  im = img.bakeOrientation(im);
  final longest = im.width > im.height ? im.width : im.height;
  if (longest > 2560) {
    im = im.width >= im.height
        ? img.copyResize(im, width: 2560)
        : img.copyResize(im, height: 2560);
  }
  return Uint8List.fromList(img.encodePng(im, level: 1));
}

class _EditArgs {
  final Uint8List bytes;
  final String op;
  final double a;
  final double b;
  final double c;
  _EditArgs(this.bytes, this.op, {this.a = 0, this.b = 0, this.c = 0});
}

/// Tahrirlash amallari (har biri alohida isolate'da)
Uint8List? _editWorker(_EditArgs p) {
  var im = img.decodePng(p.bytes) ?? img.decodeImage(p.bytes);
  if (im == null) return null;
  switch (p.op) {
    case 'rotL':
      im = img.copyRotate(im, angle: 270);
      break;
    case 'rotR':
      im = img.copyRotate(im, angle: 90);
      break;
    case 'flipH':
      im = img.flip(im, direction: img.FlipDirection.horizontal);
      break;
    case 'flipV':
      im = img.flip(im, direction: img.FlipDirection.vertical);
      break;
    case 'crop':
      {
        // Markazdan berilgan nisbatda (a:b) qirqish
        final target = p.a / p.b;
        final cur = im.width / im.height;
        var w = im.width;
        var h = im.height;
        if (cur > target) {
          w = (im.height * target).round();
        } else {
          h = (im.width / target).round();
        }
        final x = (im.width - w) ~/ 2;
        final y = (im.height - h) ~/ 2;
        im = img.copyCrop(im, x: x, y: y, width: w, height: h);
      }
      break;
    case 'resize':
      {
        final w = (im.width * p.a / 100).round().clamp(16, 100000);
        im = img.copyResize(im, width: w, interpolation: img.Interpolation.average);
      }
      break;
    case 'gray':
      im = img.grayscale(im);
      break;
    case 'sepia':
      im = img.sepia(im);
      break;
    case 'invert':
      im = img.invert(im);
      break;
    case 'blur':
      im = img.gaussianBlur(im, radius: 3);
      break;
    case 'sharpen':
      im = img.convolution(im,
          filter: [0, -1, 0, -1, 5, -1, 0, -1, 0], div: 1, offset: 0);
      break;
    case 'vignette':
      im = img.vignette(im);
      break;
    case 'adjust':
      // a = yorqinlik, b = kontrast, c = to'yinganlik (1.0 = o'zgarishsiz)
      im = img.adjustColor(im,
          brightness: p.a, contrast: p.b, saturation: p.c);
      break;
  }
  return Uint8List.fromList(img.encodePng(im, level: 1));
}

class _ExportArgs {
  final Uint8List bytes;
  final String fmt; // jpg | png
  final int quality;
  _ExportArgs(this.bytes, this.fmt, this.quality);
}

/// Yakuniy saqlash uchun kodlash
Uint8List? _exportWorker(_ExportArgs a) {
  if (a.fmt == 'png') return a.bytes;
  final im = img.decodePng(a.bytes);
  if (im == null) return null;
  return Uint8List.fromList(img.encodeJpg(im, quality: a.quality));
}

// ============================================================
// ASOSIY SAHIFA — 5 ta bo'lim (NavigationBar) + Drawer
// ============================================================
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  static const _titleKeys = [
    'title_compress',
    'title_enhance',
    'title_pdf',
    'title_editor',
    'title_video',
  ];

  /// Sarlavha: oxirgi (Audio) tab o'z tarjimasini audioTr orqali oladi
  String _title(BuildContext c) => _index < _titleKeys.length
      ? tr(c, _titleKeys[_index])
      : audioTr(c, 'title_audio');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_title(context))),
      drawer: const AppDrawer(),
      // IndexedStack — tablar almashganda holat saqlanib qoladi
      body: IndexedStack(
        index: _index,
        children: const [
          CompressScreen(),
          EnhanceScreen(),
          PdfScreen(),
          EditorScreen(),
          VideoScreen(),
          AudioScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.compress_outlined),
              selectedIcon: const Icon(Icons.compress),
              label: tr(context, 'nav_compress')),
          NavigationDestination(
              icon: const Icon(Icons.auto_fix_high_outlined),
              selectedIcon: const Icon(Icons.auto_fix_high),
              label: tr(context, 'nav_enhance')),
          NavigationDestination(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              selectedIcon: const Icon(Icons.picture_as_pdf),
              label: tr(context, 'nav_pdf')),
          NavigationDestination(
              icon: const Icon(Icons.tune_outlined),
              selectedIcon: const Icon(Icons.tune),
              label: tr(context, 'nav_editor')),
          NavigationDestination(
              icon: const Icon(Icons.movie_edit),
              selectedIcon: const Icon(Icons.movie_edit),
              label: tr(context, 'nav_video')),
          NavigationDestination(
              icon: const Icon(Icons.audiotrack_outlined),
              selectedIcon: const Icon(Icons.audiotrack),
              label: audioTr(context, 'nav_audio')),
        ],
      ),
    );
  }
}

/// Yon menyu: ilova ikonkasi + eng pastda kichik kulrang "Support" yozuvi
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/icon/icon.png',
                width: 84,
                height: 84,
                errorBuilder: (_, __, ___) => Icon(
                    Icons.photo_size_select_large,
                    size: 56,
                    color: cs.primary),
              ),
            ),
            const SizedBox(height: 12),
            Text('PixCompact',
                style: Theme.of(context).textTheme.headlineSmall),
            Text(tr(context, 'version', {'v': kAppVersion}),
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                tr(context, 'offline_note'),
                textAlign: TextAlign.center,
              ),
            ),
            const Spacer(),
            // Support yozuvi — kichik, kulrang, ko'zga tashlanmaydigan
            InkWell(
              onTap: () => openSupport(context),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Support: @oldv2',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// UMUMIY KICHIK VIDJETLAR
// ============================================================
class SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const SectionCard({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

class ProgressBox extends StatelessWidget {
  final double? value;
  final String label;
  const ProgressBox({super.key, this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(value: value),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// Natija uchun ikkita tugma: "Yuklamalar jildiga qo'shish" va "Ulashish"
class ResultButtons extends StatelessWidget {
  final String path;
  const ResultButtons({super.key, required this.path});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: () => saveToDownloads(context, path),
          icon: const Icon(Icons.download),
          label: Text(tr(context, 'add_downloads')),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => shareFile(path),
          icon: const Icon(Icons.share),
          label: Text(tr(context, 'share')),
        ),
      ],
    );
  }
}

// ============================================================
// 1) RASM SIQISH & ZIP (100 tagacha)
// ============================================================
class CompressScreen extends StatefulWidget {
  const CompressScreen({super.key});

  @override
  State<CompressScreen> createState() => _CompressScreenState();
}

class _CompressScreenState extends State<CompressScreen> {
  static const int maxFiles = 100;
  List<XFile> _files = [];
  double _quality = 80;
  double _scale = 100;
  String _fmt = 'jpg';
  bool _busy = false;
  double _progress = 0;
  String? _resultPath;
  int _origSize = 0, _newSize = 0, _zipSize = 0;

  Future<void> _pick() async {
    final picked = await ImagePicker().pickMultiImage();
    if (picked.isEmpty || !mounted) return;
    if (picked.length > maxFiles) {
      snack(context, tr(context, 'max_images', {'m': maxFiles}));
    }
    setState(() {
      _files = picked.take(maxFiles).toList();
      _resultPath = null;
    });
  }

  Future<void> _run() async {
    if (_files.isEmpty) return;
    setState(() {
      _busy = true;
      _progress = 0;
      _resultPath = null;
    });
    try {
      final archive = Archive();
      int original = 0, compressed = 0, done = 0;
      for (final f in _files) {
        final bytes = await f.readAsBytes();
        original += bytes.length;
        Uint8List? out = await compute(
          _compressWorker,
          _CompressArgs(bytes, _scale.round(), _quality.round(), _fmt),
        );
        if (out != null && _fmt == 'webp') {
          out = await toWebp(out, _quality.round()); // haqiqiy WebP
        }
        if (out != null) {
          compressed += out.length;
          final name = 'img_${(done + 1).toString().padLeft(3, '0')}.$_fmt';
          archive.addFile(ArchiveFile(name, out.length, out));
        }
        done++;
        if (mounted) setState(() => _progress = done / _files.length);
      }
      // Hammasini bitta ZIP arxivga yig'ish
      final zipBytes = ZipEncoder().encode(archive);
      if (zipBytes == null) throw Exception('zip_fail');
      final path = '${await outDir()}/pixcompact_${stamp()}.zip';
      await File(path).writeAsBytes(zipBytes);
      if (!mounted) return;
      setState(() {
        _resultPath = path;
        _origSize = original;
        _newSize = compressed;
        _zipSize = zipBytes.length;
      });
    } catch (e) {
      if (mounted) {
        final msg = e.toString().contains('zip_fail')
            ? tr(context, 'zip_fail')
            : '$e';
        snack(context, tr(context, 'error', {'e': msg}));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionCard(
          title: tr(context, 'images_count',
              {'n': _files.length, 'm': maxFiles}),
          children: [
            FilledButton.tonalIcon(
              onPressed: _busy ? null : _pick,
              icon: const Icon(Icons.photo_library),
              label: Text(tr(context, 'pick_gallery')),
            ),
            if (_files.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _files.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (_, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(File(_files[i].path),
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        cacheWidth: 150),
                  ),
                ),
              ),
            ],
          ],
        ),
        SectionCard(
          title: tr(context, 'settings'),
          children: [
            Text(tr(context, 'quality', {'v': _quality.round()})),
            Slider(
              value: _quality,
              min: 5,
              max: 100,
              divisions: 95,
              onChanged: _busy ? null : (v) => setState(() => _quality = v),
            ),
            Text(tr(context, 'resolution', {'v': _scale.round()})),
            Slider(
              value: _scale,
              min: 10,
              max: 100,
              divisions: 90,
              onChanged: _busy ? null : (v) => setState(() => _scale = v),
            ),
            const SizedBox(height: 4),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'jpg', label: Text('JPG')),
                ButtonSegment(value: 'png', label: Text('PNG')),
                ButtonSegment(value: 'webp', label: Text('WebP')),
              ],
              selected: {_fmt},
              onSelectionChanged:
                  _busy ? null : (s) => setState(() => _fmt = s.first),
            ),
            if (_fmt == 'png')
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(tr(context, 'png_note'),
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ),
          ],
        ),
        if (_busy)
          ProgressBox(
              value: _progress,
              label: tr(context, 'processing',
                  {'p': (_progress * 100).round()})),
        FilledButton.icon(
          onPressed: (_busy || _files.isEmpty) ? null : _run,
          icon: const Icon(Icons.archive),
          label: Text(tr(context, 'compress_btn')),
        ),
        if (_resultPath != null) ...[
          const SizedBox(height: 12),
          SectionCard(
            title: tr(context, 'done'),
            children: [
              Text(tr(context, 'sizes_info',
                  {'a': fmtSize(_origSize), 'b': fmtSize(_newSize)})),
              Text(tr(context, 'zip_size', {'z': fmtSize(_zipSize)})),
              const SizedBox(height: 12),
              // ZIP ni Yuklamalar jildiga qo'shish + ulashish
              ResultButtons(path: _resultPath!),
            ],
          ),
        ],
      ],
    );
  }
}

// ============================================================
// 2) RASM TINIQLASHTIRUVCHI (10 tagacha)
// ============================================================
class EnhanceScreen extends StatefulWidget {
  const EnhanceScreen({super.key});

  @override
  State<EnhanceScreen> createState() => _EnhanceScreenState();
}

class _EnhanceScreenState extends State<EnhanceScreen> {
  static const int maxFiles = 10;
  List<XFile> _files = [];
  double _sharp = 0.7; // keskinlik
  double _contrast = 1.15; // kontrast
  bool _busy = false;
  double _progress = 0;
  final List<String> _results = [];

  Future<void> _pick() async {
    final picked = await ImagePicker().pickMultiImage();
    if (picked.isEmpty || !mounted) return;
    if (picked.length > maxFiles) {
      snack(context, tr(context, 'max_images', {'m': maxFiles}));
    }
    setState(() {
      _files = picked.take(maxFiles).toList();
      _results.clear();
    });
  }

  Future<void> _run() async {
    if (_files.isEmpty) return;
    setState(() {
      _busy = true;
      _progress = 0;
      _results.clear();
    });
    try {
      final dir = await outDir();
      int i = 0;
      for (final f in _files) {
        final out = await compute(_sharpenWorker,
            _SharpenArgs(await f.readAsBytes(), _sharp, _contrast));
        if (out != null) {
          final path = '$dir/sharp_${stamp()}_$i.jpg';
          await File(path).writeAsBytes(out);
          _results.add(path);
        }
        i++;
        if (mounted) setState(() => _progress = i / _files.length);
      }
    } catch (e) {
      if (mounted) snack(context, tr(context, 'error', {'e': e}));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionCard(
          title: tr(context, 'images_count',
              {'n': _files.length, 'm': maxFiles}),
          children: [
            FilledButton.tonalIcon(
              onPressed: _busy ? null : _pick,
              icon: const Icon(Icons.photo_library),
              label: Text(tr(context, 'pick_gallery')),
            ),
            const SizedBox(height: 12),
            Text(tr(context, 'sharpness', {'v': (_sharp * 100).round()})),
            Slider(
              value: _sharp,
              min: 0.1,
              max: 1,
              onChanged: _busy ? null : (v) => setState(() => _sharp = v),
            ),
            Text(tr(context, 'contrast',
                {'v': ((_contrast - 1) * 100).round()})),
            Slider(
              value: _contrast,
              min: 1.0,
              max: 1.6,
              onChanged: _busy ? null : (v) => setState(() => _contrast = v),
            ),
          ],
        ),
        if (_busy)
          ProgressBox(
              value: _progress,
              label: tr(context, 'processing',
                  {'p': (_progress * 100).round()})),
        FilledButton.icon(
          onPressed: (_busy || _files.isEmpty) ? null : _run,
          icon: const Icon(Icons.auto_fix_high),
          label: Text(tr(context, 'enhance_btn')),
        ),
        const SizedBox(height: 12),
        for (final p in _results)
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Image.file(File(p),
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    cacheWidth: 600),
                ListTile(
                  title: Text(fmtSize(File(p).lengthSync())),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: tr(context, 'add_downloads'),
                        icon: const Icon(Icons.download),
                        onPressed: () => saveToDownloads(context, p),
                      ),
                      IconButton(
                        tooltip: tr(context, 'share'),
                        icon: const Icon(Icons.share),
                        onPressed: () => shareFile(p),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ============================================================
// 3) PDF YARATUVCHI (2000 tagacha)
// ============================================================
class PdfScreen extends StatefulWidget {
  const PdfScreen({super.key});

  @override
  State<PdfScreen> createState() => _PdfScreenState();
}

class _PdfScreenState extends State<PdfScreen> {
  static const int maxFiles = 2000;
  List<XFile> _files = [];
  bool _busy = false;
  double _progress = 0;
  String? _resultPath;

  Future<void> _pick() async {
    final picked = await ImagePicker().pickMultiImage();
    if (picked.isEmpty) return;
    setState(() {
      _files = [..._files, ...picked].take(maxFiles).toList();
      _resultPath = null;
    });
  }

  Future<void> _run() async {
    if (_files.isEmpty) return;
    setState(() {
      _busy = true;
      _progress = 0;
      _resultPath = null;
    });
    try {
      final doc = pw.Document(compress: true);
      int i = 0;
      for (final f in _files) {
        // Har bir rasm yengillashtiriladi (1600px, JPG 75%)
        final data = await compute(
            _pdfPrepWorker, _PdfPrepArgs(await f.readAsBytes(), 1600));
        if (data != null) {
          final image = pw.MemoryImage(data);
          doc.addPage(pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(12),
            build: (_) =>
                pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain)),
          ));
        }
        i++;
        if (mounted) setState(() => _progress = i / _files.length);
      }
      final bytes = await doc.save();
      final path = '${await outDir()}/pixcompact_${stamp()}.pdf';
      await File(path).writeAsBytes(bytes);
      if (mounted) setState(() => _resultPath = path);
    } catch (e) {
      if (mounted) snack(context, tr(context, 'error', {'e': e}));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: _busy ? null : _pick,
                  icon: const Icon(Icons.add_photo_alternate),
                  label: Text(tr(context, 'add_btn',
                      {'n': _files.length, 'm': maxFiles})),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                onPressed:
                    _busy ? null : () => setState(() => _files.clear()),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ),
        // Tartibni o'zgartirish: ushlab sudrang
        Expanded(
          child: _files.isEmpty
              ? Center(child: Text(tr(context, 'no_images')))
              : ReorderableListView.builder(
                  itemCount: _files.length,
                  onReorder: (o, n) {
                    setState(() {
                      if (n > o) n--;
                      final item = _files.removeAt(o);
                      _files.insert(n, item);
                    });
                  },
                  itemBuilder: (_, i) => ListTile(
                    key: ValueKey('${_files[i].path}_$i'),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.file(File(_files[i].path),
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          cacheWidth: 120),
                    ),
                    title: Text(tr(context, 'page_n', {'n': i + 1})),
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _busy
                          ? null
                          : () => setState(() => _files.removeAt(i)),
                    ),
                  ),
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_busy)
                ProgressBox(
                    value: _progress,
                    label: tr(context, 'pdf_building',
                        {'p': (_progress * 100).round()})),
              FilledButton.icon(
                onPressed: (_busy || _files.isEmpty) ? null : _run,
                icon: const Icon(Icons.picture_as_pdf),
                label: Text(tr(context, 'pdf_btn')),
              ),
              if (_resultPath != null) ...[
                const SizedBox(height: 8),
                Text(
                    '${tr(context, 'done')} ${fmtSize(File(_resultPath!).lengthSync())}',
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                ResultButtons(path: _resultPath!),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// 4) OFFLINE RASM MUHARRIRI
//    Shakl (aylantirish, qirqish, o'lcham), Filtrlar, Sozlash
//    (yorqinlik/kontrast/to'yinganlik), Saqlash (JPG/PNG/WebP).
//    Bekor qilish (undo) va asl holiga qaytarish bor.
// ============================================================
class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  Uint8List? _original; // yuklangan (kichraytirilgan) asl nusxa
  Uint8List? _current; // joriy holat
  final List<Uint8List> _undo = []; // oxirgi 8 ta holat
  bool _busy = false;
  int _tool = 0; // 0 shakl, 1 filtr, 2 sozlash, 3 saqlash

  // Sozlash qiymatlari (1.0 = o'zgarishsiz)
  double _bright = 1.0;
  double _contrast = 1.0;
  double _sat = 1.0;
  double _resize = 100;

  // Saqlash sozlamalari
  String _fmt = 'jpg';
  double _exportQ = 90;

  Future<void> _pick() async {
    final f = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (f == null) return;
    setState(() => _busy = true);
    final out = await compute(_loadWorker, await f.readAsBytes());
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (out != null) {
        _original = out;
        _current = out;
        _undo.clear();
        _bright = _contrast = _sat = 1.0;
        _resize = 100;
      }
    });
  }

  /// Bitta tahrirlash amalini fon rejimida qo'llash
  Future<void> _apply(String op,
      {double a = 0, double b = 0, double c = 0}) async {
    if (_current == null || _busy) return;
    setState(() => _busy = true);
    try {
      final out =
          await compute(_editWorker, _EditArgs(_current!, op, a: a, b: b, c: c));
      if (!mounted) return;
      if (out != null) {
        _undo.add(_current!);
        if (_undo.length > 8) _undo.removeAt(0);
        _current = out;
      }
    } catch (e) {
      if (mounted) snack(context, tr(context, 'error', {'e': e}));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Joriy rasmni tanlangan formatda faylga yozish
  Future<String?> _exportFile() async {
    if (_current == null) return null;
    setState(() => _busy = true);
    try {
      final base = await compute(_exportWorker,
          _ExportArgs(_current!, _fmt == 'webp' ? 'png' : _fmt, _exportQ.round()));
      if (base == null) return null;
      final out = _fmt == 'webp' ? await toWebp(base, _exportQ.round()) : base;
      final path = '${await outDir()}/edit_${stamp()}.$_fmt';
      await File(path).writeAsBytes(out);
      return path;
    } catch (e) {
      if (mounted) snack(context, tr(context, 'error', {'e': e}));
      return null;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_current == null) {
      return Center(
        child: _busy
            ? const CircularProgressIndicator()
            : FilledButton.tonalIcon(
                onPressed: _pick,
                icon: const Icon(Icons.photo),
                label: Text(tr(context, 'pick_image')),
              ),
      );
    }
    final size = pngSize(_current!);
    return Column(
      children: [
        // Ko'rinish (zoom qilish mumkin)
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              InteractiveViewer(
                maxScale: 5,
                child: Image.memory(_current!,
                    fit: BoxFit.contain, gaplessPlayback: true),
              ),
              if (_busy) const CircularProgressIndicator(),
            ],
          ),
        ),
        // Ma'lumot + undo / asl holiga / boshqa rasm
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Text(tr(context, 'image_info', {'w': size[0], 'h': size[1]}),
                  style: Theme.of(context).textTheme.bodySmall),
              const Spacer(),
              IconButton(
                tooltip: tr(context, 'undo'),
                onPressed: (_busy || _undo.isEmpty)
                    ? null
                    : () => setState(() => _current = _undo.removeLast()),
                icon: const Icon(Icons.undo),
              ),
              IconButton(
                tooltip: tr(context, 'restore'),
                onPressed: _busy
                    ? null
                    : () => setState(() {
                          _current = _original;
                          _undo.clear();
                        }),
                icon: const Icon(Icons.restore),
              ),
              IconButton(
                tooltip: tr(context, 'pick_other'),
                onPressed: _busy ? null : _pick,
                icon: const Icon(Icons.photo_library_outlined),
              ),
            ],
          ),
        ),
        // Asboblar tanlash
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _toolChip(0, Icons.crop_rotate, 'tool_transform'),
              _toolChip(1, Icons.auto_awesome, 'tool_filters'),
              _toolChip(2, Icons.tune, 'tool_adjust'),
              _toolChip(3, Icons.save_alt, 'tool_export'),
            ],
          ),
        ),
        // Tanlangan asbob paneli
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 260),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: _panel(),
          ),
        ),
      ],
    );
  }

  Widget _toolChip(int i, IconData icon, String key) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          avatar: Icon(icon, size: 18),
          label: Text(tr(context, key)),
          selected: _tool == i,
          onSelected: (_) => setState(() => _tool = i),
        ),
      );

  Widget _opChip(IconData icon, String labelKey, String op,
      {double a = 0, double b = 0}) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(tr(context, labelKey)),
      onPressed: _busy ? null : () => _apply(op, a: a, b: b),
    );
  }

  Widget _panel() {
    switch (_tool) {
      case 0: // SHAKL
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _opChip(Icons.rotate_left, 'rotate_left', 'rotL'),
                _opChip(Icons.rotate_right, 'rotate_right', 'rotR'),
                _opChip(Icons.flip, 'op_flip_h', 'flipH'),
                _opChip(Icons.flip_camera_android, 'op_flip_v', 'flipV'),
              ],
            ),
            const SizedBox(height: 12),
            Text(tr(context, 'crop_title'),
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final r in const [
                  ['1:1', 1.0, 1.0],
                  ['4:3', 4.0, 3.0],
                  ['3:4', 3.0, 4.0],
                  ['16:9', 16.0, 9.0],
                  ['9:16', 9.0, 16.0],
                ])
                  ActionChip(
                    avatar: const Icon(Icons.crop, size: 18),
                    label: Text(r[0] as String),
                    onPressed: _busy
                        ? null
                        : () => _apply('crop',
                            a: r[1] as double, b: r[2] as double),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(tr(context, 'resize_title', {'v': _resize.round()})),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _resize,
                    min: 10,
                    max: 100,
                    divisions: 90,
                    onChanged:
                        _busy ? null : (v) => setState(() => _resize = v),
                  ),
                ),
                FilledButton.tonal(
                  onPressed: _busy || _resize >= 100
                      ? null
                      : () async {
                          await _apply('resize', a: _resize);
                          if (mounted) setState(() => _resize = 100);
                        },
                  child: Text(tr(context, 'apply')),
                ),
              ],
            ),
          ],
        );
      case 1: // FILTRLAR
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _opChip(Icons.filter_b_and_w, 'op_gray', 'gray'),
            _opChip(Icons.photo_filter, 'op_sepia', 'sepia'),
            _opChip(Icons.invert_colors, 'op_invert', 'invert'),
            _opChip(Icons.blur_on, 'op_blur', 'blur'),
            _opChip(Icons.deblur, 'op_sharpen', 'sharpen'),
            _opChip(Icons.vignette, 'op_vignette', 'vignette'),
          ],
        );
      case 2: // SOZLASH
        return Column(
          children: [
            _adjSlider('brightness', _bright, 0.5, 1.5,
                (v) => setState(() => _bright = v)),
            _adjSlider('contrast', _contrast, 0.5, 1.5,
                (v) => setState(() => _contrast = v)),
            _adjSlider('saturation', _sat, 0.0, 2.0,
                (v) => setState(() => _sat = v)),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonal(
                onPressed: _busy
                    ? null
                    : () async {
                        await _apply('adjust', a: _bright, b: _contrast, c: _sat);
                        if (mounted) {
                          setState(() => _bright = _contrast = _sat = 1.0);
                        }
                      },
                child: Text(tr(context, 'apply')),
              ),
            ),
          ],
        );
      default: // SAQLASH
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'jpg', label: Text('JPG')),
                ButtonSegment(value: 'png', label: Text('PNG')),
                ButtonSegment(value: 'webp', label: Text('WebP')),
              ],
              selected: {_fmt},
              onSelectionChanged:
                  _busy ? null : (s) => setState(() => _fmt = s.first),
            ),
            if (_fmt != 'png') ...[
              const SizedBox(height: 8),
              Text(tr(context, 'quality', {'v': _exportQ.round()})),
              Slider(
                value: _exportQ,
                min: 30,
                max: 100,
                divisions: 70,
                onChanged: _busy ? null : (v) => setState(() => _exportQ = v),
              ),
            ],
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _busy
                  ? null
                  : () async {
                      final p = await _exportFile();
                      if (p != null && mounted) await saveToDownloads(context, p);
                    },
              icon: const Icon(Icons.download),
              label: Text(tr(context, 'add_downloads')),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _busy
                  ? null
                  : () async {
                      final p = await _exportFile();
                      if (p != null) await shareFile(p);
                    },
              icon: const Icon(Icons.share),
              label: Text(tr(context, 'share')),
            ),
          ],
        );
    }
  }

  Widget _adjSlider(String key, double value, double min, double max,
      ValueChanged<double> onChanged) {
    final pct = ((value - 1) * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr(context, key, {'v': pct > 0 ? '+$pct' : '$pct'})),
        Slider(
          value: value,
          min: min,
          max: max,
          onChanged: _busy ? null : onChanged,
        ),
      ],
    );
  }
}

// ============================================================
// 5) OFFLINE VIDEO MUHARRIR
//    Qirqish (trim), siqish darajasi, ovozni o'chirish, FPS,
//    kadrni rasm qilib saqlash. Hammasi internetsiz.
// ============================================================
class VideoScreen extends StatefulWidget {
  const VideoScreen({super.key});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  String? _path;
  double _duration = 0; // soniya
  int _w = 0, _h = 0;
  int _originalSize = 0;
  Uint8List? _thumb;
  RangeValues _range = const RangeValues(0, 1);

  VideoQuality _quality = VideoQuality.MediumQuality;
  bool _mute = false;
  int _fps = 30;

  bool _loading = false;
  bool _busy = false;
  double _progress = 0;
  String? _resultPath;
  int _resultSize = 0;
  dynamic _sub; // progress obunasi

  @override
  void initState() {
    super.initState();
    _sub = VideoCompress.compressProgress$.subscribe((p) {
      if (mounted) setState(() => _progress = (p / 100).clamp(0.0, 1.0));
    });
  }

  @override
  void dispose() {
    _sub?.unsubscribe();
    VideoCompress.cancelCompression();
    super.dispose();
  }

  Future<void> _pick() async {
    final f = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (f == null) return;
    setState(() {
      _loading = true;
      _resultPath = null;
    });
    try {
      final info = await VideoCompress.getMediaInfo(f.path);
      final thumb = await VideoCompress.getByteThumbnail(f.path, quality: 60);
      final dur = ((info.duration ?? 0) / 1000).toDouble();
      if (!mounted) return;
      setState(() {
        _path = f.path;
        _duration = dur;
        _w = info.width ?? 0;
        _h = info.height ?? 0;
        _originalSize = File(f.path).lengthSync();
        _thumb = thumb;
        _range = RangeValues(0, dur < 1 ? 1 : dur);
      });
    } catch (e) {
      if (mounted) snack(context, tr(context, 'error', {'e': e}));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Qirqish boshlanish nuqtasidagi kadrni ko'rsatish
  Future<void> _updateThumb() async {
    if (_path == null) return;
    final t = await VideoCompress.getByteThumbnail(_path!,
        quality: 60, position: (_range.start * 1000).round());
    if (mounted) setState(() => _thumb = t);
  }

  /// Tanlangan kadrni JPG sifatida Yuklamalarga saqlash
  Future<void> _saveFrame() async {
    if (_path == null) return;
    try {
      final bytes = await VideoCompress.getByteThumbnail(_path!,
          quality: 100, position: (_range.start * 1000).round());
      final p = '${await outDir()}/frame_${stamp()}.jpg';
      await File(p).writeAsBytes(bytes);
      if (mounted) await saveToDownloads(context, p);
    } catch (e) {
      if (mounted) snack(context, tr(context, 'error', {'e': e}));
    }
  }

  Future<void> _run() async {
    if (_path == null) return;
    setState(() {
      _busy = true;
      _progress = 0;
      _resultPath = null;
    });
    try {
      final trimmed = _range.start > 0.5 || _range.end < _duration - 0.5;
      final info = await VideoCompress.compressVideo(
        _path!,
        quality: _quality,
        deleteOrigin: false, // asl videoni o'chirmaymiz
        includeAudio: !_mute,
        frameRate: _fps,
        startTime: trimmed ? _range.start.floor() : null,
        duration: trimmed ? (_range.end - _range.start).ceil() : null,
      );
      if (info?.file == null) throw Exception('video_fail');
      final dest = '${await outDir()}/video_${stamp()}.mp4';
      await info!.file!.copy(dest);
      if (!mounted) return;
      setState(() {
        _resultPath = dest;
        _resultSize = File(dest).lengthSync();
      });
    } catch (e) {
      if (mounted) {
        final msg = e.toString().contains('video_fail')
            ? tr(context, 'video_fail')
            : '$e';
        snack(context, tr(context, 'error', {'e': msg}));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasVideo = _path != null;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionCard(
          title: tr(context, 'video_section'),
          children: [
            FilledButton.tonalIcon(
              onPressed: (_busy || _loading) ? null : _pick,
              icon: const Icon(Icons.video_library),
              label: Text(tr(context, 'pick_video')),
            ),
            if (_loading)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: ProgressBox(label: tr(context, 'loading')),
              ),
            if (hasVideo) ...[
              const SizedBox(height: 12),
              if (_thumb != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(_thumb!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      gaplessPlayback: true),
                ),
              const SizedBox(height: 8),
              Text(tr(context, 'file_label', {'f': _path!.split('/').last}),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(tr(context, 'video_info',
                  {'w': _w, 'h': _h, 'd': fmtTime(_duration)})),
              Text(tr(context, 'size_label', {'s': fmtSize(_originalSize)})),
            ],
          ],
        ),
        if (hasVideo && _duration > 1)
          SectionCard(
            title: tr(context, 'trim_title'),
            children: [
              Text(tr(context, 'trim_range', {
                'a': fmtTime(_range.start),
                'b': fmtTime(_range.end),
                'd': fmtTime(_range.end - _range.start),
              })),
              RangeSlider(
                values: _range,
                min: 0,
                max: _duration,
                divisions: _duration.floor().clamp(1, 100000),
                labels: RangeLabels(
                    fmtTime(_range.start), fmtTime(_range.end)),
                onChanged:
                    _busy ? null : (v) => setState(() => _range = v),
                onChangeEnd: (_) => _updateThumb(),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _busy ? null : _saveFrame,
                  icon: const Icon(Icons.image_outlined),
                  label: Text(tr(context, 'save_frame')),
                ),
              ),
            ],
          ),
        if (hasVideo)
          SectionCard(
            title: tr(context, 'level_title'),
            children: [
              SegmentedButton<VideoQuality>(
                segments: [
                  ButtonSegment(
                      value: VideoQuality.LowQuality,
                      label: Text(tr(context, 'level_strong'))),
                  ButtonSegment(
                      value: VideoQuality.MediumQuality,
                      label: Text(tr(context, 'level_medium'))),
                  ButtonSegment(
                      value: VideoQuality.HighQuality,
                      label: Text(tr(context, 'level_light'))),
                ],
                selected: {_quality},
                onSelectionChanged:
                    _busy ? null : (s) => setState(() => _quality = s.first),
              ),
              const SizedBox(height: 6),
              Text(
                tr(context, 'level_hint'),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Text(tr(context, 'fps_title')),
              const SizedBox(height: 6),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 15, label: Text('15')),
                  ButtonSegment(value: 24, label: Text('24')),
                  ButtonSegment(value: 30, label: Text('30')),
                ],
                selected: {_fps},
                onSelectionChanged:
                    _busy ? null : (s) => setState(() => _fps = s.first),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(tr(context, 'mute_audio')),
                value: _mute,
                onChanged: _busy ? null : (v) => setState(() => _mute = v),
              ),
            ],
          ),
        if (_busy)
          ProgressBox(
              value: _progress,
              label: tr(context, 'video_progress',
                  {'p': (_progress * 100).round()})),
        FilledButton.icon(
          onPressed: (_busy || !hasVideo) ? null : _run,
          icon: const Icon(Icons.movie_edit),
          label: Text(tr(context, 'video_btn')),
        ),
        if (_resultPath != null) ...[
          const SizedBox(height: 12),
          SectionCard(
            title: tr(context, 'done'),
            children: [
              Text(tr(context, 'sizes_info', {
                'a': fmtSize(_originalSize),
                'b': fmtSize(_resultSize),
              })),
              const SizedBox(height: 12),
              ResultButtons(path: _resultPath!),
            ],
          ),
        ],
      ],
    );
  }
}
