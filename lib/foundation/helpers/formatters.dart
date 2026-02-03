// lib/foundation/helpers/formatters.dart

class TFormatters {
  TFormatters._();

  static String bytesToReadable(int bytes, {int decimals = 1}) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    double size = bytes.toDouble();
    int i = 0;
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return "${size.toStringAsFixed(decimals)} ${suffixes[i]}";
  }

  static String bytesToGB(int bytes, {int decimals = 1}) {
    final gb = bytes / (1024 * 1024 * 1024);
    return "${gb.toStringAsFixed(decimals)} GB";
  }
}
