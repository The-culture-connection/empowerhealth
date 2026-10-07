// QA harness hooks. Compiled in only with --dart-define=QA_HARNESS=true (the
// Railway testing build); every entry point is a pass-through otherwise.
//
// The harness page (deploy/webapp/harness) hosts the app in an iframe sized to
// a real phone viewport and drives it over postMessage:
//   host → app: config (text scale, Bold Text, safe areas, keyboard, platform),
//               audit, highlight, inspect, flash, ping
//   app → host: ready, metrics, log, error, nav, audit, inspect

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter/scheduler.dart';

import '../cors/main_navigation_scope.dart';

import 'layout_auditor.dart';
import 'widget_index.g.dart';
import 'qa_bridge_stub.dart' if (dart.library.js_interop) 'qa_bridge_web.dart';

class QaDeviceConfig {
  const QaDeviceConfig({
    this.device = 'Browser',
    this.textScale = 1.0,
    this.boldText = false,
    this.safeTop = 0,
    this.safeBottom = 0,
    this.keyboard = false,
    this.keyboardHeight = 336,
    this.platform = TargetPlatform.iOS,
  });

  final String device;
  final double textScale;
  final bool boldText;
  final double safeTop;
  final double safeBottom;
  final bool keyboard;
  final double keyboardHeight;
  final TargetPlatform platform;

  static TargetPlatform _platform(Object? v) =>
      v == 'android' ? TargetPlatform.android : TargetPlatform.iOS;

  static double _num(Object? v, double fallback) {
    if (v is num) return v.toDouble();
    return double.tryParse('${v ?? ''}') ?? fallback;
  }

  static bool _bool(Object? v) => v == true || v == 'true' || v == '1';

  factory QaDeviceConfig.fromMap(Map<String, dynamic> m) => QaDeviceConfig(
        device: (m['device'] ?? 'Browser').toString(),
        textScale: _num(m['textScale'] ?? m['ts'], 1.0),
        boldText: _bool(m['boldText'] ?? m['bold']),
        safeTop: _num(m['safeTop'] ?? m['top'], 0),
        safeBottom: _num(m['safeBottom'] ?? m['bottom'], 0),
        keyboard: _bool(m['keyboard'] ?? m['kb']),
        keyboardHeight: _num(m['keyboardHeight'] ?? m['kbh'], 336),
        platform: _platform(m['platform']),
      );

  /// Initial config from the iframe URL so the first frame is already right.
  factory QaDeviceConfig.fromUri(Uri uri) =>
      QaDeviceConfig.fromMap(Map<String, dynamic>.from(uri.queryParameters));

  MediaQueryData apply(MediaQueryData mq) {
    final insetBottom = keyboard ? keyboardHeight : 0.0;
    return mq.copyWith(
      textScaler: TextScaler.linear(textScale),
      boldText: boldText,
      viewPadding: EdgeInsets.only(top: safeTop, bottom: safeBottom),
      // Like iOS: the keyboard consumes the home-indicator inset.
      padding: EdgeInsets.only(
        top: safeTop,
        bottom: math.max(0, safeBottom - insetBottom),
      ),
      viewInsets: EdgeInsets.only(bottom: insetBottom),
    );
  }
}

class QaHarness {
  QaHarness._();

  static const bool enabled = bool.fromEnvironment('QA_HARNESS');

  static final ValueNotifier<QaDeviceConfig> config =
      ValueNotifier(enabled ? QaDeviceConfig.fromUri(Uri.base) : const QaDeviceConfig());
  static final ValueNotifier<bool> highlight = ValueNotifier(false);
  static final ValueNotifier<bool> inspect = ValueNotifier(false);
  static final ValueNotifier<List<QaIssue>> issues = ValueNotifier(const []);
  static final ValueNotifier<Rect?> selected = ValueNotifier(null);

  static final GlobalKey _appKey = GlobalKey(debugLabel: 'qa-app');
  static String _route = '/';
  static const _tabNames = ['Home', 'Learn', 'Journal', 'Community', 'You'];
  static String _lastAuditSignature = '';
  static Timer? _auditTimer;

  static final _QaNavigatorObserver _observer = _QaNavigatorObserver();

  static List<NavigatorObserver> get navigatorObservers =>
      enabled ? [_observer] : const [];

  /// Runs [appMain] inside a zone that mirrors print/errors to the harness.
  static void run(Future<void> Function() appMain) {
    if (!enabled) {
      appMain();
      return;
    }
    runZonedGuarded(
      () {
        WidgetsFlutterBinding.ensureInitialized();
        _install();
        appMain();
      },
      (error, stack) => _postError('Uncaught: $error', '$error\n$stack'),
      zoneSpecification: ZoneSpecification(
        print: (self, parent, zone, line) {
          qaPost({'type': 'log', 'level': 'print', 'message': line});
          parent.print(zone, line);
        },
      ),
    );
  }

