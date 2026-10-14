// Smoke test without mounting the full app (requires Firebase in widget tests).

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sanity', () {
    expect(2 + 2, 4);
  });
}
