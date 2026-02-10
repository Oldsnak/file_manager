import 'package:audioplayers/audioplayers.dart';
import 'package:file_manager/foundation/constants/sizes.dart';
import 'package:flutter/material.dart';

import '../../../foundation/constants/assets.dart';
import '../pages/social_webview_page.dart';

class SocialApps extends StatelessWidget {
  const SocialApps({super.key});

  void _openWeb(BuildContext context, {required String platform, required String url}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SocialWebViewPage(
          platform: platform,
          initialUrl: url,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Center(
        child: Wrap(
          spacing: TSizes.sm,
          runSpacing: 20,
          alignment: WrapAlignment.center,
          children: [
            AnimatedSocialIcon(
              assetPath: facebook,
              onTap: () => _openWeb(
                context,
                platform: "facebook",
                url: "https://m.facebook.com/",
              ),
            ),
            AnimatedSocialIcon(
              assetPath: youtube,
              onTap: () => _openWeb(
                context,
                platform: "youtube",
                url: "https://m.youtube.com/",
              ),
            ),
            AnimatedSocialIcon(
              assetPath: instagram,
              onTap: () => _openWeb(
                context,
                platform: "instagram",
                url: "https://www.instagram.com/",
              ),
            ),
            AnimatedSocialIcon(
              assetPath: tiktok,
              onTap: () => _openWeb(
                context,
                platform: "tiktok",
                url: "https://www.tiktok.com/",
              ),
            ),
            AnimatedSocialIcon(
              assetPath: download,
              onTap: () {
                // Download icon: by default open a neutral page (you can change later)
                _openWeb(
                  context,
                  platform: "download",
                  url: "https://www.google.com/",
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

AudioPlayer? _globalPlayer;

AudioPlayer _getPlayer() {
  _globalPlayer ??= AudioPlayer();
  return _globalPlayer!;
}

class AnimatedSocialIcon extends StatefulWidget {
  final String assetPath;
  final VoidCallback onTap;

  const AnimatedSocialIcon({
    super.key,
    required this.assetPath,
    required this.onTap,
  });

  @override
  State<AnimatedSocialIcon> createState() => _AnimatedSocialIconState();
}

class _AnimatedSocialIconState extends State<AnimatedSocialIcon> {
  double _scale = 1.0;

  Future<void> _playSound() async {
    try {
      final player = _getPlayer();
      await player.stop();
      await player.setSource(AssetSource('sounds/tap_sound.wav'));
      await player.resume();
    } catch (e) {
      debugPrint("Sound Error: $e");
    }
  }

  void _onTapDown(TapDownDetails details) {
    _playSound();
    setState(() => _scale = 0.92);
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _scale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        child: Container(
          padding: const EdgeInsets.all(1.5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.8),
                Colors.white.withOpacity(0.1),
                Colors.blue.withOpacity(0.4),
              ],
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Image.asset(
              widget.assetPath,
              width: 40,
              height: 40,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
