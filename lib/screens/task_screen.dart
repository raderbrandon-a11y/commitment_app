import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/premium_service.dart';
import '../state/session_engine.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  static const String _prefsDebugPremiumKey = 'debug_premium_override';

  bool _debugPremiumOverride = false;
  bool _debugLoaded = false;

  final _taskController = TextEditingController();
  final _catController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDebugPremiumOverride();

    // preload engine draft values if any
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

  Future<void> _loadDebugPremiumOverride() async {
    if (!kDebugMode) return;
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getBool(_prefsDebugPremiumKey) ?? false;
    if (!mounted) return;
    setState(() {
      _debugPremiumOverride = v;
      _debugLoaded = true;
    });
  }

  bool _isPremiumSafe(Object? premium) {
    if (premium == null) return false;
    try {
      final v = (premium as dynamic).isPremium;
      return v == true;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<SessionEngine>();
    final premium = context.watch<PremiumService>();

    final realPremium = _isPremiumSafe(premium);
    final isPremium = kDebugMode ? _debugPremiumOverride : realPremium;

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
        actions: [
          if (kDebugMode)
            IconButton(
              tooltip: 'Debug Premium',
              icon: Icon(
                _debugPremiumOverride ? Icons.workspace_premium : Icons.workspace_premium_outlined,
              ),
              onPressed: () async {
                HapticFeedback.selectionClick();
                final prefs = await SharedPreferences.getInstance();
                final next = !_debugPremiumOverride;
                await prefs.setBool(_prefsDebugPremiumKey, next);
                if (!mounted) return;
                setState(() {
                  _debugPremiumOverride = next;
                  _debugLoaded = true;
                });
              },
            ),
          if (kDebugMode && !_debugLoaded)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
            ),
        ],
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
