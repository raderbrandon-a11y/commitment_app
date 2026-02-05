import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 👈 haptics
import 'package:provider/provider.dart';

import '../models/outcomes.dart';
import '../state/session_engine.dart';

class OutcomeScreen extends StatelessWidget {
  const OutcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<SessionEngine>();

    const navy = Color(0xFF161526);
    const yellow = Color(0xFFF2B749);
    const pink = Color(0xFFF28891);

    ButtonStyle styleFor(Color bg) {
      return ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      );
    }

    Future<void> _withHaptic(
      VoidCallback haptic,
      VoidCallback action,
    ) async {
      haptic();
      await Future.delayed(const Duration(milliseconds: 16)); // 👈 one frame
      action();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('How did it go?'),
        centerTitle: true, // 👈 horizontal center
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Log your outcome',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _withHaptic(
                    HapticFeedback.mediumImpact,
                    () => engine.finalizeOutcome(Outcome.completed),
                  );
                },
                style: styleFor(navy),
                child: const Text('Completed'),
              ),
            ),
            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _withHaptic(
                    HapticFeedback.lightImpact,
                    () => engine.finalizeOutcome(Outcome.partial),
                  );
                },
                style: styleFor(yellow),
                child: const Text('Partially completed (25–99%)'),
              ),
            ),
            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _withHaptic(
                    HapticFeedback.selectionClick,
                    () => engine.finalizeOutcome(Outcome.incomplete),
                  );
                },
                style: styleFor(pink),
                child: const Text('Barely started (0–24%)'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
