// PixCompact — Audio konvertor va hajmni kichraytiruvchi (Compressor)
//
// Bu fayl main.dart ga tegmasdan, alohida bo'lim sifatida ishlaydi.
// Umumiy vidjetlar (SectionCard, ProgressBox, ResultButtons) va yordamchi
// funksiyalar (outDir, stamp, fmtSize, fmtTime, snack, tr) main.dart dan olinadi.
//
// FFmpeg paketi haqida: asl so'ralgan `ffmpeg_kit_flutter_min_gpl` ishdan
// chiqarilgan (discontinued), uning Android binarlari Maven'dan o'chirilgan va
// "min" to'plamida MP3 kodlagichi (libmp3lame) yo'q. Shu sabab faol qo'llab-
// quvvatlanadigan `ffmpeg_kit_flutter_new_audio` ishlatilgan (API bir xil).
// Paketni almashtirish uchun faqat pastdagi 3 ta `import ffmpeg_kit...`
// qatoridagi paket nomini o'zgartirish kifoya.
import 'dart:async';
import 'dart:io';

import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_audio/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new_audio/return_code.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'main.dart';

// ============================================================
// TILLAR (uz / en / ru) — main.dart dagi katta jadvalga tegmaslik uchun
// shu faylning o'zida saqlanadi. HomePage ham shu funksiyadan foydalanadi.
// ============================================================
const Map<String, Map<String, String>> _audioStrings = {
  'uz': {
    'title_audio': 'Audio konvertor',
    'nav_audio': 'Audio',
    'audio_section': 'Audio fayl',
    'pick_audio': 'Telefondan audio tanlash',
    'pick_other_audio': 'Boshqa fayl tanlash',
    'audio_info': 'Davomiyligi: {d}',
    'audio_avg_bitrate': 'O\'rtacha bitrate: ~{b} kbps',
    'out_format': 'Chiqish formati',
    'bitrate_title': 'Bitrate: {v} kbps',
    'bitrate_hint':
        'Past bitrate — kichik hajm, past sifat. 128 kbps odatda yetarli.',
    'est_size': 'Taxminiy hajmi: ~{s}',
    'lossless_note':
        'WAV va FLAC yo\'qotishsiz formatlar — bitrate ta\'sir qilmaydi. WAV hajmi odatda kattalashadi.',
    'convert_btn': 'Konvertatsiya qilish',
    'cancel_btn': 'Bekor qilish',
    'converting': '{p}% — konvertatsiya qilinmoqda...',
    'converting_unknown': 'Konvertatsiya qilinmoqda...',
    'cancelled': 'Bekor qilindi',
    'convert_fail': 'Konvertatsiya bajarilmadi',
    'pick_fail': 'Faylni o\'qib bo\'lmadi',
  },
  'en': {
    'title_audio': 'Audio converter',
    'nav_audio': 'Audio',
    'audio_section': 'Audio file',
    'pick_audio': 'Pick audio from phone',
    'pick_other_audio': 'Pick another file',
    'audio_info': 'Duration: {d}',
    'audio_avg_bitrate': 'Average bitrate: ~{b} kbps',
    'out_format': 'Output format',
    'bitrate_title': 'Bitrate: {v} kbps',
    'bitrate_hint':
        'Lower bitrate — smaller file, lower quality. 128 kbps is usually enough.',
    'est_size': 'Estimated size: ~{s}',
    'lossless_note':
        'WAV and FLAC are lossless — bitrate has no effect. WAV files usually get bigger.',
    'convert_btn': 'Convert',
    'cancel_btn': 'Cancel',
    'converting': '{p}% — converting...',
    'converting_unknown': 'Converting...',
    'cancelled': 'Cancelled',
    'convert_fail': 'Conversion failed',
    'pick_fail': 'Could not read the file',
  },
  'ru': {
    'title_audio': 'Аудио конвертер',
    'nav_audio': 'Аудио',
    'audio_section': 'Аудиофайл',
    'pick_audio': 'Выбрать аудио с телефона',
    'pick_other_audio': 'Выбрать другой файл',
    'audio_info': 'Длительность: {d}',
    'audio_avg_bitrate': 'Средний битрейт: ~{b} кбит/с',
    'out_format': 'Выходной формат',
    'bitrate_title': 'Битрейт: {v} кбит/с',
    'bitrate_hint':
        'Ниже битрейт — меньше размер и качество. Обычно хватает 128 кбит/с.',
    'est_size': 'Примерный размер: ~{s}',
    'lossless_note':
        'WAV и FLAC — форматы без потерь, битрейт не влияет. Размер WAV обычно растёт.',
    'convert_btn': 'Конвертировать',
    'cancel_btn': 'Отмена',
    'converting': '{p}% — конвертация...',
    'converting_unknown': 'Конвертация...',
    'cancelled': 'Отменено',
    'convert_fail': 'Не удалось конвертировать',
    'pick_fail': 'Не удалось прочитать файл',
  },
};

