// ===========================================================================
// lib/widgets/html_iframe.dart
// ---------------------------------------------------------------------------
// Renders a full HTML string inside a real browser <iframe>. This is what the
// Lesson tab uses so the AI's CSS animations and JavaScript actually RUN
// (unlike flutter_widget_from_html, which only shows static HTML).
//
// The iframe is sandboxed with "allow-scripts" only: scripts can run, but the
// page is treated as a separate origin and can't touch the parent app, cookies,
// or storage. That keeps AI-generated HTML safe.
//
// WEB ONLY: this file uses dart:html and dart:ui_web, which exist only on
// Flutter Web. The app is web-only, so that's fine.
// ===========================================================================

import 'dart:html' as web;
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';

class HtmlIframe extends StatefulWidget {
  // The HTML to show. Can be a full document or a fragment.
  final String html;
  const HtmlIframe({super.key, required this.html});

  @override
  State<HtmlIframe> createState() => _HtmlIframeState();
}

class _HtmlIframeState extends State<HtmlIframe> {
  // A unique id for this iframe so multiple lessons don't clash.
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType =
        'lesson-iframe-${DateTime.now().microsecondsSinceEpoch}-${widget.html.hashCode}';

    // Build the iframe and load the HTML into it via srcdoc.
    final iframe = web.IFrameElement()
      ..srcdoc = widget.html
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..setAttribute('sandbox', 'allow-scripts');

    // Register it so Flutter can place it on screen.
    ui_web.platformViewRegistry
        .registerViewFactory(_viewType, (int viewId) => iframe);
  }

  @override
  Widget build(BuildContext context) {
    // Fills whatever space the parent gives it; the page scrolls inside.
    return HtmlElementView(viewType: _viewType);
  }
}