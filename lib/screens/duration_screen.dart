import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 👈 haptics
import 'package:provider/provider.dart';

import '../state/session_engine.dart';

class DurationScreen extends StatefulWidget {
  const DurationScreen({super.key});

  @override
  State<DurationScreen> createState() => _DurationScreenState();
}

class _DurationScreenState extends State<DurationScreen> {
  late Duration _selected;

  @override
  void initState() {
    super.initState();
    final engine = context.read<SessionEngine>();
    _selected = Duration(minutes: engine.draftDurationMinutes);
  }

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<SessionEngine>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Duration'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            HapticFeedback.selectionClick();
            engine.backToTask();
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'How long will you work?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),

            SizedBox(
              height: 200,
              child: CupertinoTimerPicker(
                mode: CupertinoTimerPickerMode.hm,
                initialTimerDuration: _selected,
                onTimerDurationChanged: (d) {
                  if (d.inMinutes < 1) return;
                  _selected = d;
                  HapticFeedback.selectionClick();
                  engine.setDurationMinutes(d.inMinutes);
                },
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  engine.continueFromDuration();
                },
                child: Text(
                  'Continue (${engine.draftDurationMinutes} min)',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
