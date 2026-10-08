import 'package:flutter/material.dart';

/// How a document is presented: its icon, its accent colour, and the short
/// label shown next to the size.
class FileTypeDisplay {
  final IconData icon;
  final Color color;
  final String label;

  const FileTypeDisplay({
    required this.icon,
    required this.color,
    required this.label,
  });
}

const _pdf = FileTypeDisplay(
  icon: Icons.picture_as_pdf_rounded,
  color: Color(0xFFE5342A),
  label: 'PDF',
);

const _doc = FileTypeDisplay(
  icon: Icons.description_rounded,
  color: Color(0xFF2B579A),
  label: 'DOC',
);

const _sheet = FileTypeDisplay(
  icon: Icons.table_chart_rounded,
  color: Color(0xFF217346),
  label: 'XLS',
);

const _slides = FileTypeDisplay(
  icon: Icons.slideshow_rounded,
  color: Color(0xFFD24726),
  label: 'PPT',
);

const _archive = FileTypeDisplay(
  icon: Icons.folder_zip_rounded,
  color: Color(0xFF8B5CF6),
  label: 'ZIP',
);

const _text = FileTypeDisplay(
  icon: Icons.article_rounded,
  color: Color(0xFF64748B),
  label: 'TXT',
);

const _generic = FileTypeDisplay(
  icon: Icons.insert_drive_file_rounded,
  color: Color(0xFF64748B),
  label: 'FILE',
);

String fileExtensionOf(String fileName) {
  final dot = fileName.lastIndexOf('.');
  if (dot == -1 || dot == fileName.length - 1) return '';
  return fileName.substring(dot + 1).toLowerCase();
}

FileTypeDisplay fileTypeDisplayFor({
  String fileName = '',
  String mimeType = '',
}) {
  final ext = fileExtensionOf(fileName);
  final mime = mimeType.toLowerCase();

  if (mime == 'application/pdf' || ext == 'pdf') return _pdf;
  if (['doc', 'docx', 'odt', 'rtf', 'pages'].contains(ext)) return _doc;
  if (['xls', 'xlsx', 'csv', 'ods', 'numbers'].contains(ext)) return _sheet;
  if (['ppt', 'pptx', 'odp', 'key'].contains(ext)) return _slides;
  if (['zip', 'rar', '7z', 'tar', 'gz', 'bz2'].contains(ext)) return _archive;
  if (mime.startsWith('text/') || ['txt', 'md', 'log'].contains(ext)) {
    return _text;
  }

  // An unrecognised extension still says more than "FILE" does.
  if (ext.isNotEmpty && ext.length <= 4) {
    return FileTypeDisplay(
      icon: _generic.icon,
      color: _generic.color,
      label: ext.toUpperCase(),
    );
  }
  return _generic;
}