  static void _install() {
    debugDefaultTargetPlatformOverride = config.value.platform;

    final previousFlutterError = FlutterError.onError;
    FlutterError.onError = (details) {
      var detail = _normalizePaths(details.toString());
      // Web builds have no creation locations; map the widget chain
      // ("Row ← Padding ← _CareToolCard ← …") to project source instead.
      final chain = detail.split('\n').where((l) => l.contains('←')).join(' ');
      final widgets = qaProjectWidgetsInChain(chain);
      if (widgets.isNotEmpty) detail = 'Project widgets: ${widgets.join(', ')}\n\n$detail';
      _postError(details.exceptionAsString(), detail);
      previousFlutterError?.call(details);
    };
    final previousPlatformError = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (error, stack) {
      _postError('Async: $error', '$error\n$stack');
      return previousPlatformError?.call(error, stack) ?? false;
    };

    qaListen(_onHostMessage);
    SchedulerBinding.instance.addPersistentFrameCallback((_) => _scheduleAudit());
    SchedulerBinding.instance.addPostFrameCallback((_) {
      qaPost({'type': 'ready'});
      _postMetrics();
    });
  }

  static void _onHostMessage(Map<String, dynamic> m) {
    switch (m['type']) {
      case 'ping':
        qaPost({'type': 'ready'});
        _postMetrics();
      case 'config':
        final next = QaDeviceConfig.fromMap(Map<String, dynamic>.from(m['config'] as Map));
        final platformChanged = next.platform != config.value.platform;
        config.value = next;
        if (platformChanged) {
          debugDefaultTargetPlatformOverride = next.platform;
          WidgetsBinding.instance.reassembleApplication();
        }
        SchedulerBinding.instance.addPostFrameCallback((_) => _postMetrics());
        WidgetsBinding.instance.scheduleFrame();
      case 'audit':
        _runAudit(force: true);
      case 'navigate':
        _navigate(Map<String, dynamic>.from((m['target'] as Map?) ?? const {}));
      case 'screenshot':
        unawaited(_captureScreenshot(m['requestId']));
      case 'highlight':
        highlight.value = m['on'] == true;
        if (highlight.value) _runAudit(force: true);
      case 'inspect':
        inspect.value = m['on'] == true;
        if (!inspect.value) selected.value = null;
      case 'flash':
        final r = m['rect'];
        if (r is Map) {
          selected.value = Rect.fromLTWH(
            (r['x'] as num).toDouble(),
            (r['y'] as num).toDouble(),
            (r['w'] as num).toDouble(),
            (r['h'] as num).toDouble(),
          );
        }
    }
  }

  static void _scheduleAudit() {
    _auditTimer?.cancel();
    _auditTimer = Timer(const Duration(milliseconds: 900), () => _runAudit());
  }

  static void _runAudit({bool force = false}) {
    List<QaIssue> found;
    try {
      found = qaRunAudit();
    } catch (e) {
      qaPost({'type': 'log', 'level': 'warn', 'message': 'Layout audit failed: $e'});
      return;
    }
    final screens = _visibleScreens();
    final signature = '${screens.join(',')}#${found.map((i) => i.signature).join(';')}';
    if (!force && signature == _lastAuditSignature) return;
    _lastAuditSignature = signature;
    issues.value = found;
    qaPost({
      'type': 'audit',
      'route': _route,
      'screens': screens,
      'issues': found.map((i) => i.toJson()).toList(),
    });
  }

  static void _postMetrics() {
    final views = WidgetsBinding.instance.renderViews;
    if (views.isEmpty) return;
    final view = views.first;
    final c = config.value;
    qaPost({
      'type': 'metrics',
      'width': view.size.width,
      'height': view.size.height,
      'dpr': view.flutterView.devicePixelRatio,
      'textScale': c.textScale,
      // Matches the clamp in lib/main.dart's MaterialApp.builder.
      'textScaleEffective': c.textScale.clamp(0.9, 1.3),
      'boldText': c.boldText,
      'safeTop': c.safeTop,
      'safeBottom': c.safeBottom,
      'keyboard': c.keyboard ? c.keyboardHeight : 0,
      'platform': c.platform == TargetPlatform.android ? 'android' : 'ios',
      'route': _route,
    });
  }

  static void _postError(String summary, String detail) {
    qaPost({
      'type': 'error',
      'summary': summary,
      'detail': detail.length > 6000 ? '${detail.substring(0, 6000)}…' : detail,
      'route': _route,
    });
  }

