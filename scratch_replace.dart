import 'dart:io';

void main() {
  final dir = Directory('lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    String content = file.readAsStringSync();
    if (content.contains('.withOpacity(')) {
      content = content.replaceAllMapped(
        RegExp(r'\.withOpacity\((.*?)\)'), 
        (m) => '.withValues(alpha: ${m[1]})'
      );
      file.writeAsStringSync(content);
      print('Updated opacity in ${file.path}');
    }
  }
}