/// Audio bo'limi uchun tarjima (tizim tiliga qarab; boshqa til — inglizcha).
String audioTr(BuildContext context, String key, [Map<String, Object>? p]) {
  final code = Localizations.localeOf(context).languageCode;
  final table = _audioStrings[code] ?? _audioStrings['en']!;
  var s = table[key] ?? _audioStrings['en']![key] ?? key;
  p?.forEach((k, v) => s = s.replaceAll('{$k}', '$v'));
  return s;
}

// ============================================================
// CHIQISH FORMATLARI
// ============================================================
enum _AudioFormat {
  mp3('MP3', 'mp3', true),
  aac('AAC', 'm4a', true), // AAC — M4A konteynerida (hamma joyda ochiladi)
  wav('WAV', 'wav', false),
  flac('FLAC', 'flac', false);

  const _AudioFormat(this.label, this.ext, this.lossy);

  final String label;
  final String ext;

  /// true — bitrate ta'sir qiladi (MP3, AAC); false — yo'qotishsiz (WAV, FLAC)
  final bool lossy;

  /// FFmpeg kodek argumentlari
  List<String> codecArgs(int kbps) {
    switch (this) {
      case _AudioFormat.mp3:
        return ['-c:a', 'libmp3lame', '-b:a', '${kbps}k'];
      case _AudioFormat.aac:
        return ['-c:a', 'aac', '-b:a', '${kbps}k'];
      case _AudioFormat.wav:
        return ['-c:a', 'pcm_s16le'];
      case _AudioFormat.flac:
        return ['-c:a', 'flac'];
    }
  }
}

/// Konvertatsiya natijasi (ichki)
class _Outcome {
  final bool ok;
  final bool cancelled;
  final String? log;
  const _Outcome({required this.ok, this.cancelled = false, this.log});
}

// ============================================================
// EKRAN
// ============================================================
class AudioScreen extends StatefulWidget {
  const AudioScreen({super.key});

  @override
  State<AudioScreen> createState() => _AudioScreenState();
}

class _AudioScreenState extends State<AudioScreen> {
  /// Slayder qadamlari (kbps)
  static const List<int> _levels = [32, 48, 64, 96, 128, 160, 192, 256, 320];

  /// Tezkor tanlov tugmalari (_levels ichidan)
  static const List<int> _presets = [64, 96, 128, 192, 320];

  String? _path; // tanlangan fayl yo'li
  String _name = '';
  int _originalSize = 0;
  double _duration = 0; // soniya (0 — noma'lum)

  _AudioFormat _format = _AudioFormat.mp3;
  int _kbps = 128;

  bool _loading = false; // fayl tahlil qilinmoqda
  bool _busy = false; // konvertatsiya ketmoqda
  double? _progress; // 0..1, null — noma'lum
  String? _resultPath;
  int _resultSize = 0;

  @override
  void dispose() {
    // Ekran yopilsa, ishlayotgan jarayonni to'xtatamiz
    if (_busy) FFmpegKit.cancel();
    super.dispose();
  }

