import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/premium_service.dart';

class PremiumPaywallSheet extends StatelessWidget {
  const PremiumPaywallSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final premium = context.watch<PremiumService>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            const Text(
              'Finish It Premium',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Unlock all premium features with a one-time purchase.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            const _BenefitRow(text: 'Unlimited sessions per day'),
            const _BenefitRow(text: 'Category tags & analytics'),
            const _BenefitRow(text: 'Full history & insights'),
            const _BenefitRow(text: 'Future premium features included'),
            const SizedBox(height: 24),

            // ✅ iOS text clipping fix: give the button more height + line height
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: premium.isBusy || premium.offerings?.current == null
                    ? null
                    : () async {
                        HapticFeedback.lightImpact();

                        final package = premium
                            .offerings!.current!.availablePackages.first;

                        await premium.purchasePackage(package);

                        if (!context.mounted) return;

                        if (premium.isPremium) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Premium unlocked.')),
                          );
                        }
                      },
                child: premium.isBusy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Unlock Premium',
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 12),

            TextButton(
              onPressed: premium.isBusy
                  ? null
                  : () async {
                      HapticFeedback.selectionClick();
                      await premium.restore();

                      if (!context.mounted) return;

                      if (premium.isPremium) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Premium restored.')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('No previous purchases found to restore.'),
                          ),
                        );
                      }
                    },
              child: const Text(
                'Restore purchases',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),

            const SizedBox(height: 8),

            TextButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                Navigator.pop(context);
              },
              child: const Text('Not now'),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.check, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
