import 'package:flutter/material.dart';

/// Pops overlay routes on the app [Navigator] until only the root remains.
///
/// Safe alternative to [Navigator.popUntil] with `route.isFirst`, which can
/// interact badly with follow-up [Navigator.pop] calls and empty the stack.
void popAllOverlayRoutes(BuildContext context) {
  final navigator = Navigator.of(context);
  while (navigator.canPop()) {
    navigator.pop();
  }
}

/// Pops at most [count] routes; never pops below the root.
void popOverlayRoutes(BuildContext context, {required int count}) {
  final navigator = Navigator.of(context);
  var remaining = count;
  while (navigator.canPop() && remaining > 0) {
    navigator.pop();
    remaining--;
  }
}
