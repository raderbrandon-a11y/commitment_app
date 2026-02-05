import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 👈 haptics
import 'package:provider/provider.dart';

import '../state/session_engine.dart';

class RunningScreen extends StatelessWidget {
  const RunningScreen({super.key});

  String _mmss(Duration d) {
    final total = d.inSeconds;
    final m = (total ~/ 60).toString().padLeft(2, '0');
    final s = (total % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<SessionEngine>();
    final s = engine.activeSession;

    if (s == null) {
      return const Scaffold(body: Center(child: Text('No active session')));
    }

    final remaining = engine.remaining;

    return Scaffold(
      appBar: AppBar(title: const Text('Countdown')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Commitment Mode banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Commitment Mode is on — pausing is disabled to help you stay locked in.',
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.help_outline),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      showModalBottomSheet(
                        context: context,
                        builder: (_) => const SafeArea(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'Why no pause?\n\n'
                              'This app is designed for short, focused commitments. '
                              'Pausing can stretch a 25-minute block into drift.\n\n'
                              'If you need to stop before time is up, tap “End session” and log an outcome.”\n',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Text(
              s.task,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            Text(
              _mmss(remaining),
              style: const TextStyle(fontSize: 72, fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: 24),

            // If timer hits zero, engine will automatically move to needsOutcome.
            // So here we just show buttons when still running.
            if (remaining > Duration.zero) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    engine.endSessionEarly();
                  },
                  child: const Text('End session'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
