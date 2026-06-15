// ===========================================================================
// lib/widgets/html_iframe.dart
// ---------------------------------------------------------------------------
// Renders a full HTML string inside a real browser <iframe>. This is what the
// Lesson tab uses so the AI's CSS animations and JavaScript actually RUN
// (unlike flutter_widget_from_html, which only shows static HTML).
//
// THEME: the AI sometimes returns bare HTML with little or no styling. To keep
// every lesson looking good, we wrap the AI's HTML in a built-in dark theme
// (matching the app's navy/blue look). If the AI DID include its own <style>,
// those rules are placed after ours, so the AI's design still wins.
//
// The iframe is sandboxed with "allow-scripts" only: scripts can run, but the
// page is treated as a separate origin and can't touch the parent app.
//
// WEB ONLY: uses dart:html and dart:ui_web, which exist only on Flutter Web.
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

    final iframe = web.IFrameElement()
      ..srcdoc = _wrapLesson(widget.html)
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..setAttribute('sandbox', 'allow-scripts');

    ui_web.platformViewRegistry
        .registerViewFactory(_viewType, (int viewId) => iframe);
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}

// Wraps the AI's HTML in a themed document so bare HTML still looks good.
String _wrapLesson(String raw) {
  // Keep any <style> blocks the AI provided (we re-add them AFTER our base
  // theme so the AI's own styling takes precedence).
  final aiStyles = RegExp(r'<style[^>]*>[\s\S]*?</style>', caseSensitive: false)
      .allMatches(raw)
      .map((m) => m.group(0)!)
      .join('\n');

  // Get just the visible content. If the AI sent a full HTML document, take
  // what's inside <body>; otherwise strip stray doc tags and use the rest.
  String body;
  final bodyMatch =
      RegExp(r'<body[^>]*>([\s\S]*?)</body>', caseSensitive: false)
          .firstMatch(raw);
  if (bodyMatch != null) {
    body = bodyMatch.group(1) ?? raw;
  } else {
    body = raw
        .replaceAll(RegExp(r'<!doctype[^>]*>', caseSensitive: false), '')
        .replaceAll(RegExp(r'</?html[^>]*>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<head[^>]*>[\s\S]*?</head>', caseSensitive: false),
            '');
  }

  return '''
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>$_baseCss</style>
$aiStyles
</head>
<body>
<main class="theetify-lesson">
$body
</main>
</body>
</html>
''';
}

// The built-in dark theme applied to every lesson.
const String _baseCss = r'''
:root{
  --bg:#0D1B2A; --surface:#13263b; --text:#E7EEF5; --dim:#A9BBCC;
  --accent:#33A7E8; --line:rgba(140,180,215,.18); --code:#0a1622;
}
*{box-sizing:border-box;}
html,body{margin:0;padding:0;background:var(--bg);}
body{
  font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Helvetica,Arial,sans-serif;
  color:var(--text);line-height:1.7;font-size:16px;-webkit-font-smoothing:antialiased;
}
.theetify-lesson{max-width:860px;margin:0 auto;padding:32px 26px 72px;}
h1,h2,h3,h4{line-height:1.25;font-weight:700;color:#fff;margin:1.6em 0 .55em;}
h1{font-size:1.9em;margin-top:.15em;}
h2{font-size:1.45em;padding-bottom:.3em;border-bottom:1px solid var(--line);}
h3{font-size:1.18em;color:var(--accent);}
p{margin:0 0 1.05em;color:var(--dim);}
a{color:var(--accent);text-decoration:none;}
a:hover{text-decoration:underline;}
strong,b{color:#fff;font-weight:650;}
ul,ol{margin:0 0 1.1em;padding-left:1.4em;color:var(--dim);}
li{margin:.3em 0;}
li::marker{color:var(--accent);}
blockquote{margin:1.2em 0;padding:.6em 1.1em;border-left:3px solid var(--accent);
  background:rgba(51,167,232,.08);color:var(--text);border-radius:0 8px 8px 0;}
code{font-family:ui-monospace,Consolas,Menlo,monospace;font-size:.9em;background:var(--code);
  border:1px solid var(--line);border-radius:5px;padding:.12em .42em;color:#bfe3ff;}
pre{background:var(--code);border:1px solid var(--line);border-radius:10px;padding:16px;overflow:auto;margin:1.2em 0;}
pre code{background:none;border:none;padding:0;color:#cfe6ff;}
table{width:100%;border-collapse:collapse;margin:1.3em 0;font-size:.95em;border:1px solid var(--line);border-radius:10px;overflow:hidden;}
th,td{padding:11px 14px;text-align:left;border-bottom:1px solid var(--line);}
th{background:var(--surface);color:#fff;font-weight:650;}
tr:nth-child(even) td{background:rgba(255,255,255,.02);}
tr:last-child td{border-bottom:none;}
img{max-width:100%;height:auto;border-radius:8px;}
hr{border:none;border-top:1px solid var(--line);margin:1.8em 0;}
::selection{background:rgba(51,167,232,.35);}
.theetify-lesson{animation:fadeUp .5s ease both;}
@keyframes fadeUp{from{opacity:0;transform:translateY(8px);}to{opacity:1;transform:none;}}
@media (prefers-reduced-motion:reduce){.theetify-lesson{animation:none;}}
''';