// lib/features/downloader/pages/social_webview_page.dart

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SocialWebViewPage extends StatefulWidget {
  final String platform; // "facebook" | "youtube" | "instagram" | "tiktok" | etc.
  final String initialUrl;

  const SocialWebViewPage({
    super.key,
    required this.platform,
    required this.initialUrl,
  });

  @override
  State<SocialWebViewPage> createState() => _SocialWebViewPageState();
}

class _SocialWebViewPageState extends State<SocialWebViewPage> {
  late final WebViewController _controller;

  int _progress = 0;
  bool _canGoBack = false;
  bool _canGoForward = false;
  String _currentUrl = "";

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) {
            if (!mounted) return;
            setState(() => _progress = p);
          },
          onPageStarted: (url) {
            if (!mounted) return;
            setState(() => _currentUrl = url);
          },
          onPageFinished: (url) async {
            _currentUrl = url;

            final back = await _controller.canGoBack();
            final forward = await _controller.canGoForward();

            if (!mounted) return;
            setState(() {
              _canGoBack = back;
              _canGoForward = forward;
            });
          },
          onWebResourceError: (error) {
            debugPrint("WebView error: ${error.description}");
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.initialUrl));
  }

  String _titleFromPlatform(String p) {
    final x = p.trim().toLowerCase();
    if (x.isEmpty) return "Browser";
    return "${x[0].toUpperCase()}${x.substring(1)}";
  }

  Future<void> _refresh() async {
    try {
      await _controller.reload();
    } catch (_) {}
  }

  Future<void> _updateNavState() async {
    try {
      final back = await _controller.canGoBack();
      final forward = await _controller.canGoForward();
      if (!mounted) return;
      setState(() {
        _canGoBack = back;
        _canGoForward = forward;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final title = _titleFromPlatform(widget.platform);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: "Refresh",
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_progress < 100)
            LinearProgressIndicator(
              value: _progress / 100.0,
              minHeight: 2,
            ),
          Expanded(
            child: WebViewWidget(controller: _controller),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  IconButton(
                    tooltip: "Back",
                    onPressed: _canGoBack
                        ? () async {
                      await _controller.goBack();
                      await _updateNavState();
                    }
                        : null,
                    icon: const Icon(Icons.arrow_back_ios_new),
                  ),
                  IconButton(
                    tooltip: "Forward",
                    onPressed: _canGoForward
                        ? () async {
                      await _controller.goForward();
                      await _updateNavState();
                    }
                        : null,
                    icon: const Icon(Icons.arrow_forward_ios),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _currentUrl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
