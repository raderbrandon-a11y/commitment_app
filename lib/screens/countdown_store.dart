import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/session.dart';
import '../models/outcomes.dart';
import '../services/storage_service.dart';
import '../services/clock.dart';

// Legacy store (kept compiling to avoid analyzer reds).
class CountdownStore extends ChangeNotifier {
  final StorageService storage;
  final Clock clock;
  final Uuid _uuid = const Uuid();

  Session? activeSession;
  Timer? _ticker;

  CountdownStore({
    required this.storage,
    required this.clock,
  });

  void startSession({
    required String task,
    required int durationMinutes,
  }) {
    final nowMs = clock.nowMs();
    final endMs = clock.now().add(Duration(minutes: durationMinutes)).millisecondsSinceEpoch;

    activeSession = Session(
      id: _uuid.v4(),
      task: task.trim(),
      durationMinutes: durationMinutes,
      startTimeMs: nowMs,
      endTimeMs: endMs,
    );

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

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (activeSession == null) {
        _ticker?.cancel();
        return;
      }
      if (remaining == Duration.zero) {
        _ticker?.cancel();
        notifyListeners();
      } else {
        notifyListeners();
      }
    });
  }

  Future<void> finalizeOutcome(Outcome outcome) async {
    final s = activeSession;
    if (s == null) return;

    final now = clock.nowMs();
    final logged = s.copyWith(outcome: outcome, loggedAtMs: now);

    await storage.saveSession(logged);
    activeSession = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
