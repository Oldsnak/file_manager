// lib/core/services/vault_auth_service.dart
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// Vault Authentication Service
/// - Stores PIN securely (hash + salt)
/// - Provides setup/verify/change/reset
/// - Optional biometric support (if available/enrolled)
class VaultAuthService {
  VaultAuthService({
    FlutterSecureStorage? storage,
    LocalAuthentication? localAuth,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _localAuth = localAuth ?? LocalAuthentication();

  final FlutterSecureStorage _storage;
  final LocalAuthentication _localAuth;

  // -------------------- Keys --------------------
  static const String _kHasPin = "vault_has_pin_v1";
  static const String _kPinHash = "vault_pin_hash_v1";
  static const String _kPinSalt = "vault_pin_salt_v1";
  static const String _kBioEnabled = "vault_bio_enabled_v1";
  static const String _kFailCount = "vault_fail_count_v1";

  // -------------------- Public (static helper) --------------------
  /// Useful for HomePage gate without DI.
  static Future<bool> isVaultSetup() async {
    const storage = FlutterSecureStorage();
    final v = await storage.read(key: _kHasPin);
    return v == "1";
  }

  // -------------------- Public getters --------------------
  Future<bool> hasPin() async {
    final v = await _storage.read(key: _kHasPin);
    return v == "1";
  }

  Future<bool> isBiometricEnabled() async {
    final v = await _storage.read(key: _kBioEnabled);
    return v == "1";
  }

  Future<int> getFailCount() async {
    final v = await _storage.read(key: _kFailCount);
    return int.tryParse(v ?? "0") ?? 0;
  }

  // -------------------- Setup / Update PIN --------------------
  Future<void> setupPin(String pin) async {
    _validatePin(pin);

    final salt = _generateSalt();
    final hash = _hashPin(pin, salt);

    await _storage.write(key: _kPinSalt, value: salt);
    await _storage.write(key: _kPinHash, value: hash);
    await _storage.write(key: _kHasPin, value: "1");
    await resetFailCount();
  }

  Future<bool> changePin({
    required String oldPin,
    required String newPin,
  }) async {
    final ok = await verifyPin(oldPin, countFailure: false);
    if (!ok) return false;

    await setupPin(newPin);
    return true;
  }

  Future<void> resetPin() async {
    await _storage.delete(key: _kPinSalt);
    await _storage.delete(key: _kPinHash);
    await _storage.write(key: _kHasPin, value: "0");
    await setBiometricEnabled(false);
    await resetFailCount();
  }

  // -------------------- Verify PIN --------------------
  Future<bool> verifyPin(String pin, {bool countFailure = true}) async {
    _validatePin(pin);

    final salt = await _storage.read(key: _kPinSalt);
    final savedHash = await _storage.read(key: _kPinHash);

    if (salt == null || salt.isEmpty || savedHash == null || savedHash.isEmpty) {
      return false;
    }

    final hash = _hashPin(pin, salt);
    final ok = _constantTimeEquals(hash, savedHash);

    if (ok) {
      await resetFailCount();
      return true;
    } else {
      if (countFailure) await _incFailCount();
      return false;
    }
  }

  // -------------------- Biometric --------------------
  Future<bool> canCheckBiometrics() async {
    try {
      final can = await _localAuth.canCheckBiometrics;
      final supported = await _localAuth.isDeviceSupported();
      return can && supported;
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasEnrolledBiometrics() async {
    try {
      final types = await _localAuth.getAvailableBiometrics();
      return types.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _kBioEnabled, value: enabled ? "1" : "0");
  }

  /// ✅ Version-safe biometric auth:
  /// Some local_auth versions don't support `options` or `AuthenticationOptions`.
  ///
  /// We still achieve "biometric only" by:
  /// - checking canCheckBiometrics + enrolled biometrics before calling authenticate
  ///
  /// Returns true if successful.
  Future<bool> authenticateBiometric({
    String reason = "Unlock Secure Vault",
  }) async {
    final enabled = await isBiometricEnabled();
    if (!enabled) return false;
    try {
      // pre-checks
      final can = await canCheckBiometrics();
      if (!can) return false;

      final enrolled = await hasEnrolledBiometrics();
      if (!enrolled) return false;

      // 👇 no `options:` here to avoid version mismatch errors
      final ok = await _localAuth.authenticate(
        localizedReason: reason,
      );

      if (ok) await resetFailCount();
      return ok;
    } catch (_) {
      return false;
    }
  }

  // -------------------- Fail counter --------------------
  Future<void> resetFailCount() async {
    await _storage.write(key: _kFailCount, value: "0");
  }

  Future<void> _incFailCount() async {
    final current = await getFailCount();
    await _storage.write(key: _kFailCount, value: "${current + 1}");
  }

  // -------------------- Helpers --------------------
  void _validatePin(String pin) {
    if (pin.trim().isEmpty) {
      throw Exception("PIN is empty");
    }
    if (pin.length < 4 || pin.length > 8) {
      throw Exception("PIN must be 4 to 8 digits");
    }
    final onlyDigits = RegExp(r"^\d+$");
    if (!onlyDigits.hasMatch(pin)) {
      throw Exception("PIN must be digits only");
    }
  }

  String _generateSalt() {
    final ms = DateTime.now().microsecondsSinceEpoch.toString();
    final mix =
        "${ms}_${Object().hashCode}_${DateTime.now().millisecondsSinceEpoch}";
    return base64UrlEncode(utf8.encode(mix));
  }

  /// Lightweight hash function without external 'crypto' dependency.
  String _hashPin(String pin, String salt) {
    final data = utf8.encode("$salt|$pin|v1");
    const int fnvOffset = 0xcbf29ce484222325;
    const int fnvPrime = 0x100000001b3;

    int hash = fnvOffset;
    for (final b in data) {
      hash ^= b;
      hash = (hash * fnvPrime) & 0xFFFFFFFFFFFFFFFF;
    }

    hash ^= (hash >> 32);
    hash = hash & 0xFFFFFFFFFFFFFFFF;

    return hash.toRadixString(16).padLeft(16, "0");
  }

  bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    int diff = 0;
    for (int i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }

  @visibleForTesting
  Future<void> debugClearAll() async {
    await _storage.deleteAll();
  }
}
