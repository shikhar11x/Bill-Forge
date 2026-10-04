import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/core/responsive/breakpoints.dart';

void main() {
  test('maps widths to screen sizes at the documented boundaries', () {
    expect(Breakpoints.fromWidth(599), ScreenSize.mobile);
    expect(Breakpoints.fromWidth(600), ScreenSize.tablet);
    expect(Breakpoints.fromWidth(1024), ScreenSize.tablet);
    expect(Breakpoints.fromWidth(1025), ScreenSize.desktop);
  });
}