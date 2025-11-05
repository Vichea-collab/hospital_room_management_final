import 'dart:io';

String _esc(String code) => '\x1B[$code';

String green(String s) => '${_esc('32m')}$s${_esc('0m')}';
String yellow(String s) => '${_esc('33m')}$s${_esc('0m')}';
String red(String s) => '${_esc('31m')}$s${_esc('0m')}';
String blue(String s) => '${_esc('34m')}$s${_esc('0m')}';
String cyan(String s) => '${_esc('36m')}$s${_esc('0m')}';
String magenta(String s) => '${_esc('35m')}$s${_esc('0m')}';

void printHeader(String title) {
  stdout.writeln(blue('=== $title ==='));
}

String prompt(String label, {String? defaultValue}) {
  stdout.write(
      '${yellow(label)}${defaultValue != null ? ' [$defaultValue]' : ''}: ');
  final line = stdin.readLineSync();
  if ((line == null || line.trim().isEmpty) && defaultValue != null)
    return defaultValue;
  return line?.trim() ?? '';
}

int? promptInt(String label, {int? defaultValue}) {
  final s = prompt(label, defaultValue: defaultValue?.toString());
  return int.tryParse(s);
}

bool confirm(String label, {bool defaultYes = true}) {
  final def = defaultYes ? 'Y/n' : 'y/N';
  stdout.write('${label} [$def]: ');
  final s = stdin.readLineSync();
  if (s == null || s.trim().isEmpty) return defaultYes;
  final lower = s.trim().toLowerCase();
  return lower == 'y' || lower == 'yes';
}

void clearScreen() {
  // Simple clear for many terminals
  if (stdout.hasTerminal) {
    stdout.write('\x1B[2J\x1B[H');
  }
}
