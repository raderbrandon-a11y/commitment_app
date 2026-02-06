import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 👈 haptics
import 'package:provider/provider.dart';

import '../models/outcomes.dart';
import '../state/session_engine.dart';
import '../theme/app_theme.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  String _prettyOutcome(Outcome? o) {
    if (o == null) return 'Unlogged';
    switch (o) {
      case Outcome.completed:
        return 'Completed';
      case Outcome.partial:
        return 'Partially Completed';
      case Outcome.incomplete:
        return 'Barely Started';
    }
  }

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<SessionEngine>();
    final s = engine.lastLoggedSession;

    if (s == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Results')),
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              engine.goHome();
            },
            child: const Text('Back to home'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Results')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, // 👈 vertical center
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.task,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Planned: ${s.durationMinutes} min',
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    'Outcome: ${_prettyOutcome(s.outcome)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    'Finished early: ${s.endedEarly ? "Yes" : "No"}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      engine.resultsGoToHistory();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.coral,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('View history'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      engine.resultsStartAnother();
                    },
                    child: const Text('Start another'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
