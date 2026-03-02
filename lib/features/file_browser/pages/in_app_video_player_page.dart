// lib/features/file_browser/pages/in_app_video_player_page.dart

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:video_player/video_player.dart';

import '../../../core/models/browser_item.dart';
import '../../../core/services/background_audio_service.dart';
import '../../../foundation/constants/colors.dart';

class InAppVideoPlayerPage extends StatefulWidget {
  const InAppVideoPlayerPage({
    super.key,
    required this.initialItem,
    required this.playlist,
  });

  final BrowserItem initialItem;
  final List<BrowserItem> playlist;

  @override
  State<InAppVideoPlayerPage> createState() => _InAppVideoPlayerPageState();
}

class _InAppVideoPlayerPageState extends State<InAppVideoPlayerPage>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  int _currentIndex = 0;
  bool _loop = false;
  bool _playInBackground = false;
  bool _showOverlay = false;
  Timer? _hideOverlayTimer;
  static const Duration _overlayVisibleDuration = Duration(seconds: 5);
  static const Duration _seekStep = Duration(seconds: 10);
  double? _dragStartX;
  double _horizontalDragDelta = 0;
  double _verticalDragDelta = 0;
  Duration? _seekStartPosition;
  Offset? _pointerDownPosition;
  String? _dragType;
  static const double _tapSlop = 18;

  double _volumeLevel = 0.5;
  double _brightnessLevel = 0.5;
  double _displayVolume = 0.5;
  double _displayBrightness = 0.5;
  double _previousDisplayVolume = 0.5;
  double _previousDisplayBrightness = 0.5;
  bool _showVolumeIndicator = false;
  bool _showBrightnessIndicator = false;
  Timer? _volumeIndicatorTimer;
  Timer? _brightnessIndicatorTimer;
  static const Duration _indicatorHideDelay = Duration(milliseconds: 1500);

  List<BrowserItem> get _playlist => widget.playlist;
  BrowserItem get _currentItem =>
      _playlist.isNotEmpty && _currentIndex < _playlist.length
          ? _playlist[_currentIndex]
          : widget.initialItem;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentIndex = _playlist.indexWhere((e) => e.id == widget.initialItem.id);
    if (_currentIndex < 0) _currentIndex = 0;
    _loadVideo();
    _loadInitialVolumeAndBrightness();
  }

  Future<void> _loadInitialVolumeAndBrightness() async {
    try {
      await FlutterVolumeController.setAndroidAudioStream(stream: AudioStream.music);
      FlutterVolumeController.showSystemUI = false;
      final v = await FlutterVolumeController.getVolume(stream: AudioStream.music);
      if (v != null && mounted) setState(() => _volumeLevel = _displayVolume = v);
    } catch (_) {}
    try {
      final b = await ScreenBrightness.instance.current;
      if (mounted) setState(() => _brightnessLevel = _displayBrightness = b.clamp(0.0, 1.0));
    } catch (_) {}
  }

  @override
  void dispose() {
    _hideOverlayTimer?.cancel();
    _volumeIndicatorTimer?.cancel();
    _brightnessIndicatorTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (_playInBackground &&
          _playlist.isNotEmpty &&
          _currentIndex < _playlist.length) {
        final path = _playlist[_currentIndex].path;
        if (path.isNotEmpty) {
          _handOffToBackgroundAndPop();
        }
      }
    }
  }

  Future<void> _handOffToBackgroundAndPop() async {
    try {
      final position = _controller?.value.position ?? Duration.zero;
      await Get.find<BackgroundAudioService>().playInBackground(
        filePath: _playlist[_currentIndex].path,
        title: _playlist[_currentIndex].name,
        id: _playlist[_currentIndex].id,
        position: position,
        loop: _loop,
      );
      if (!mounted) return;
      SystemChrome.setPreferredOrientations(DeviceOrientation.values);
      Get.back();
    } catch (_) {}
  }

  Future<void> _loadVideo() async {
    final path = _currentItem.path;
    if (path.isEmpty) return;
    final file = File(path);
    if (!await file.exists()) return;
    _controller?.dispose();
    _controller = VideoPlayerController.file(file);
    await _controller!.initialize();
    if (mounted) {
      setState(() {});
      _controller!.setLooping(_loop);
      await _controller!.play();
    }
  }

  void _onTap() {
    if (_showOverlay) {
      _hideOverlay();
      return;
    }
    setState(() => _showOverlay = true);
    _hideOverlayTimer?.cancel();
    _hideOverlayTimer = Timer(_overlayVisibleDuration, () {
      if (mounted) setState(() => _showOverlay = false);
    });
  }

  void _hideOverlay() {
    _hideOverlayTimer?.cancel();
    if (mounted) setState(() => _showOverlay = false);
  }

  void _handleHorizontalDragStart() {
    _seekStartPosition = _controller?.value.position;
    _horizontalDragDelta = 0;
  }

  void _handleHorizontalDragUpdate(double deltaDx) {
    if (_controller == null) return;
    final dur = _controller!.value.duration;
    if (dur.inMilliseconds <= 0) return;
    final start = _seekStartPosition ?? _controller!.value.position;
    _horizontalDragDelta += deltaDx;
    const msPerPixel = 200;
    final deltaMs = (_horizontalDragDelta * msPerPixel).round();
    final newMs = (start.inMilliseconds + deltaMs).clamp(0, dur.inMilliseconds);
    _controller!.seekTo(Duration(milliseconds: newMs));
  }

  void _handleHorizontalDragEnd() {
    _seekStartPosition = null;
    _horizontalDragDelta = 0;
  }

  void _handleVerticalDragStart(double globalX) {
    _dragStartX = globalX;
    _verticalDragDelta = 0;
  }

  void _handleVerticalDragUpdate(double deltaDy, BuildContext context) {
    _verticalDragDelta += deltaDy;
    final screenWidth = MediaQuery.of(context).size.width;
    final isLeftHalf = (_dragStartX ?? 0) < screenWidth / 2;
    if (_verticalDragDelta.abs() > 15) {
      final delta = _verticalDragDelta > 0 ? -1.0 : 1.0;
      if (isLeftHalf) {
        _adjustBrightness(delta);
      } else {
        _adjustVolume(delta);
      }
      _verticalDragDelta = 0;
    }
  }

  void _handleVerticalDragEnd(double velocity, BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLeftHalf = (_dragStartX ?? 0) < screenWidth / 2;
    if (velocity.abs() > 50) {
      final delta = velocity < 0 ? 1.0 : -1.0;
      if (isLeftHalf) {
        _adjustBrightness(delta);
      } else {
        _adjustVolume(delta);
      }
    }
    _dragStartX = null;
  }

  Future<void> _closeWithBackgroundCheck() async {
    if (_playInBackground &&
        _playlist.isNotEmpty &&
        _currentIndex < _playlist.length) {
      final path = _playlist[_currentIndex].path;
      if (path.isNotEmpty) {
        try {
          final position = _controller?.value.position ?? Duration.zero;
          await Get.find<BackgroundAudioService>().playInBackground(
            filePath: path,
            title: _playlist[_currentIndex].name,
            id: _playlist[_currentIndex].id,
            position: position,
            loop: _loop,
          );
        } catch (_) {}
      }
    } else {
      _controller?.pause();
    }
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    Get.back();
  }

  void _toggleOrientation() {
    if (MediaQuery.of(context).orientation == Orientation.portrait) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }
  }

  void _previous() {
    if (_playlist.isEmpty) return;
    _currentIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
    _loadVideo();
  }

  void _next() {
    if (_playlist.isEmpty) return;
    _currentIndex = (_currentIndex + 1) % _playlist.length;
    _loadVideo();
  }

  Future<void> _adjustVolume(double delta) async {
    try {
      await FlutterVolumeController.setAndroidAudioStream(stream: AudioStream.music);
      FlutterVolumeController.showSystemUI = false;
      // Use our stored value so we don't get stuck when getVolume() returns stale data after setVolume()
      final current = _volumeLevel;
      const step = 0.04;
      final next = (current + (delta * step)).clamp(0.0, 1.0);
      await FlutterVolumeController.setVolume(next, stream: AudioStream.music);
      if (mounted) {
        final prev = _displayVolume;
        setState(() {
          _volumeLevel = next;
          _previousDisplayVolume = prev;
          _displayVolume = next;
          _showVolumeIndicator = true;
        });
        _volumeIndicatorTimer?.cancel();
        _volumeIndicatorTimer = Timer(_indicatorHideDelay, () {
          if (mounted) setState(() => _showVolumeIndicator = false);
        });
      }
    } catch (e) {
      debugPrint('Volume adjust error: $e');
    }
  }

  Future<void> _adjustBrightness(double delta) async {
    try {
      final screen = ScreenBrightness.instance;
      final current = await screen.current;
      const step = 0.04;
      final next = (current + (delta * step)).clamp(0.0, 1.0);
      await screen.setApplicationScreenBrightness(next);
      if (mounted) {
        final prev = _displayBrightness;
        setState(() {
          _brightnessLevel = next;
          _previousDisplayBrightness = prev;
          _displayBrightness = next;
          _showBrightnessIndicator = true;
        });
        _brightnessIndicatorTimer?.cancel();
        _brightnessIndicatorTimer = Timer(_indicatorHideDelay, () {
          if (mounted) setState(() => _showBrightnessIndicator = false);
        });
      }
    } catch (e) {
      debugPrint('Brightness adjust error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: const Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) await _closeWithBackgroundCheck();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: VideoPlayer(_controller!),
            ),
          ),
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (event) {
                _pointerDownPosition = event.position;
                _dragType = null;
              },
              onPointerMove: (event) {
                final down = _pointerDownPosition;
                if (down == null) return;
                final delta = event.position - down;
                if (_dragType == null) {
                  if (delta.distance > _tapSlop) {
                    _dragType = delta.dx.abs() >= delta.dy.abs() ? 'h' : 'v';
                    if (_dragType == 'h') {
                      _handleHorizontalDragStart();
                      _handleHorizontalDragUpdate(delta.dx);
                    } else {
                      _handleVerticalDragStart(event.position.dx);
                      _handleVerticalDragUpdate(delta.dy, context);
                    }
                  }
                } else {
                  if (_dragType == 'h') {
                    _handleHorizontalDragUpdate(event.delta.dx);
                  } else if (_dragType == 'v') {
                    _handleVerticalDragUpdate(event.delta.dy, context);
                  }
                }
              },
              onPointerUp: (event) {
                final down = _pointerDownPosition;
                _pointerDownPosition = null;
                if (down == null) return;
                if (_dragType == 'h') {
                  _handleHorizontalDragEnd();
                } else if (_dragType == 'v') {
                  _handleVerticalDragEnd(0, context);
                } else {
                  final delta = event.position - down;
                  if (delta.distance <= _tapSlop) _onTap();
                }
                _dragType = null;
              },
              onPointerCancel: (_) {
                if (_dragType == 'h') _handleHorizontalDragEnd();
                else if (_dragType == 'v') _handleVerticalDragEnd(0, context);
                _pointerDownPosition = null;
                _dragType = null;
              },
              child: const SizedBox.shrink(),
            ),
          ),
          AnimatedOpacity(
            opacity: _showOverlay ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            child: IgnorePointer(
              ignoring: !_showOverlay,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _hideOverlay,
                onHorizontalDragStart: (_) => _handleHorizontalDragStart(),
                onHorizontalDragUpdate: (d) => _handleHorizontalDragUpdate(d.delta.dx),
                onHorizontalDragEnd: (_) => _handleHorizontalDragEnd(),
                onVerticalDragStart: (d) => _handleVerticalDragStart(d.globalPosition.dx),
                onVerticalDragUpdate: (d) {
                  if (d.primaryDelta != null) {
                    _handleVerticalDragUpdate(d.primaryDelta!, context);
                  }
                },
                onVerticalDragEnd: (d) => _handleVerticalDragEnd(d.primaryVelocity ?? 0, context),
                child: Container(
                  color: Colors.black54,
                  child: Column(
                    children: [
                    AppBar(
                      backgroundColor: Colors.transparent,
                      leading: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: _closeWithBackgroundCheck,
                      ),
                      title: Text(
                        _currentItem.name,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.screen_rotation, color: Colors.white),
                          onPressed: _toggleOrientation,
                        ),
                      ],
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          VideoProgressIndicator(_controller!, allowScrubbing: true),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: Icon(
                                  _loop ? Icons.repeat_one : Icons.repeat,
                                  color: _loop ? TColors.primary : Colors.white70,
                                  size: 28,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _loop = !_loop;
                                    _controller?.setLooping(_loop);
                                  });
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.skip_previous, color: Colors.white),
                                onPressed: _playlist.length > 1 ? _previous : null,
                              ),
                              IconButton(
                                icon: Icon(
                                  _controller!.value.isPlaying
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                  color: Colors.white,
                                  size: 40,
                                ),
                                onPressed: () {
                                  if (_controller!.value.isPlaying) {
                                    _controller!.pause();
                                  } else {
                                    _controller!.play();
                                  }
                                  setState(() {});
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.skip_next, color: Colors.white),
                                onPressed: _playlist.length > 1 ? _next : null,
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.airplay,
                                  color: _playInBackground ? TColors.primary : Colors.white70,
                                  size: 28,
                                ),
                                onPressed: () => setState(() => _playInBackground = !_playInBackground),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_showBrightnessIndicator) _buildBrightnessIndicator(),
          if (_showVolumeIndicator) _buildVolumeIndicator(),
        ],
      ),
    ),
    );
  }

  Widget _buildBrightnessIndicator() {
    return Positioned(
      left: 24,
      top: 0,
      bottom: 0,
      child: Center(
        child: Material(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.brightness_6, color: Colors.amber.shade300, size: 36),
                const SizedBox(height: 8),
                Text(
                  'Brightness',
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
                ),
                const SizedBox(height: 8),
                TweenAnimationBuilder<double>(
                  key: ValueKey('brightness_$_displayBrightness'),
                  tween: Tween(begin: _previousDisplayBrightness, end: _displayBrightness),
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  builder: (_, value, __) => SizedBox(
                    width: 120,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        LinearProgressIndicator(
                          value: value,
                          backgroundColor: Colors.white24,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.amber.shade300),
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(value * 100).round()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVolumeIndicator() {
    return Positioned(
      right: 24,
      top: 0,
      bottom: 0,
      child: Center(
        child: Material(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.volume_up, color: Colors.blue.shade300, size: 36),
                const SizedBox(height: 8),
                Text(
                  'Volume',
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
                ),
                const SizedBox(height: 8),
                TweenAnimationBuilder<double>(
                  key: ValueKey('volume_$_displayVolume'),
                  tween: Tween(begin: _previousDisplayVolume, end: _displayVolume),
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  builder: (_, value, __) => SizedBox(
                    width: 120,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        LinearProgressIndicator(
                          value: value,
                          backgroundColor: Colors.white24,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade300),
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(value * 100).round()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class VideoProgressIndicator extends StatefulWidget {
  const VideoProgressIndicator(this.controller, {super.key, this.allowScrubbing = true});

  final VideoPlayerController controller;
  final bool allowScrubbing;

  @override
  State<VideoProgressIndicator> createState() => _VideoProgressIndicatorState();
}

class _VideoProgressIndicatorState extends State<VideoProgressIndicator> {
  void _listener() => setState(() {});

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_listener);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final duration = widget.controller.value.duration;
    final position = widget.controller.value.position;
    if (duration.inMilliseconds <= 0) return const SizedBox.shrink();
    return Row(
      children: [
        Text(
          _formatDuration(position),
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: TColors.primary,
              inactiveTrackColor: Colors.white24,
              thumbColor: TColors.primary,
            ),
            child: Slider(
              value: position.inMilliseconds.toDouble(),
              max: duration.inMilliseconds.toDouble(),
              onChanged: widget.allowScrubbing
                  ? (v) => widget.controller.seekTo(Duration(milliseconds: v.toInt()))
                  : null,
            ),
          ),
        ),
        Text(
          _formatDuration(duration),
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${d.inHours > 0 ? '${d.inHours}:' : ''}$m:$s';
  }
}