  // ---------- Fayl tanlash ----------
  Future<void> _pick() async {
    try {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.audio, // faqat audio fayllar
        allowMultiple: false,
      );
      final path = res?.files.single.path;
      if (res == null) return; // foydalanuvchi bekor qildi
      if (path == null) {
        if (mounted) snack(context, audioTr(context, 'pick_fail'));
        return;
      }

      setState(() {
        _loading = true;
        _resultPath = null;
      });

      final dur = await _probeDuration(path);
      if (!mounted) return;
      setState(() {
        _path = path;
        _name = path.split('/').last;
        _originalSize = File(path).lengthSync();
        _duration = dur;
      });
    } catch (e) {
      if (mounted) snack(context, tr(context, 'error', {'e': e}));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// FFprobe orqali davomiylikni olish (xato bo'lsa 0)
  Future<double> _probeDuration(String path) async {
    try {
      final session = await FFprobeKit.getMediaInformation(path);
      final info = session.getMediaInformation();
      return double.tryParse(info?.getDuration() ?? '') ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Chiqish fayl nomi uchun xavfsiz asos
  String _baseName(String path) {
    var n = path.split('/').last;
    final dot = n.lastIndexOf('.');
    if (dot > 0) n = n.substring(0, dot);
    n = n.replaceAll(RegExp(r'[^\w\-]+'), '_');
    if (n.length > 40) n = n.substring(0, 40);
    return n.isEmpty ? 'audio' : n;
  }

  // ---------- Konvertatsiya ----------
  Future<void> _convert() async {
    final input = _path;
    if (input == null || _busy) return;

    setState(() {
      _busy = true;
      _progress = _duration > 0 ? 0 : null;
      _resultPath = null;
    });

    final fmt = _format;
    final out = '${await outDir()}/${_baseName(input)}_${stamp()}.${fmt.ext}';

    // Argumentlar ro'yxati — bo'shliq/maxsus belgili yo'llar uchun xavfsiz
    final args = <String>[
      '-y', // mavjud faylni almashtirish
      '-i', input,
      '-vn', // albom rasmi (video oqimi)ni tashlab yuborish
      '-map_metadata', '0', // nom, ijrochi kabi teglarni saqlash
      ...fmt.codecArgs(_kbps),
      out,
    ];

    final done = Completer<_Outcome>();
    try {
      await FFmpegKit.executeWithArgumentsAsync(
        args,
        // Tugaganda
        (session) async {
          final rc = await session.getReturnCode();
          if (ReturnCode.isSuccess(rc)) {
            done.complete(const _Outcome(ok: true));
          } else if (ReturnCode.isCancel(rc)) {
            done.complete(const _Outcome(ok: false, cancelled: true));
          } else {
            final log = await session.getOutput();
            done.complete(_Outcome(ok: false, log: log));
          }
        },
        null, // log callback kerak emas
        // Jarayon foizi
        (stats) {
          if (!mounted || _duration <= 0) return;
          final ms = stats.getTime();
          if (ms > 0) {
            setState(() => _progress = (ms / 1000 / _duration).clamp(0.0, 1.0));
          }
        },
      );

      final r = await done.future;
      if (!mounted) return;

      if (r.ok && await File(out).exists()) {
        setState(() {
          _resultPath = out;
          _resultSize = File(out).lengthSync();
        });
      } else {
        await _deleteQuietly(out);
        if (r.cancelled) {
          snack(context, audioTr(context, 'cancelled'));
        } else {
          final log = (r.log ?? '').trim();
          final tail = log.length > 160 ? log.substring(log.length - 160) : log;
          snack(
            context,
            tail.isEmpty
                ? audioTr(context, 'convert_fail')
                : '${audioTr(context, 'convert_fail')}: $tail',
          );
        }
      }
    } catch (e) {
      await _deleteQuietly(out);
      if (mounted) snack(context, tr(context, 'error', {'e': e}));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteQuietly(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  // ---------- Interfeys ----------
  @override
  Widget build(BuildContext context) {
    final hasFile = _path != null;
    final avgKbps = (_duration > 0 && _originalSize > 0)
        ? (_originalSize * 8 / _duration / 1000).round()
        : 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1) Fayl tanlash
        SectionCard(
          title: audioTr(context, 'audio_section'),
          children: [
            FilledButton.tonalIcon(
              onPressed: (_busy || _loading) ? null : _pick,
              icon: const Icon(Icons.audio_file),
              label: Text(audioTr(
                  context, hasFile ? 'pick_other_audio' : 'pick_audio')),
            ),
            if (_loading)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: ProgressBox(label: tr(context, 'loading')),
              ),
            if (hasFile) ...[
              const SizedBox(height: 12),
              Text(tr(context, 'file_label', {'f': _name}),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(tr(context, 'size_label', {'s': fmtSize(_originalSize)})),
              if (_duration > 0)
                Text(audioTr(context, 'audio_info', {'d': fmtTime(_duration)})),
              if (avgKbps > 0)
                Text(audioTr(context, 'audio_avg_bitrate', {'b': avgKbps})),
            ],
          ],
        ),

        // 2) Chiqish formati
        if (hasFile)
          SectionCard(
            title: audioTr(context, 'out_format'),
            children: [
              SegmentedButton<_AudioFormat>(
                segments: [
                  for (final f in _AudioFormat.values)
                    ButtonSegment(value: f, label: Text(f.label)),
                ],
                selected: {_format},
                onSelectionChanged:
                    _busy ? null : (s) => setState(() => _format = s.first),
              ),
            ],
          ),

        // 3) Bitrate (faqat MP3 / AAC uchun)
        if (hasFile)
          SectionCard(
            title: audioTr(context, 'bitrate_title', {'v': _kbps}),
            children: [
              if (_format.lossy) ...[
                Slider(
                  value: _levels.indexOf(_kbps).toDouble(),
                  min: 0,
                  max: (_levels.length - 1).toDouble(),
                  divisions: _levels.length - 1,
                  label: '$_kbps kbps',
                  onChanged: _busy
                      ? null
                      : (v) => setState(() => _kbps = _levels[v.round()]),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final v in _presets)
                      ChoiceChip(
                        label: Text('$v'),
                        selected: _kbps == v,
                        onSelected:
                            _busy ? null : (_) => setState(() => _kbps = v),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  audioTr(context, 'bitrate_hint'),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                if (_duration > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(audioTr(context, 'est_size', {
                      's': fmtSize((_kbps * 1000 / 8 * _duration).round()),
                    })),
                  ),
              ] else
                Text(
                  audioTr(context, 'lossless_note'),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
            ],
          ),

        // 4) Jarayon
        if (_busy)
          ProgressBox(
            value: _progress,
            label: _progress == null
                ? audioTr(context, 'converting_unknown')
                : audioTr(context, 'converting',
                    {'p': (_progress! * 100).round()}),
          ),

        // 5) Boshlash / bekor qilish
        if (_busy)
          OutlinedButton.icon(
            onPressed: () => FFmpegKit.cancel(),
            icon: const Icon(Icons.close),
            label: Text(audioTr(context, 'cancel_btn')),
          )
        else
          FilledButton.icon(
            onPressed: hasFile ? _convert : null,
            icon: const Icon(Icons.transform),
            label: Text(audioTr(context, 'convert_btn')),
          ),

        // 6) Natija: saqlash / ulashish (umumiy ResultButtons)
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
