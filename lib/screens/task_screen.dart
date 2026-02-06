import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/premium_service.dart';
import '../state/session_engine.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  final _taskController = TextEditingController();
  final _catController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Preload engine draft values if any
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final engine = context.read<SessionEngine>();
      _taskController.text = engine.draftTask;
      _catController.text = engine.draftCategory ?? '';
    });
  }

  @override
  void dispose() {
    _taskController.dispose();
    _catController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<SessionEngine>();
    final premium = context.watch<PremiumService>();

    final isPremium = premium.isPremium;
    final canContinue = engine.draftTask.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            HapticFeedback.selectionClick();
            engine.goHome();
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _taskController,
                decoration: const InputDecoration(
                  labelText: 'Task',
                ),
                onChanged: engine.updateDraftTask,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),

              if (isPremium) ...[
                TextField(
                  controller: _catController,
                  decoration: const InputDecoration(
                    labelText: 'Category (Premium)',
                    hintText: 'e.g., Work, Fitness, Admin',
                  ),
                  onChanged: (v) => engine.setDraftCategory(v),
                  textInputAction: TextInputAction.done,
                ),
              ],

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: canContinue
                      ? () {
                          HapticFeedback.lightImpact();
                          engine.continueFromTask();
                        }
                      : null,
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
