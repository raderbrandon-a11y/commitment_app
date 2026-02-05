import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/session.dart';
import '../models/outcomes.dart';
import '../services/storage_service.dart';
import '../services/clock.dart';

enum FlowState {
  idle,
  draftTask,
  draftDuration,
  confirm,
  running,
  needsOutcome,
  results,
  history,
}

class SessionEngine extends ChangeNotifier {
  final StorageService storage;
  final Clock clock;
  final Uuid _uuid = const Uuid();

  FlowState flow = FlowState.idle;

  // Draft inputs
  String draftTask = '';
  int draftDurationMinutes = 25;

  // 🔒 Premium-only draft input (we still store it here; UI decides visibility)
  String? draftCategory;

  // For "Use last task"
  String? lastTask;

  // Active session
  Session? activeSession;

  // Results screen session
  Session? lastLoggedSession;

  // History cache
  List<Session> history = <Session>[];

  Timer? _ticker;

  bool _initialized = false;
  Future<void>? _initFuture;

  SessionEngine({
    required this.storage,
    required this.clock,
  });

  Future<void> init() {
    _initFuture ??= _doInit();
    return _initFuture!;
  }

  Future<void> _doInit() async {
    await storage.init();
    history = await storage.loadSessions();

    if (history.isNotEmpty) {
      lastTask = history.first.task;
    }

    _initialized = true;
    notifyListeners();
  }

  Future<void> _ensureInit() async {
    if (_initialized) return;
    await init();
  }

  // ---------------------------
  // Premium gating helpers
  // ---------------------------

  /// Free: last 3 sessions. Premium: full history.
  List<Session> visibleHistory({required bool isPremium}) {
    if (isPremium) return history;
    if (history.length <= 3) return history;
    return history.take(3).toList(growable: false);
  }

  /// Count sessions logged today (local date based on clock.now()).
  int sessionsLoggedToday() {
    final now = clock.now();
    bool sameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;

    int count = 0;
    for (final s in history) {
      final ms = s.loggedAtMs ?? s.endTimeMs;
      final dt = DateTime.fromMillisecondsSinceEpoch(ms);
      if (sameDay(dt, now)) count++;
    }
    return count;
  }

  // ---------- Navigation actions ----------
  void goHome() {
    flow = FlowState.idle;
    notifyListeners();
  }

  void tapStart() {
    draftTask = '';
    draftDurationMinutes = 25;
    draftCategory = null;
    flow = FlowState.draftTask;
    notifyListeners();
  }

  void openHistory() async {
    await _ensureInit();
    history = await storage.loadSessions();
    flow = FlowState.history;
    notifyListeners();
  }

  // ---------- Draft task ----------
  void updateDraftTask(String v) {
    draftTask = v;
    notifyListeners();
  }

  void useLastTask() {
    if (lastTask == null) return;
    draftTask = lastTask!;
    notifyListeners();
  }

  void setDraftCategory(String? v) {
    final trimmed = v?.trim() ?? '';
    draftCategory = trimmed.isEmpty ? null : trimmed;
    notifyListeners();
  }

  void continueFromTask() {
    if (draftTask.trim().isEmpty) return;
    flow = FlowState.draftDuration;
    notifyListeners();
  }

  // ---------- Draft duration ----------
  void setDurationMinutes(int minutes) {
    draftDurationMinutes = minutes.clamp(1, 24 * 60);
    notifyListeners();
  }

  void continueFromDuration() {
    flow = FlowState.confirm;
    notifyListeners();
  }

  void backToTask() {
    flow = FlowState.draftTask;
    notifyListeners();
  }

  void backToDuration() {
    flow = FlowState.draftDuration;
    notifyListeners();
  }

  // ---------- Session runtime ----------
  void startSession({required bool isPremium}) {
    final nowMs = clock.nowMs();
    final endMs = clock
        .now()
        .add(Duration(minutes: draftDurationMinutes))
        .millisecondsSinceEpoch;

    activeSession = Session(
      id: _uuid.v4(),
      task: draftTask.trim(),
      durationMinutes: draftDurationMinutes,
      startTimeMs: nowMs,
      endTimeMs: endMs,
      category: isPremium ? draftCategory : null,
    );

    lastTask = draftTask.trim();
    flow = FlowState.running;

    _startTicker();
    notifyListeners();
  }

  Duration get remaining {
    final s = activeSession;
    if (s == null) return Duration.zero;
    final diff = s.endTimeMs - clock.nowMs();
    if (diff <= 0) return Duration.zero;
    return Duration(milliseconds: diff);
  }

  void endSessionEarly() {
    final s = activeSession;
    if (s == null) return;

    activeSession = s.copyWith(endedEarly: true);
    _ticker?.cancel();

    flow = FlowState.needsOutcome;
    notifyListeners();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (activeSession == null) {
        _ticker?.cancel();
        return;
      }

      if (remaining == Duration.zero) {
        _ticker?.cancel();
        flow = FlowState.needsOutcome;
        notifyListeners();
      } else {
        notifyListeners();
      }
    });
  }

  // Outcome selected -> save -> results
  Future<void> finalizeOutcome(Outcome outcome) async {
    await _ensureInit();
    final s = activeSession;
    if (s == null) return;

    final now = clock.nowMs();

    final logged = s.copyWith(
      outcome: outcome,
      loggedAtMs: now,
      endedEarly: s.endedEarly,
    );

    await storage.saveSession(logged);
    history = await storage.loadSessions();

    lastLoggedSession = logged;
    activeSession = null;

    flow = FlowState.results;
    notifyListeners();
  }

  // Results actions
  void resultsStartAnother() {
    tapStart();
  }

  void resultsGoToHistory() {
    openHistory();
  }

  Future<void> refreshHistory() async {
    await _ensureInit();
    history = await storage.loadSessions();
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
