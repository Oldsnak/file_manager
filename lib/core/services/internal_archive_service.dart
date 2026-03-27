import 'dart:io';

import 'package:archive/archive_io.dart';
/// Zip / tar / gzip helpers for on-device folders (internal storage browser).
class InternalArchiveService {
  InternalArchiveService._();

  static final _unsafeNameChars = RegExp(r'[\\/:*?"<>|]');

  /// Extensions supported by [extractFileToDisk] from package:archive.
  static bool looksLikeArchive(String fileName) {
    final n = fileName.toLowerCase();
    return n.endsWith('.zip') ||
        n.endsWith('.tar') ||
        n.endsWith('.tar.gz') ||
        n.endsWith('.tgz') ||
        n.endsWith('.tar.bz2') ||
        n.endsWith('.tbz') ||
        n.endsWith('.tar.xz') ||
        n.endsWith('.txz');
  }

  /// Ensures a single file segment name and required extension.
  static String sanitizeArchiveFileName(String raw, String extensionWithDot) {
    var s = raw.replaceAll(_unsafeNameChars, '_').trim();
    if (s.isEmpty) s = 'archive';
    final lower = s.toLowerCase();
    final ext = extensionWithDot.toLowerCase();
    if (!lower.endsWith(ext)) {
      s = '$s$extensionWithDot';
    }
    return s;
  }

  /// Zips [folderPath] recursively; archive entries include the folder’s basename as root.
  static Future<void> compressFolderToZip(String folderPath, String outputZipPath) async {
    final dir = Directory(folderPath);
    if (!await dir.exists()) {
      throw FileSystemException('Folder not found', folderPath);
    }
    final out = File(outputZipPath);
    await out.parent.create(recursive: true);
    final encoder = ZipFileEncoder();
    encoder.create(outputZipPath);
    await encoder.addDirectory(dir, includeDirName: true, followLinks: false);
    await encoder.close();
  }

  /// Creates a .tar.gz of [folderPath] at [outputPath] (should end with `.tar.gz`).
  static Future<void> compressFolderToTarGz(String folderPath, String outputPath) async {
    final dir = Directory(folderPath);
    if (!await dir.exists()) {
      throw FileSystemException('Folder not found', folderPath);
    }
    await File(outputPath).parent.create(recursive: true);
    final encoder = TarFileEncoder();
    await encoder.tarDirectory(
      dir,
      compression: TarFileEncoder.gzip,
      filename: outputPath,
      followLinks: false,
    );
  }

  /// Uncompressed .tar only.
  static Future<void> compressFolderToTar(String folderPath, String outputPath) async {
    final dir = Directory(folderPath);
    if (!await dir.exists()) {
      throw FileSystemException('Folder not found', folderPath);
    }
    await File(outputPath).parent.create(recursive: true);
    final encoder = TarFileEncoder();
    await encoder.tarDirectory(
      dir,
      compression: TarFileEncoder.store,
      filename: outputPath,
      followLinks: false,
    );
  }

  /// Extracts zip/tar/tar.gz/… into [outputDir] (created if missing). Uses archive’s zip-slip checks.
  static Future<void> extractArchiveTo(String archivePath, String outputDir) async {
    final f = File(archivePath);
    if (!await f.exists()) {
      throw FileSystemException('Archive not found', archivePath);
    }
    await Directory(outputDir).create(recursive: true);
    await extractFileToDisk(archivePath, outputDir);
  }
}
