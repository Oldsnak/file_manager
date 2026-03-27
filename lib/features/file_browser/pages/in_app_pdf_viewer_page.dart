// lib/features/file_browser/pages/in_app_pdf_viewer_page.dart

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../../core/models/browser_item.dart';
import '../services/pdf_speech_coordinator.dart';

class InAppPdfViewerPage extends StatefulWidget {
  const InAppPdfViewerPage({super.key, required this.item});

  final BrowserItem item;

  @override
  State<InAppPdfViewerPage> createState() => _InAppPdfViewerPageState();
}

class _InAppPdfViewerPageState extends State<InAppPdfViewerPage> {
  late final PdfViewerController _pdfController;
  String? _error;
  String? _selectedText;
  int _pageNumber = 1;
  int _pageCount = 0;
  bool _landscape = false;
  bool _playingTts = false;

  /// Same pattern as [InAppVideoPlayerPage]: tap toggles chrome; auto-hide after delay.
  bool _showOverlay = false;
  Timer? _hideOverlayTimer;
  static const Duration _overlayVisibleDuration = Duration(seconds: 5);

  /// Page rail only while scrolling / changing page (or zoom).
  bool _showPageRail = false;
  Timer? _hideRailTimer;
  static const Duration _railVisibleDuration = Duration(milliseconds: 1800);

  double _lastZoomLevel = 1.0;

  static const _highlightColors = <Color>[
    Color(0xFFE53935),
    Color(0xFF43A047),
    Color(0xFFFDD835),
  ];

  @override
  void initState() {
    super.initState();
    _pdfController = PdfViewerController();
    _pdfController.addListener(_onPdfControllerTick);
    _validateAndLoad();
  }

  void _validateAndLoad() {
    final path = widget.item.path;
    if (path.isEmpty) {
      setState(() => _error = 'File path is empty');
      return;
    }
    if (kIsWeb) {
      setState(() => _error = 'In-app PDF is not supported on web.');
      return;
    }
    final file = File(path);
    if (!file.existsSync()) {
      setState(() => _error = 'File not found');
      return;
    }
    setState(() => _error = null);
  }

  void _onPdfControllerTick() {
    if (!mounted) {
      return;
    }
    final n = _pdfController.pageNumber;
    final c = _pdfController.pageCount;
    final z = _pdfController.zoomLevel;
    final zoomChanged = (z - _lastZoomLevel).abs() > 0.002;
    if (zoomChanged) {
      _lastZoomLevel = z;
      _bumpScrollChrome();
    }
    if (n != _pageNumber || c != _pageCount) {
      setState(() {
        _pageNumber = n;
        _pageCount = c;
      });
    }
  }

  void _bumpScrollChrome() {
    if (_pageCount <= 0) return;
    setState(() => _showPageRail = true);
    _hideRailTimer?.cancel();
    _hideRailTimer = Timer(_railVisibleDuration, () {
      if (mounted) setState(() => _showPageRail = false);
    });
  }

