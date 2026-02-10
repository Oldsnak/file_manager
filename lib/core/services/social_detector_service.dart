// file_manager/core/services/social_detector_service.dart

import 'package:flutter/foundation.dart';

/// Detects social platform from a URL and provides basic normalization.
/// This is *client-side convenience* (backend is still the source of truth).
///
/// Platforms supported:
/// - youtube
/// - instagram
/// - facebook
/// - tiktok
/// - unknown
@immutable
class SocialDetectorService {
  const SocialDetectorService();

  /// Normalize a pasted URL:
  /// - trims spaces
  /// - ensures scheme (https)
  /// - strips common tracking query params
  String normalizeUrl(String url) {
    var raw = url.trim();
    if (raw.isEmpty) return raw;

    if (!raw.startsWith('http://') && !raw.startsWith('https://')) {
      raw = 'https://$raw';
    }

    Uri? uri;
    try {
      uri = Uri.parse(raw);
    } catch (_) {
      return raw;
    }

    final cleanedHost = _stripWww(uri.host.toLowerCase());

    // Remove common tracking params
    const trackingKeys = {
      'utm_source',
      'utm_medium',
      'utm_campaign',
      'utm_term',
      'utm_content',
      'fbclid',
      'gclid',
      'igshid',
    };

    final newQuery = <String, String>{};
    uri.queryParameters.forEach((k, v) {
      if (!trackingKeys.contains(k.toLowerCase())) {
        newQuery[k] = v;
      }
    });

    final normalized = uri.replace(
      scheme: uri.scheme.isEmpty ? 'https' : uri.scheme,
      host: cleanedHost,
      queryParameters: newQuery.isEmpty ? null : newQuery,
      fragment: '',
    );

    return normalized.toString();
  }

  /// Returns one of:
  /// "youtube" | "instagram" | "facebook" | "tiktok" | "unknown"
  String detectPlatform(String url) {
    final host = _hostOf(url);
    if (host.isEmpty) return 'unknown';

    // YouTube
    if (host == 'youtube.com' || host == 'youtu.be' || host.endsWith('.youtube.com')) {
      return 'youtube';
    }

    // Instagram
    if (host == 'instagram.com' || host.endsWith('.instagram.com')) {
      return 'instagram';
    }

    // Facebook
    if (host == 'facebook.com' || host.endsWith('.facebook.com') || host == 'fb.watch') {
      return 'facebook';
    }

    // TikTok
    if (host == 'tiktok.com' || host.endsWith('.tiktok.com')) {
      return 'tiktok';
    }

    return 'unknown';
  }

  /// Quick allowlist check for domains.
  /// Works with exact domains and subdomains.
  bool isAllowedDomain(String url, List<String> allowedDomains) {
    final host = _hostOf(url);
    if (host.isEmpty) return false;

    final h = host.toLowerCase();
    final allowed = allowedDomains.map((e) => e.toLowerCase().trim()).where((e) => e.isNotEmpty).toList();

    for (final d in allowed) {
      if (h == d || h.endsWith('.$d')) return true;
    }
    return false;
  }

  String _hostOf(String url) {
    var raw = url.trim();
    if (raw.isEmpty) return '';

    if (!raw.startsWith('http://') && !raw.startsWith('https://')) {
      raw = 'https://$raw';
    }

    try {
      final uri = Uri.parse(raw);
      return _stripWww(uri.host.toLowerCase());
    } catch (_) {
      return '';
    }
  }

  String _stripWww(String host) {
    if (host.startsWith('www.')) return host.substring(4);
    return host;
  }
}
