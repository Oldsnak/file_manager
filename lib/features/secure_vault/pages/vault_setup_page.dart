// lib/features/secure_vault/pages/vault_setup_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../foundation/constants/colors.dart';
import '../../../foundation/constants/sizes.dart';
import '../../../foundation/helpers/helper_functions.dart';

import '../pages/vault_home_page.dart';

class VaultSetupPage extends StatefulWidget {
  const VaultSetupPage({super.key});

  @override
  State<VaultSetupPage> createState() => _VaultSetupPageState();
}

class _VaultSetupPageState extends State<VaultSetupPage> {
  final _pin = TextEditingController();
  final _pin2 = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _saving = false;

  @override
  void dispose() {
    _pin.dispose();
    _pin2.dispose();
    super.dispose();
  }

  String? _validatePin(String? v) {
    final s = (v ?? "").trim();
    if (s.isEmpty) return "PIN required";
    if (s.length < 4) return "Minimum 4 digits";
    if (!RegExp(r"^\d+$").hasMatch(s)) return "Digits only";
    return null;
  }

  String? _validateConfirm(String? v) {
    final s = (v ?? "").trim();
    if (s != _pin.text.trim()) return "PIN does not match";
    return _validatePin(v);
  }

  Future<void> _saveAndContinue() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);

    // NOTE:
    // Abhi yahan actual secure PIN store nahi kiya (next step me hum VaultAuthService banayenge
    // jo flutter_secure_storage / local_auth se securely store karega).
    await Future.delayed(const Duration(milliseconds: 400));

    setState(() => _saving = false);

    // Go to home (replace)
    Get.off(() => const VaultHomePage());
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    final bgGradient = dark
        ? const RadialGradient(
      colors: [
        TColors.darkGradientBackgroundStart,
        TColors.darkGradientBackgroundEnd
      ],
      radius: 1.0,
    )
        : const RadialGradient(
      colors: [
        TColors.lightGradientBackgroundStart,
        TColors.lightGradientBackgroundEnd
      ],
      radius: 1.0,
    );

    final cardBg = dark ? TColors.darkContainer : TColors.lightContainer;
    final border = dark ? TColors.darkerGrey : TColors.grey;
    final titleColor = dark ? TColors.textWhite : TColors.textPrimary;
    final subColor = dark ? TColors.darkGrey : TColors.textSecondary;

    return Container(
      decoration: BoxDecoration(gradient: bgGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            "Secure Vault Setup",
            style: TextStyle(color: titleColor),
          ),
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          iconTheme: IconThemeData(color: titleColor),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Create your Vault PIN",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: titleColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "This PIN will be required to open your Secure Vault.",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: subColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: TSizes.spaceBtwSections),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(TSizes.lg),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(TSizes.cardRdiusLg),
                  border: Border.all(color: border),
                  boxShadow: [
                    BoxShadow(
                      color: TColors.primary.withOpacity(dark ? 0.18 : 0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _pin,
                        keyboardType: TextInputType.number,
                        obscureText: _obscure1,
                        maxLength: 8,
                        decoration: InputDecoration(
                          labelText: "New PIN",
                          hintText: "Enter 4-8 digits",
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => _obscure1 = !_obscure1),
                            icon: Icon(_obscure1 ? Icons.visibility : Icons.visibility_off),
                          ),
                          counterText: "",
                        ),
                        validator: _validatePin,
                      ),
                      const SizedBox(height: TSizes.spaceBtwInputFields),
                      TextFormField(
                        controller: _pin2,
                        keyboardType: TextInputType.number,
                        obscureText: _obscure2,
                        maxLength: 8,
                        decoration: InputDecoration(
                          labelText: "Confirm PIN",
                          hintText: "Re-enter PIN",
                          prefixIcon: const Icon(Icons.verified_user_outlined),
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => _obscure2 = !_obscure2),
                            icon: Icon(_obscure2 ? Icons.visibility : Icons.visibility_off),
                          ),
                          counterText: "",
                        ),
                        validator: _validateConfirm,
                      ),
                      const SizedBox(height: TSizes.spaceBtwSections),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _saving ? null : _saveAndContinue,
                          icon: AnimatedRotation(
                            turns: _saving ? 1 : 0,
                            duration: const Duration(milliseconds: 800),
                            child: const Icon(Icons.security),
                          ),
                          label: Text(_saving ? "Saving..." : "Continue"),
                        ),
                      ),
                      const SizedBox(height: TSizes.sm),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _saving ? null : () => Get.back(),
                          child: const Text("Not now"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: TSizes.spaceBtwItems),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(TSizes.md),
                decoration: BoxDecoration(
                  color: dark
                      ? TColors.darkOptionalContainer
                      : TColors.lightOptionalContainer,
                  borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
                  border: Border.all(color: TColors.optional.withOpacity(0.35)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: TColors.optional),
                    const SizedBox(width: TSizes.sm),
                    Expanded(
                      child: Text(
                        "Tip: Use a PIN you can remember. In the next step we can also enable fingerprint/face unlock.",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: titleColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
