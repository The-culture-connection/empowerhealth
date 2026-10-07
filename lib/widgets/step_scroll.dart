import 'package:flutter/widgets.dart';

/// Scroll controller for multi-step flows that render every step inside one
/// scroll view. Call [syncStep] from `build` with a value that identifies the
/// visible step; whenever it changes, the view jumps back to the top after the
/// frame so the new step is shown from its start instead of at the previous
/// step's scroll offset.
class StepScrollController extends ScrollController {
  Object? _step;
  bool _hasStep = false;

  void syncStep(Object? step) {
    final changed = _hasStep && step != _step;
    _step = step;
    _hasStep = true;
    if (changed) scrollToTopAfterFrame(this);
  }
}

/// Jumps [controller] to the top once the current frame has laid out.
void scrollToTopAfterFrame(ScrollController controller) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!controller.hasClients) return;
    for (final position in controller.positions) {
      if (position.pixels != position.minScrollExtent) {
        position.jumpTo(position.minScrollExtent);
      }
    }
  });
}
