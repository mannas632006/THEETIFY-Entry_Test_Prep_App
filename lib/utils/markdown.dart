// ===========================================================================
// lib/utils/markdown.dart
// ---------------------------------------------------------------------------
// A tiny, dependency-free Markdown -> HTML converter.
//
// WHY THIS EXISTS: the AI writes the Deep Notes and Crash Notes in Markdown
// (with #, **bold**, - lists, etc.). Flutter's plain Text() would show those
// symbols literally. Instead of adding a new package, we convert the Markdown
// to simple HTML here and render it with `flutter_widget_from_html`, which the
// app already uses for the lesson tab.
//
// It handles the common things the AI produces: headings, bold, italics,
// inline code, bullet lists, numbered lists, blockquotes, and horizontal
// rules. Anything it doesn't recognise is shown as a normal paragraph.
// ===========================================================================

/// Converts a Markdown string into a small, safe subset of HTML.
String markdownToHtml(String markdown) {
  final lines = markdown.replaceAll('\r\n', '\n').split('\n');
  final out = StringBuffer();

  final paragraph = <String>[];
  bool inUnordered = false;
  bool inOrdered = false;

  void closeLists() {
    if (inUnordered) {
      out.write('</ul>');
      inUnordered = false;
    }
    if (inOrdered) {
      out.write('</ol>');
      inOrdered = false;
    }
  }

  void flushParagraph() {
    if (paragraph.isNotEmpty) {
      out.write('<p>${_inline(paragraph.join(' '))}</p>');
      paragraph.clear();
    }
  }

  for (final raw in lines) {
    final line = raw.trim();

    // Blank line: end the current paragraph and any open list.
    if (line.isEmpty) {
      flushParagraph();
      closeLists();
      continue;
    }

    // Horizontal rule: ---, ***, or ___ on their own line.
    if (RegExp(r'^(-{3,}|\*{3,}|_{3,})$').hasMatch(line)) {
      flushParagraph();
      closeLists();
      out.write('<hr>');
      continue;
    }

    // Heading: # .. ###### .
    final heading = RegExp(r'^(#{1,6})\s+(.*)$').firstMatch(line);
    if (heading != null) {
      flushParagraph();
      closeLists();
      final level = heading.group(1)!.length;
      out.write('<h$level>${_inline(heading.group(2)!)}</h$level>');
      continue;
    }

    // Blockquote: > text .
    if (line.startsWith('> ')) {
      flushParagraph();
      closeLists();
      out.write('<blockquote>${_inline(line.substring(2))}</blockquote>');
      continue;
    }

    // Bullet list item: -, *, or + followed by a space.
    final bullet = RegExp(r'^[-*+]\s+(.*)$').firstMatch(line);
    if (bullet != null) {
      flushParagraph();
      if (inOrdered) {
        out.write('</ol>');
        inOrdered = false;
      }
      if (!inUnordered) {
        out.write('<ul>');
        inUnordered = true;
      }
      out.write('<li>${_inline(bullet.group(1)!)}</li>');
      continue;
    }

    // Numbered list item: 1. text .
    final numbered = RegExp(r'^\d+\.\s+(.*)$').firstMatch(line);
    if (numbered != null) {
      flushParagraph();
      if (inUnordered) {
        out.write('</ul>');
        inUnordered = false;
      }
      if (!inOrdered) {
        out.write('<ol>');
        inOrdered = true;
      }
      out.write('<li>${_inline(numbered.group(1)!)}</li>');
      continue;
    }

    // Anything else is part of a normal paragraph.
    closeLists();
    paragraph.add(line);
  }

  flushParagraph();
  closeLists();
  return out.toString();
}

/// Handles inline formatting inside a single piece of text:
/// HTML escaping first, then inline code, bold, and italics.
String _inline(String text) {
  // 1) Escape HTML-special characters so the source can't break the markup.
  //    (We add our own real tags AFTER this step, so they stay intact.)
  var s = text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');

  // 2) Inline code: `code` .
  s = s.replaceAllMapped(
    RegExp(r'`([^`]+)`'),
    (m) => '<code>${m.group(1)}</code>',
  );

  // 3) Bold: **text** or __text__  (handled before italics).
  s = s.replaceAllMapped(
    RegExp(r'\*\*([^*]+)\*\*'),
    (m) => '<strong>${m.group(1)}</strong>',
  );
  s = s.replaceAllMapped(
    RegExp(r'__([^_]+)__'),
    (m) => '<strong>${m.group(1)}</strong>',
  );

  // 4) Italics: *text* or _text_ .
  s = s.replaceAllMapped(
    RegExp(r'\*([^*]+)\*'),
    (m) => '<em>${m.group(1)}</em>',
  );
  s = s.replaceAllMapped(
    RegExp(r'_([^_]+)_'),
    (m) => '<em>${m.group(1)}</em>',
  );

  return s;
}