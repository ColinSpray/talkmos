import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';

/// First page of a PDF, rendered once and kept on disk.
class PdfPreview {
  final Uint8List image;
  final int pageCount;

  const PdfPreview({required this.image, required this.pageCount});
}

class PdfPreviewService {
  static final PdfPreviewService _instance = PdfPreviewService._internal();
  factory PdfPreviewService() => _instance;
  PdfPreviewService._internal();

  static const String _dirName = 'pdf_thumbs';

  /// Wide enough for the preview screen's full-width render; the bubble scales
  /// the same bitmap down rather than rendering a second time.
  static const double _renderWidth = 640;

  /// Rendering blocks on native decode, so two bubbles for the same file must
  /// not both pay for it. Keyed by cache key, cleared once the render lands.
  final Map<String, Future<PdfPreview?>> _inFlight = {};

  /// In-memory hits for the current session, so a scroll back up the list does
  /// not hit the disk again.
  final Map<String, PdfPreview> _memory = {};

  static bool isPdf({String fileName = '', String mimeType = ''}) {
    if (mimeType.toLowerCase() == 'application/pdf') return true;
    return fileName.toLowerCase().endsWith('.pdf');
  }

  /// FNV-1a, so the key is a filesystem-safe fixed-length string. Not a
  /// security hash — a collision costs one wrong thumbnail, not anything worse.
  String _keyFor(String source) {
    var hash = 0xcbf29ce484222325;
    for (final unit in source.codeUnits) {
      hash = (hash ^ unit) * 0x100000001b3;
      hash &= 0xFFFFFFFFFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }

  Future<Directory> _cacheDir() async {
    final base = await getTemporaryDirectory();
    final dir = Directory(p.join(base.path, _dirName));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Renders from a file already on disk. [cacheKey] should be stable for the
  /// document — the remote url for a received file, the path for a local one.
  Future<PdfPreview?> fromFile(File file, {required String cacheKey}) async {
    final key = _keyFor(cacheKey);
    if (_memory.containsKey(key)) return _memory[key];

    final pending = _inFlight[key];
    if (pending != null) return pending;

    final future = _render(() => PdfDocument.openFile(file.path), key);
    _inFlight[key] = future;
    try {
      return await future;
    } finally {
      _inFlight.remove(key);
    }
  }

  /// Renders straight from bytes, for a document picked but not yet sent.
  Future<PdfPreview?> fromBytes(Uint8List bytes, {String? cacheKey}) async {
    final key = _keyFor(cacheKey ?? '${bytes.length}:${bytes.hashCode}');
    if (_memory.containsKey(key)) return _memory[key];

    final pending = _inFlight[key];
    if (pending != null) return pending;

    final future = _render(() => PdfDocument.openData(bytes), key);
    _inFlight[key] = future;
    try {
      return await future;
    } finally {
      _inFlight.remove(key);
    }
  }

  /// A render that has not landed by here is not going to be worth waiting
  /// for — and on a platform with no PDF renderer at all the open never
  /// completes, so without this the caller's spinner turns forever.
  static const Duration _renderTimeout = Duration(seconds: 12);

  /// Bounds the whole attempt — the disk read included, since a platform with
  /// no temp directory and no PDF renderer hangs rather than failing, and the
  /// caller is showing a spinner until this answers.
  Future<PdfPreview?> _render(Future<PdfDocument> Function() open, String key) {
    return _renderUnbounded(open, key).timeout(
      _renderTimeout,
      onTimeout: () {
        debugPrint('[PdfPreview] render timed out');
        return null;
      },
    );
  }

  Future<PdfPreview?> _renderUnbounded(
    Future<PdfDocument> Function() open,
    String key,
  ) async {
    final cached = await _readFromDisk(key);
    if (cached != null) {
      _memory[key] = cached;
      return cached;
    }

    PdfDocument? document;
    PdfPage? page;
    try {
      document = await open();
      final pageCount = document.pagesCount;
      if (pageCount < 1) return null;

      page = await document.getPage(1);
      final scale = _renderWidth / page.width;
      final rendered = await page.render(
        width: _renderWidth,
        height: page.height * scale,
        format: PdfPageImageFormat.png,
        backgroundColor: '#FFFFFF',
      );
      if (rendered == null) return null;

      final preview = PdfPreview(image: rendered.bytes, pageCount: pageCount);
      _memory[key] = preview;
      await _writeToDisk(key, preview);
      return preview;
    } catch (e) {
      debugPrint('[PdfPreview] render failed: $e');
      return null;
    } finally {
      await page?.close();
      await document?.close();
    }
  }

  File _imageFile(Directory dir, String key) =>
      File(p.join(dir.path, '$key.png'));

  File _metaFile(Directory dir, String key) =>
      File(p.join(dir.path, '$key.pages'));

  Future<PdfPreview?> _readFromDisk(String key) async {
    try {
      final dir = await _cacheDir();
      final image = _imageFile(dir, key);
      final meta = _metaFile(dir, key);
      if (!await image.exists() || !await meta.exists()) return null;

      final pageCount = int.tryParse((await meta.readAsString()).trim());
      if (pageCount == null) return null;

      return PdfPreview(image: await image.readAsBytes(), pageCount: pageCount);
    } catch (e) {
      debugPrint('[PdfPreview] disk read failed: $e');
      return null;
    }
  }

  Future<void> _writeToDisk(String key, PdfPreview preview) async {
    try {
      final dir = await _cacheDir();
      await _imageFile(dir, key).writeAsBytes(preview.image);
      await _metaFile(dir, key).writeAsString('${preview.pageCount}');
    } catch (e) {
      debugPrint('[PdfPreview] disk write failed: $e');
    }
  }

  Future<void> clearCache() async {
    _memory.clear();
    try {
      final dir = await _cacheDir();
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (e) {
      debugPrint('[PdfPreview] clear failed: $e');
    }
  }
}
