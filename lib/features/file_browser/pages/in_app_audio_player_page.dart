// lib/features/file_browser/pages/in_app_audio_player_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../../../core/models/browser_item.dart';
import '../../../foundation/constants/colors.dart';

class InAppAudioPlayerPage extends StatefulWidget {
  const InAppAudioPlayerPage({
    super.key,
    required this.initialItem,
    required this.playlist,
  });

  final BrowserItem initialItem;
  final List<BrowserItem> playlist;

  @override
  State<InAppAudioPlayerPage> createState() => _InAppAudioPlayerPageState();
}

class _InAppAudioPlayerPageState extends State<InAppAudioPlayerPage> {
  late AudioPlayer _player;
  bool _loop = false;
  bool _playInBackground = true;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _loadPlaylist();
    _player.playerStateStream.listen((state) => setState(() {}));
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _loadPlaylist() async {
    if (widget.playlist.isEmpty) return;
    final sources = widget.playlist.map((item) {
      return AudioSource.uri(
        Uri.file(item.path),
        tag: MediaItem(
          id: item.id,
          title: item.name,
          album: 'File Manager',
        ),
      );
    }).toList();
    await _player.setAudioSource(ConcatenatingAudioSource(children: sources));
    final idx = widget.playlist.indexWhere((e) => e.id == widget.initialItem.id);
    if (idx >= 0) await _player.seek(Duration.zero, index: idx);
    await _player.play();
  }

  void _previous() => _player.seekToPrevious();
  void _next() => _player.seekToNext();
  void _toggleLoop() {
    setState(() {
      _loop = !_loop;
      _player.setLoopMode(_loop ? LoopMode.one : LoopMode.off);
    });
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${d.inHours > 0 ? '${d.inHours}:' : ''}$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialItem.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        backgroundColor: TColors.primary.withValues(alpha: 0.12),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              StreamBuilder<SequenceState?>(
                stream: _player.sequenceStateStream,
                builder: (context, snapshot) {
                  final state = snapshot.data;
                  final item = state?.currentSource?.tag as MediaItem?;
                  return Text(
                    item?.title ?? widget.initialItem.name,
                    style: theme.textTheme.titleLarge,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  );
                },
              ),
              const SizedBox(height: 32),
              StreamBuilder<Duration>(
                stream: _player.positionStream,
                builder: (context, posSnapshot) {
                  return StreamBuilder<Duration?>(
                    stream: _player.durationStream,
                    builder: (context, durSnapshot) {
                      final pos = posSnapshot.data ?? Duration.zero;
                      final dur = durSnapshot.data ?? Duration.zero;
                      return Column(
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: TColors.primary,
                              thumbColor: TColors.primary,
                            ),
                            child: Slider(
                              value: pos.inMilliseconds.toDouble(),
                              max: dur.inMilliseconds > 0 ? dur.inMilliseconds.toDouble() : 1,
                              onChanged: (v) => _player.seek(Duration(milliseconds: v.toInt())),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_formatDuration(pos), style: theme.textTheme.bodySmall),
                              Text(_formatDuration(dur), style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.skip_previous, size: 40),
                    onPressed: _player.hasPrevious ? _previous : null,
                    color: TColors.primary,
                  ),
                  StreamBuilder<PlayerState>(
                    stream: _player.playerStateStream,
                    builder: (context, snapshot) {
                      final state = snapshot.data;
                      final playing = state?.playing ?? false;
                      return IconButton(
                        icon: Icon(playing ? Icons.pause : Icons.play_arrow, size: 56),
                        onPressed: () => playing ? _player.pause() : _player.play(),
                        color: TColors.primary,
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next, size: 40),
                    onPressed: _player.hasNext ? _next : null,
                    color: TColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Loop', style: theme.textTheme.bodyMedium),
                  Switch(value: _loop, onChanged: (_) => _toggleLoop(), activeTrackColor: TColors.primary),
                  const SizedBox(width: 24),
                  Text('Play in background', style: theme.textTheme.bodyMedium),
                  Switch(value: _playInBackground, onChanged: (v) => setState(() => _playInBackground = v), activeTrackColor: TColors.primary),
                ],
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
