import 'dart:math';

final Random _r = Random();

String uuid() {
  return '${_hex(8)}-${_hex(4)}-4${_hex(3)}-${(8 + _r.nextInt(4)).toRadixString(16)}${_hex(3)}-${_hex(12)}';
}

String _hex(int len) => List.generate(len, (_) => _r.nextInt(16).toRadixString(16)).join();