  void _onChromeTap() {
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

  @override
  void dispose() {
    _hideOverlayTimer?.cancel();
    _hideRailTimer?.cancel();
    _pdfController.removeListener(_onPdfControllerTick);
    unawaited(PdfSpeechCoordinator.stop());
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  Future<void> _setOrientation(bool landscape) async {
    setState(() => _landscape = landscape);
    await SystemChrome.setPreferredOrientations(
      landscape
          ? const [
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ]
          : const [DeviceOrientation.portraitUp],
    );
  }

  Future<void> _requestNotifPermission() async {
    if (Platform.isAndroid) {
      final s = await Permission.notification.status;
      if (!s.isGranted) {
        await Permission.notification.request();
      }
    }
  }

  void _onTextSelectionChanged(PdfTextSelectionChangedDetails details) {
    final t = details.selectedText?.trim();
    setState(() => _selectedText = t?.isEmpty ?? true ? null : t);
  }

  void _copySelection() {
    final t = _selectedText;
    if (t == null || t.isEmpty) {
      return;
    }
    Clipboard.setData(ClipboardData(text: t));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  void _applyHighlightColor(Color color) {
    _pdfController.annotationSettings.highlight
      ..color = color
      ..opacity = 0.4;
    _pdfController.annotationMode = PdfAnnotationMode.highlight;
    setState(() {});
  }

  void _clearAnnotationTool() {
    _pdfController.annotationMode = PdfAnnotationMode.none;
    setState(() {});
  }

  Future<String> _buildTextToSpeak() async {
    final path = widget.item.path;
    final bytes = await File(path).readAsBytes();
    final doc = PdfDocument(inputBytes: bytes);
    try {
      final extractor = PdfTextExtractor(doc);
      final full = extractor.extractText();
      final sel = _selectedText?.trim();
      if (sel == null || sel.isEmpty) {
        return full;
      }
      final i = full.indexOf(sel);
      if (i >= 0) {
        return full.substring(i);
      }
      final pageIdx = (_pdfController.pageNumber >= 1 ? _pdfController.pageNumber : 1) - 1;
      final fromPage = extractor.extractText(startPageIndex: pageIdx);
      final j = fromPage.indexOf(sel);
      if (j >= 0) {
        return fromPage.substring(j);
      }
      return '$sel\n\n$fromPage';
    } finally {
      doc.dispose();
    }
  }

  Future<void> _togglePlay() async {
    if (_playingTts) {
      await PdfSpeechCoordinator.stop();
      if (mounted) {
        setState(() => _playingTts = false);
      }
      return;
    }
    await _requestNotifPermission();
    String text;
    try {
      text = await _buildTextToSpeak();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not read PDF text: $e')),
        );
      }
      return;
    }
    text = text.trim();
    if (text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No text found in this PDF.')),
        );
      }
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() => _playingTts = true);
    await PdfSpeechCoordinator.speakWithNotification(
      text: text,
      title: widget.item.name,
      onFinished: () {
        if (mounted) {
          setState(() => _playingTts = false);
        }
      },
    );
    if (mounted) {
      setState(() => _playingTts = false);
    }
  }

  /// AppBar content for the video-style overlay (not a [Scaffold.appBar]).
  PreferredSizeWidget _overlayAppBar() {
    final iconColor = Colors.white;
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      flexibleSpace: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.55),
              Colors.black.withValues(alpha: 0.08),
              Colors.transparent,
            ],
          ),
        ),
      ),
      title: Text(
        widget.item.name,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: TextStyle(color: iconColor, shadows: const [
          Shadow(blurRadius: 4, color: Colors.black45),
        ]),
      ),
      leading: IconButton(
        icon: Icon(Icons.close, color: iconColor),
        onPressed: () => Get.back(),
      ),
      actions: [
        IconButton(
          tooltip: _playingTts ? 'Stop reading' : 'Read aloud',
          icon: Icon(
            _playingTts ? Icons.stop_circle_outlined : Icons.play_circle_outline,
            color: iconColor,
          ),
          onPressed: _togglePlay,
        ),
        IconButton(
          tooltip: _landscape ? 'Portrait' : 'Landscape',
          icon: Icon(
            _landscape ? Icons.stay_current_portrait : Icons.stay_current_landscape,
            color: iconColor,
          ),
          onPressed: () => _setOrientation(!_landscape),
        ),
        IconButton(
          tooltip: 'Copy selection',
          icon: Icon(Icons.copy, color: iconColor),
          onPressed: (_selectedText?.isNotEmpty ?? false) ? _copySelection : null,
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.highlight, color: iconColor),
          tooltip: 'Highlight color',
          onSelected: (value) {
            if (value == 'none') {
              _clearAnnotationTool();
            } else {
              final i = int.tryParse(value);
              if (i != null && i >= 0 && i < _highlightColors.length) {
                _applyHighlightColor(_highlightColors[i]);
              }
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(value: '0', child: _menuColorRow(_highlightColors[0], 'Red highlight')),
            PopupMenuItem(value: '1', child: _menuColorRow(_highlightColors[1], 'Green highlight')),
            PopupMenuItem(value: '2', child: _menuColorRow(_highlightColors[2], 'Yellow highlight')),
            const PopupMenuDivider(),
            const PopupMenuItem(value: 'none', child: Text('Selection only (no highlight tool)')),
          ],
        ),
      ],
    );
  }

  static Widget _menuColorRow(Color c, String label) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: c,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black26),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.item.name, overflow: TextOverflow.ellipsis),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Get.back(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(_error!, textAlign: TextAlign.center),
          ),
        ),
      );
    }

    final file = File(widget.item.path);
    final topPad = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: ColoredBox(
              color: Theme.of(context).colorScheme.surface,
              child: NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification n) {
                  if (n is ScrollStartNotification ||
                      n is ScrollUpdateNotification ||
                      n is OverscrollNotification) {
                    _bumpScrollChrome();
                  }
                  return false;
                },
                child: SfPdfViewer.file(
                  file,
                  controller: _pdfController,
                  canShowScrollHead: true,
                  canShowScrollStatus: true,
                  enableTextSelection: true,
                  canShowTextSelectionMenu: true,
                  interactionMode: PdfInteractionMode.selection,
                  onTap: (_) => _onChromeTap(),
                  onTextSelectionChanged: _onTextSelectionChanged,
                  onDocumentLoaded: (PdfDocumentLoadedDetails _) {
                    setState(() {
                      _pageCount = _pdfController.pageCount;
                      _pageNumber = _pdfController.pageNumber;
                      _lastZoomLevel = _pdfController.zoomLevel;
                    });
                  },
                  onPageChanged: (PdfPageChangedDetails d) {
                    setState(() => _pageNumber = d.newPageNumber);
                    _bumpScrollChrome();
                  },
                ),
              ),
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
                child: Container(
                  color: Colors.black54,
                  child: Column(
                    children: [
                      _overlayAppBar(),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_pageCount > 0)
            Positioned(
              right: 4,
              top: topPad + (_showOverlay ? kToolbarHeight : 0) + 8,
              bottom: 24,
              child: AnimatedOpacity(
                opacity: _showPageRail ? 1 : 0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                child: IgnorePointer(
                  ignoring: !_showPageRail,
                  child: _PageRail(
                    pageNumber: _pageNumber,
                    pageCount: _pageCount,
                    onPageSelected: (p) {
                      _pdfController.jumpToPage(p);
                      _bumpScrollChrome();
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Vertical slider + current / total page labels on the side.
class _PageRail extends StatelessWidget {
  const _PageRail({
    required this.pageNumber,
    required this.pageCount,
    required this.onPageSelected,
  });

  final int pageNumber;
  final int pageCount;
  final ValueChanged<int> onPageSelected;

  @override
  Widget build(BuildContext context) {
    final maxIdx = (pageCount - 1).clamp(0, 99999).toDouble();
    final value = (pageNumber - 1).clamp(0, pageCount - 1).toDouble();

    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$pageNumber',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
                shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
              ),
            ),
            const Text(
              '—',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              '$pageCount',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: RotatedBox(
                quarterTurns: 3,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                  ),
                  child: Slider(
                    value: value,
                    min: 0,
                    max: maxIdx,
                    divisions: pageCount > 1 ? pageCount - 1 : null,
                    label: '$pageNumber / $pageCount',
                    onChanged: (v) {
                      onPageSelected(v.round() + 1);
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

