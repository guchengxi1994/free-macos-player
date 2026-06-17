import 'package:flutter_test/flutter_test.dart';
import 'package:free_macos_player/main.dart';

void main() {
  group('_formatDuration', () {
    test('formats mm:ss when under one hour', () {
      expect(formatDuration(const Duration(minutes: 2, seconds: 5)), '02:05');
    });

    test('formats hh:mm:ss when at least one hour', () {
      expect(
        formatDuration(const Duration(hours: 1, minutes: 2, seconds: 5)),
        '01:02:05',
      );
    });
  });
}
