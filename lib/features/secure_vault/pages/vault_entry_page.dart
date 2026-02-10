// lib/features/secure_vault/pages/vault_entry_page.dart
import 'package:file_manager/features/secure_vault/pages/vault_home_page.dart';
import 'package:file_manager/foundation/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/vault_auth_service.dart';

/// Entry (Lock) screen for Secure Vault:
/// - If PIN not set => Setup PIN (and optional biometrics toggle)
/// - If PIN set => Unlock with PIN or biometrics (if enabled)
///
/// Navigation:
/// After successful unlock, it navigates to route: "/secure-vault"
/// Make sure you register this route in GetMaterialApp.
class VaultEntryPage extends StatefulWidget {
  const VaultEntryPage({super.key});

  static const String routeName = "/vault-entry";

  @override
  State<VaultEntryPage> createState() => _VaultEntryPageState();
}

class _VaultEntryPageState extends State<VaultEntryPage> {
  late final VaultAuthService _auth;

  final _pinCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _hasPin = false;
  bool _bioPossible = false;
  bool _bioEnabled = false;

  bool _isLoading = true;
  bool _obscure = true;

  String? _error;

  @override
  void initState() {
    super.initState();

    // Use DI if registered, else fallback to direct instance.
    _auth = _findOrCreateAuthService();

    _bootstrap();
  }

  VaultAuthService _findOrCreateAuthService() {
    try {
      return Get.find<VaultAuthService>();
    } catch (_) {
      // If you prefer, register it in DependencyInjection instead.
      final svc = VaultAuthService();
      Get.put<VaultAuthService>(svc, permanent: true);
      return svc;
    }
  }

  Future<void> _bootstrap() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final hasPin = await _auth.hasPin();
      final canBio = await _auth.canCheckBiometrics();
      final enrolled = canBio ? await _auth.hasEnrolledBiometrics() : false;
      final bioEnabled = await _auth.isBiometricEnabled();

      setState(() {
        _hasPin = hasPin;
        _bioPossible = canBio && enrolled;
        _bioEnabled = bioEnabled && (canBio && enrolled);
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
        _error = "Something went wrong while preparing Vault.";
      });
    }
  }

  @override
  void dispose() {
    _pinCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _setError(String? msg) {
    setState(() => _error = msg);
  }

  Future<void> _setupPin() async {
    FocusScope.of(context).unfocus();
    _setError(null);

    final pin = _pinCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (pin.isEmpty || confirm.isEmpty) {
      _setError("Please enter PIN and confirm it.");
      return;
    }
    if (pin != confirm) {
      _setError("PIN and Confirm PIN do not match.");
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _auth.setupPin(pin);

      // Keep biometric preference (if possible). If not possible, force off.
      if (!_bioPossible) {
        await _auth.setBiometricEnabled(false);
      } else {
        await _auth.setBiometricEnabled(_bioEnabled);
      }

      setState(() {
        _hasPin = true;
        _isLoading = false;
        _pinCtrl.clear();
        _confirmCtrl.clear();
      });

      // After setup, move to unlock (or directly open vault if you want)
      Get.snackbar("Vault", "PIN created successfully",
          snackPosition: SnackPosition.BOTTOM);
      _goToVaultHome();
    } catch (e) {
      setState(() => _isLoading = false);
      _setError(e.toString().replaceFirst("Exception: ", ""));
    }
  }

  Future<void> _unlockWithPin() async {
    FocusScope.of(context).unfocus();
    _setError(null);

    final pin = _pinCtrl.text.trim();
    if (pin.isEmpty) {
      _setError("Please enter your PIN.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final ok = await _auth.verifyPin(pin);
      setState(() => _isLoading = false);

      if (!ok) {
        final fails = await _auth.getFailCount();
        _setError("Wrong PIN. Attempts: $fails");
        return;
      }

      _pinCtrl.clear();
      _goToVaultHome();
    } catch (e) {
      setState(() => _isLoading = false);
      _setError(e.toString().replaceFirst("Exception: ", ""));
    }
  }

  Future<void> _unlockWithBiometric() async {
    FocusScope.of(context).unfocus();
    _setError(null);

    if (!_bioPossible || !_bioEnabled) {
      _setError("Biometric is not enabled on this device.");
      return;
    }

    setState(() => _isLoading = true);
    try {
      final ok = await _auth.authenticateBiometric(
        reason: "Unlock Secure Vault",
      );
      setState(() => _isLoading = false);

      if (!ok) {
        _setError("Biometric authentication failed.");
        return;
      }

      _goToVaultHome();
    } catch (_) {
      setState(() => _isLoading = false);
      _setError("Biometric authentication failed.");
    }
  }

  void _goToVaultHome() {
    // IndexedStack ke andar ho → direct navigate
    Get.offAll(
          () => const VaultHomePage(),
      transition: Transition.fadeIn,
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(_hasPin ? "Unlock Vault" : "Setup Vault", style: TextStyle(color: TColors.primary),),
        backgroundColor: Colors.transparent,
        // centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
              children: [
                _HeaderCard(
                  title: _hasPin ? "Secure Vault" : "Create Vault PIN",
                  subtitle: _hasPin
                      ? "Enter your PIN to access Secure Vault."
                      : "Set a PIN to protect your Secure Vault.",
                  icon: Icons.lock_rounded,
                ),
                const SizedBox(height: 16),
            
                if (_error != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      _error!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
            
                _PinField(
                  controller: _pinCtrl,
                  label: _hasPin ? "PIN" : "Create PIN",
                  obscure: _obscure,
                  onToggleObscure: () => setState(() => _obscure = !_obscure),
                ),
            
                if (!_hasPin) ...[
                  const SizedBox(height: 12),
                  _PinField(
                    controller: _confirmCtrl,
                    label: "Confirm PIN",
                    obscure: _obscure,
                    onToggleObscure: () =>
                        setState(() => _obscure = !_obscure),
                  ),
                ],
            
                const SizedBox(height: 14),
            
                if (_bioPossible) _biometricToggle(theme),

                const SizedBox(height: 24),

                if (_hasPin) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _unlockWithPin,
                      child: const Text("Unlock"),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_bioPossible && _bioEnabled)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _unlockWithBiometric,
                        icon: const Icon(Icons.fingerprint),
                        label: const Text("Use Biometrics"),
                      ),
                    ),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _setupPin,
                      child: const Text("Create PIN"),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _biometricToggle(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.fingerprint),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Enable biometrics",
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Switch(
            value: _bioEnabled,
            activeColor: TColors.primary,                // ON thumb color
            activeTrackColor: TColors.primary.withOpacity(0.4), // ON track color
            // inactiveThumbColor: Colors.grey.shade400,
            // inactiveTrackColor: Colors.grey.shade300,
            onChanged: (v) async {
              setState(() => _bioEnabled = v);
              await _auth.setBiometricEnabled(v);
            },
          ),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TColors.primary.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            height: 54,
            width: 54,
            decoration: BoxDecoration(
              color: TColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 28, color: TColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PinField extends StatelessWidget {
  const _PinField({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.onToggleObscure,
  });

  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback onToggleObscure;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      maxLength: 8,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        counterText: "",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        prefixIcon: const Icon(Icons.password_rounded),
        suffixIcon: IconButton(
          onPressed: onToggleObscure,
          icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
        ),
      ),
    );
  }
}