  static String _normalizePaths(String text) =>
      text.replaceAllMapped(RegExp(r'(?:file|org-dartlang-app|https?):\/\/[^\s:]*?\/(lib\/[^\s:]+)'),
          (m) => m.group(1)!);

  /// Project screens the user can currently see: the top page route (plus
  /// any page under a dialog/sheet) and, inside it, the selected tab.
  static List<String> _visibleScreens() {
    final screenName = RegExp(r'(Screen|Page)(V\d+)?$');
    final names = <String>[];
    void visit(Element e) {
      final w = e.widget;
      if (w is Offstage && w.offstage) return;
      if (w is Visibility && !w.visible) return;
      final name = qaTypeName(w);
      if (screenName.hasMatch(name) && !names.contains(name) && qaWidgetIndex.containsKey(name)) {
        names.add(name);
      }
      // IndexedStack hides unselected tabs with Visibility(visible: false).
      e.visitChildElements(visit);
    }

    final visible = <Route<dynamic>>[];
    for (final route in _QaNavigatorObserver.stack.reversed) {
      visible.insert(0, route);
      if (route is ModalRoute && route.opaque) break;
    }
    for (final route in visible) {
      final context = route is ModalRoute ? route.subtreeContext : null;
      if (context is Element) visit(context);
    }
    // Name the bottom tab too, so gated or unnamed tab content is still identifiable.
    final tab = _currentTab();
    if (tab != null && tab < _tabNames.length && visible.isNotEmpty && visible.first == _QaNavigatorObserver.stack.first) {
      names.insert(0, '${_tabNames[tab]} tab');
    }
    return names;
  }

  /// Wraps the app below MaterialApp: applies the simulated device to
  /// MediaQuery (before the app's own text-scale clamp in [build]) and adds
  /// the highlight / inspect overlay.
  static Widget wrapApp(
    BuildContext context,
    Widget Function(MediaQueryData mediaQuery) build,
  ) {
    if (!enabled) return build(MediaQuery.of(context));
    return ValueListenableBuilder<QaDeviceConfig>(
      valueListenable: config,
      builder: (context, c, _) => _QaOverlay(
        appKey: _appKey,
        child: build(c.apply(MediaQuery.of(context))),
      ),
    );
  }

  /// The bottom-nav scope (main tab scaffold) on the topmost route that has
  /// one. After login the app pushes a second main scaffold above the auth
  /// gate's route, so there can be more than one.
  static Element? _tabScopeElement() {
    final root = WidgetsBinding.instance.rootElement;
    if (root == null) return null;
    final scopes = <Element>[];
    void visit(Element e) {
      if (e.widget is MainNavigationScope) {
        scopes.add(e);
        return;
      }
      e.visitChildElements(visit);
    }

    visit(root);
    Element? best;
    var bestIndex = -2;
    for (final element in scopes) {
      final route = ModalRoute.of(element);
      if (route != null && !route.isActive) continue;
      final index = route == null ? -1 : _QaNavigatorObserver.stack.indexOf(route);
      if (index >= bestIndex) {
        best = element;
        bestIndex = index;
      }
    }
    return best;
  }

  /// Selected bottom-nav tab (0 Home … 4 You), or null outside the main scaffold.
  static int? _currentTab() {
    final scope = _tabScopeElement();
    if (scope == null) return null;
    int? index;
    void visit(Element e) {
      if (index != null) return;
      final w = e.widget;
      if (w is IndexedStack) {
        index = w.index;
        return;
      }
      e.visitChildElements(visit);
    }

    visit(scope);
    return index;
  }

  /// Opens the screen a checklist item is about: closes pages above the main
  /// tab scaffold (never the scaffold itself or what's under it, such as the
  /// sign-in route), selects [target]['tab'], then pushes [target]['route'].
  static void _navigate(Map<String, dynamic> target) {
    final navigator = _observer.navigator;
    if (navigator == null) return;
    final scopeElement = _tabScopeElement();
    final mainRoute = scopeElement == null ? null : ModalRoute.of(scopeElement);
    if (mainRoute != null && mainRoute.navigator == navigator) {
      navigator.popUntil((route) => route == mainRoute);
    }
    final tab = target['tab'];
    if (tab is num) {
      final scope = scopeElement?.widget;
      if (scope is! MainNavigationScope) {
        qaPost({
          'type': 'log',
          'level': 'warn',
          'message': 'Sign in or tap "Explore as Guest" first, then open the screen again.',
        });
        return;
      }
      scope.selectTab(tab.toInt());
    }
    final route = target['route'];
    if (route is String && route.isNotEmpty && route != '/') {
      SchedulerBinding.instance.addPostFrameCallback((_) => navigator.pushNamed(route));
    }
  }

