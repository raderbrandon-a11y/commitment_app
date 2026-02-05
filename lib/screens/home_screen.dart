import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../state/session_engine.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _tapThen(VoidCallback go) async {
    HapticFeedback.selectionClick();
    await Future.delayed(const Duration(milliseconds: 16));
    go();
  }

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final engine = context.read<SessionEngine>();

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Text(
                'Finish It',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Close loops. Unlock momentum.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 20),

              Expanded(
                child: Center(
                  child: Container(
                    color: bg, // forces image background to match
                    padding: const EdgeInsets.all(6),
                    child: Image.asset(
                      'assets/images/task image.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _tapThen(() => engine.tapStart()),
                  child: const Text('Start'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _tapThen(() => engine.openHistory()),
                  child: const Text('History'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
