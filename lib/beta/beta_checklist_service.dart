import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

import '../services/analytics_service.dart';
import 'beta_checklist.dart';

export 'beta_checklist.dart';

/// Tracks the beta checklist for the signed-in user (guests included).
///
/// State lives under the user's own doc so the owner-only rules cover it:
/// `users/{uid}/beta/checklist` and `users/{uid}/beta_days/{yyyy-MM-dd}`.
/// Every Firebase call is best-effort; nothing here may break the app.
class BetaChecklistService extends ChangeNotifier with WidgetsBindingObserver {
  BetaChecklistService._();

  static final BetaChecklistService instance = BetaChecklistService._();

  bool _initialized = false;
  StreamSubscription<User?>? _authSub;
  Timer? _timer;
  bool _foreground = true;

  String? _uid;
  Future<void>? _loadFuture;
  bool _loading = false;
  final Map<String, DateTime?> _completed = {};
  final Set<String> _inFlight = {};
  String _todayKey = betaDateKey(DateTime.now());
  int _todaySeconds = 0;
  bool _todayGoalMet = false;
  final Set<String> _goalDays = {};

  // Set while this service logs its own events, so they never feed back in.
  bool _loggingOwnEvent = false;

  bool get isVisible => kBetaTestingEnabled && _uid != null;
  bool get loading => _loading;

  List<({BetaChecklistItem item, bool done})> get items => [
    for (final item in kBetaChecklistItems)
      (item: item, done: _completed.containsKey(item.id)),
  ];

  bool isDone(String id) => _completed.containsKey(id);

  int get completedCount =>
      kBetaChecklistItems.where((i) => _completed.containsKey(i.id)).length;

  int get totalItems => kBetaChecklistItems.length;

  int get remainingCount =>
      betaRemainingCount(_completed.keys.toSet(), _effectiveTodaySeconds);

  int get todayMinutes => _effectiveTodaySeconds ~/ 60;

  bool get todayGoalMet => _todayGoalMet || betaDailyGoalMet(_todaySeconds);

  int get daysGoalMet => _goalDays.length;

  int get _effectiveTodaySeconds =>
      _todayGoalMet && _todaySeconds < kBetaDailyGoalSeconds
      ? kBetaDailyGoalSeconds
      : _todaySeconds;

  DocumentReference<Map<String, dynamic>> _checklistRef(String uid) =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('beta')
          .doc('checklist');

  CollectionReference<Map<String, dynamic>> _daysRef(String uid) =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('beta_days');

  /// Call once after Firebase is initialised.
  void initialize() {
    if (!kBetaTestingEnabled || _initialized) return;
    _initialized = true;
    try {
      final binding = WidgetsBinding.instance;
      binding.addObserver(this);
      final state = binding.lifecycleState;
      _foreground = state == null || state == AppLifecycleState.resumed;
      _authSub = FirebaseAuth.instance.authStateChanges().listen(
        _onAuthChanged,
        onError: (Object e) => debugPrint('[Beta] auth stream error: $e'),
      );
      _onAuthChanged(FirebaseAuth.instance.currentUser);
    } catch (e) {
      debugPrint('[Beta] initialize failed: $e');
    }
  }

  void _onAuthChanged(User? user) {
    // A token refresh can emit a transient null while a user is still signed in.
    final resolved = user ?? FirebaseAuth.instance.currentUser;
    final uid = resolved?.uid;
    if (uid == _uid) return;
    _stopTimer();
    _uid = uid;
    _resetState();
    notifyListeners();
    if (uid != null) {
      _loadFuture = _load(uid);
    } else {
      _loadFuture = null;
    }
  }

  void _resetState() {
    _completed.clear();
    _inFlight.clear();
    _goalDays.clear();
    _todayKey = betaDateKey(DateTime.now());
    _todaySeconds = 0;
    _todayGoalMet = false;
  }

  Future<void> _load(String uid) async {
    _loading = true;
    notifyListeners();
    try {
      final checklist = await _checklistRef(uid).get();
      final today = await _daysRef(uid).doc(_todayKey).get();
      final cutoff = betaDateKey(
        DateTime.now().subtract(const Duration(days: kBetaGoalHistoryDays)),
      );
      final goalDocs = await _daysRef(
        uid,
      ).where('goalMet', isEqualTo: true).get();
      if (uid != _uid) return;

      final completed = checklist.data()?['completed'];
      if (completed is Map) {
        for (final entry in completed.entries) {
          final v = entry.value;
          _completed[entry.key.toString()] = v is Timestamp ? v.toDate() : null;
        }
      }
      final todayData = today.data();
      final seconds = todayData?['seconds'];
      _todaySeconds = seconds is num ? seconds.toInt() : 0;
      _todayGoalMet = todayData?['goalMet'] == true;
      for (final doc in goalDocs.docs) {
        if (doc.id.compareTo(cutoff) >= 0) _goalDays.add(doc.id);
      }
    } catch (e) {
      debugPrint('[Beta] load failed: $e');
    } finally {
      if (uid == _uid) {
        _loading = false;
        notifyListeners();
        _syncTimer();
      }
    }
  }