  /// PNG of the app as rendered (without the harness overlay), plus the
  /// context needed to file a bug and reopen its screen.
  static Future<void> _captureScreenshot(Object? requestId) async {
    try {
      final boundary = _appKey.currentContext?.findRenderObject();
      if (boundary is! RenderRepaintBoundary) throw StateError('app not rendered yet');
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final size = Size(image.width / 2, image.height / 2);
      image.dispose();
      if (bytes == null) throw StateError('could not encode PNG');
      final top = _QaNavigatorObserver.stack.isEmpty ? null : _QaNavigatorObserver.stack.last;
      qaPost({
        'type': 'screenshot',
        'requestId': requestId,
        'png': base64Encode(bytes.buffer.asUint8List()),
        'width': size.width,
        'height': size.height,
        'route': top?.settings.name,
        'tab': _currentTab(),
        'screens': _visibleScreens(),
        'issues': issues.value.map((i) => i.toJson()).toList(),
      });
    } catch (e) {
      qaPost({'type': 'screenshot', 'requestId': requestId, 'error': '$e'});
    }
  }

  static void _inspectAt(Offset position) {
    final box = _appKey.currentContext?.findRenderObject();
    if (box is! RenderBox) return;
    final info = qaInspectAt(box, position);
    if (info == null) return;
    final r = info['rect']! as Map<String, double>;
    selected.value = Rect.fromLTWH(r['x']!, r['y']!, r['w']!, r['h']!);
    qaPost({'type': 'inspect', 'route': _route, 'info': info});
  }
}

class _QaNavigatorObserver extends NavigatorObserver {
  /// Current route stack, bottom to top.
  static final List<Route<dynamic>> stack = [];

  void _report(String action, Route<dynamic>? top) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final screens = QaHarness._visibleScreens();
      final name = top?.settings.name;
      QaHarness._route = name ?? (screens.isNotEmpty ? screens.last : top?.runtimeType.toString() ?? '?');
      qaPost({
        'type': 'nav',
        'action': action,
        'route': QaHarness._route,
        'screens': screens,
      });
      QaHarness._scheduleAudit();
    });
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    stack.add(route);
    _report('push', route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    stack.remove(route);
    _report('pop', previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    stack.remove(route);
    _report('remove', stack.isEmpty ? null : stack.last);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final i = oldRoute == null ? -1 : stack.indexOf(oldRoute);
    if (newRoute != null) {
      if (i >= 0) {
        stack[i] = newRoute;
      } else {
        stack.add(newRoute);
      }
    }
    _report('replace', newRoute);
  }
}

class _QaOverlay extends StatelessWidget {
  const _QaOverlay({required this.appKey, required this.child});

  final GlobalKey appKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      textDirection: TextDirection.ltr,
      fit: StackFit.expand,
      children: [
        RepaintBoundary(key: appKey, child: child),
        IgnorePointer(
          child: AnimatedBuilder(
            animation: Listenable.merge([
              QaHarness.highlight,
              QaHarness.issues,
              QaHarness.selected,
            ]),
            builder: (context, _) => CustomPaint(
              painter: _QaPainter(
                issues: QaHarness.highlight.value ? QaHarness.issues.value : const [],
                selected: QaHarness.selected.value,
              ),
            ),
          ),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: QaHarness.inspect,
          builder: (context, on, _) => on
              ? Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (e) => QaHarness._inspectAt(e.position),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _QaPainter extends CustomPainter {
  _QaPainter({required this.issues, required this.selected});

  final List<QaIssue> issues;
  final Rect? selected;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < issues.length; i++) {
      final issue = issues[i];
      final color = issue.severity == 'P0' ? const Color(0xFFE5484D) : const Color(0xFFF59E0B);
      canvas.drawRect(issue.rect, Paint()..color = color.withValues(alpha: 0.12));
      canvas.drawRect(
        issue.rect,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      final label = TextPainter(
        text: TextSpan(
          text: ' ${i + 1} ',
          style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 10, fontWeight: FontWeight.w700),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final origin = Offset(
        issue.rect.left.clamp(0.0, math.max(0.0, size.width - label.width)),
        (issue.rect.top - label.height).clamp(0.0, math.max(0.0, size.height - label.height)),
      );
      canvas.drawRect(origin & label.size, Paint()..color = color);
      label.paint(canvas, origin);
      label.dispose();
    }
    if (selected != null) {
      canvas.drawRect(selected!, Paint()..color = const Color(0x332F80ED));
      canvas.drawRect(
        selected!,
        Paint()
          ..color = const Color(0xFF2F80ED)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(_QaPainter old) => old.issues != issues || old.selected != selected;
}
