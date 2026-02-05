import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/premium_service.dart';
import '../state/session_engine.dart';

class ConfirmScreen extends StatefulWidget {
  const ConfirmScreen({super.key});

  @override
  State<ConfirmScreen> createState() => _ConfirmScreenState();
}

class _ConfirmScreenState extends State<ConfirmScreen> {
  static const String _prefsDebugPremiumKey = 'debug_premium_override';

  bool _debugPremiumOverride = false;
  bool _debugLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadDebugPremiumOverride();
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

  void _showUpsellBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: false,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Daily limit reached',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'Free includes 3 timers per day. Upgrade to Premium for unlimited timers and advanced insights.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              const _BenefitRow(text: 'Unlimited timers per day'),
              const SizedBox(height: 8),
              const _BenefitRow(text: 'Full session history'),
              const SizedBox(height: 8),
              const _BenefitRow(text: 'Streaks, averages, totals'),
              const SizedBox(height: 8),
              const _BenefitRow(text: 'Tag sessions with categories'),
              const SizedBox(height: 8),
              const _BenefitRow(text: 'Category analytics'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        Navigator.of(ctx).pop();
                      },
                      child: const Text('Not now'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        Navigator.of(ctx).pop();
                        // TODO: RevenueCat purchase flow
                      },
                      child: const Text('Upgrade'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<SessionEngine>();
    final premium = context.watch<PremiumService>();

    final realPremium = _isPremiumSafe(premium);
    final isPremium = kDebugMode ? _debugPremiumOverride : realPremium;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            HapticFeedback.selectionClick();
            engine.backToDuration();
          },
        ),
        actions: [
          if (kDebugMode && !_debugLoaded)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    engine.draftTask,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Duration: ${engine.draftDurationMinutes} minutes',
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (isPremium && (engine.draftCategory?.trim().isNotEmpty ?? false)) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Category: ${engine.draftCategory}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  HapticFeedback.lightImpact();

                  await engine.refreshHistory();
                  if (!isPremium && engine.sessionsLoggedToday() >= 3) {
                    _showUpsellBottomSheet(context);
                    return;
                  }

                  engine.startSession(isPremium: isPremium);
                },
                child: const Text('Start'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final String text;
  const _BenefitRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.check_circle_outline, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
