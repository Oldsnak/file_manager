// lib/features/file_browser/pages/in_app_pdf_viewer_page.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdfx/pdfx.dart';

import '../../../core/models/browser_item.dart';

class InAppPdfViewerPage extends StatefulWidget {
  const InAppPdfViewerPage({super.key, required this.item});

  final BrowserItem item;

  @override
  State<InAppPdfViewerPage> createState() => _InAppPdfViewerPageState();
}

class _InAppPdfViewerPageState extends State<InAppPdfViewerPage> {
  PdfControllerPinch? _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  void _loadPdf() {
    final path = widget.item.path;
    if (path.isEmpty) {
      setState(() => _error = 'File path is empty');
      return;
    }
    final file = File(path);
    if (!file.existsSync()) {
      setState(() => _error = 'File not found');
      return;
    }
    setState(() {
      _controller = PdfControllerPinch(
        document: PdfDocument.openFile(path),
      );
      _error = null;
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
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

    if (_controller == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.item.name, overflow: TextOverflow.ellipsis)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item.name, overflow: TextOverflow.ellipsis, maxLines: 1),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Get.back(),
        ),
      ),
      body: PdfViewPinch(
        controller: _controller!,
        scrollDirection: Axis.vertical,
      ),
    );
  }
}
