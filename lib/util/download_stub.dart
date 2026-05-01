import 'dart:convert';

void downloadTextFile(
  String filename,
  String content, {
  String mime = 'text/plain',
}) {
  // ignore: avoid_print
  print(
    'downloadTextFile not supported on this platform: $filename (${utf8.encode(content).length} bytes, $mime)',
  );
}