  /// Reloads from Firestore (e.g. when the checklist screen opens).
  Future<void> refresh() async {
    final uid = _uid;
    if (!kBetaTestingEnabled || uid == null) return;
    _rollDateIfNeeded();
    _loadFuture = _load(uid);
    await _loadFuture;
  }

  /// Completes any items triggered by [eventName]. Never throws.
  void recordEvent(String eventName) {
    if (!kBetaTestingEnabled || !_initialized || _uid == null) return;
    if (_loggingOwnEvent || eventName.startsWith('beta_')) return;
    try {
      for (final item in betaItemsForEvent(eventName)) {
        if (!_completed.containsKey(item.id)) {
          unawaited(markDone(item.id));
        }
      }
    } catch (e) {
      debugPrint('[Beta] recordEvent failed: $e');
    }
  }

  /// Marks checklist item [id] done for the current user (first time only).
  Future<void> markDone(String id) async {
    if (!kBetaTestingEnabled || !_initialized) return;
    final item = betaItemById(id);
    final uid = _uid;
    if (item == null || uid == null) return;
    try {
      await _loadFuture;
      if (uid != _uid || _completed.containsKey(id) || !_inFlight.add(id)) {
        return;
      }
      _completed[id] = DateTime.now();
      notifyListeners();
      await _writeChecklist(uid, completedId: id);
      await _logOwnEvent('beta_checklist_item_completed', {
        'item_id': item.id,
        'item_title': item.title,
        'remaining': remainingCount,
      });
    } catch (e) {
      debugPrint('[Beta] markDone($id) failed: $e');
    } finally {
      _inFlight.remove(id);
    }
  }

  Future<void> _writeChecklist(String uid, {String? completedId}) async {
    await _checklistRef(uid).set({
      if (completedId != null)
        'completed': {completedId: FieldValue.serverTimestamp()},
      'totalItems': totalItems,
      'remaining': remainingCount,
      'todaySeconds': _todaySeconds,
      'updatedAt': FieldValue.serverTimestamp(),
      'timezoneOffsetMinutes': DateTime.now().timeZoneOffset.inMinutes,
    }, SetOptions(merge: true));
  }

  Future<void> _logOwnEvent(String name, Map<String, dynamic> params) async {
    _loggingOwnEvent = true;
    try {
      await AnalyticsService().logEvent(
        eventName: name,
        feature: 'app',
        parameters: params,
      );
    } catch (e) {
      debugPrint('[Beta] analytics $name failed: $e');
    } finally {
      _loggingOwnEvent = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Daily minutes
  // ---------------------------------------------------------------------------

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) _rollDateIfNeeded();
    _syncTimer();
  }

  void _syncTimer() {
    // Wait for the load so a tick can't be overwritten by the stored count.
    final shouldRun =
        kBetaTestingEnabled && _foreground && _uid != null && !_loading;
    if (shouldRun && _timer == null) {
      _timer = Timer.periodic(const Duration(minutes: 1), (_) => _tick());
    } else if (!shouldRun) {
      _stopTimer();
    }
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _rollDateIfNeeded() {
    final key = betaDateKey(DateTime.now());
    if (key == _todayKey) return;
    _todayKey = key;
    _todaySeconds = 0;
    _todayGoalMet = false;
    notifyListeners();
  }

  Future<void> _tick() async {
    final uid = _uid;
    if (uid == null || FirebaseAuth.instance.currentUser == null) {
      _stopTimer();
      return;
    }
    _rollDateIfNeeded();
    final key = _todayKey;
    _todaySeconds += 60;
    final reachedGoal = !_todayGoalMet && betaDailyGoalMet(_todaySeconds);
    if (reachedGoal) {
      _todayGoalMet = true;
      _goalDays.add(key);
    }
    notifyListeners();
    try {
      await _daysRef(uid).doc(key).set({
        'date': key,
        'seconds': FieldValue.increment(60),
        // Only ever set true, so another device's met goal is never undone.
        if (reachedGoal) 'goalMet': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (reachedGoal) {
        await _writeChecklist(uid);
        await _logOwnEvent('beta_daily_goal_met', {
          'date': key,
          'minutes': _todaySeconds ~/ 60,
        });
      }
    } catch (e) {
      debugPrint('[Beta] daily minutes write failed: $e');
    }
  }

  @override
  void dispose() {
    _stopTimer();
    unawaited(_authSub?.cancel());
    if (_initialized) WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
