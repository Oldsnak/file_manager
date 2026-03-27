import 'package:audioplayers/audioplayers.dart';
import 'package:file_manager/core/services/download_jobs_registry.dart';
import 'package:file_manager/foundation/constants/sizes.dart';
import 'package:flutter/material.dart';

import '../../../foundation/constants/assets.dart';
import '../pages/downloads_library_page.dart';
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
            ListenableBuilder(
              listenable: DownloadJobsRegistry.instance,
              builder: (context, _) {
                final showDot = DownloadJobsRegistry.instance.showActiveIndicator;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedSocialIcon(
                      assetPath: download,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const DownloadsLibraryPage(),
                          ),
                        );
                      },
                    ),
                    if (showDot)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: 11,
                          height: 11,
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
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
