import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../services/premium_service.dart';

class PremiumPaywallSheet extends StatelessWidget {
  const PremiumPaywallSheet({super.key});

  Package? _bestPackage(Offerings? offerings) {
    final current = offerings?.current;
    final pkgs = current?.availablePackages ?? <Package>[];
    if (pkgs.isEmpty) return null;

    // Prefer monthly, then annual, then first available.
    for (final p in pkgs) {
      final id = p.identifier.toLowerCase();
      if (id.contains('month')) return p;
    }
    for (final p in pkgs) {
      final id = p.identifier.toLowerCase();
      if (id.contains('year') || id.contains('annual')) return p;
    }
    return pkgs.first;
  }

  String _priceLabel(Package? pkg) {
    final price = pkg?.storeProduct.priceString;
    if (price == null || price.isEmpty) return '';
    return price;
  }

  @override
  Widget build(BuildContext context) {
    final premium = context.watch<PremiumService>();
    final scheme = Theme.of(context).colorScheme;

    final pkg = _bestPackage(premium.offerings);
    final price = _priceLabel(pkg);

    final busy = premium.isBusy;
    final error = premium.lastError;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Unlock Premium',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Get more momentum with unlimited sessions and deeper insights.',
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),
            const _BenefitRow(text: 'Unlimited sessions/day (Free is capped at 3/day)'),
            const SizedBox(height: 10),
            const _BenefitRow(text: 'Full history (Free shows last 3)'),
            const SizedBox(height: 10),
            const _BenefitRow(text: 'Premium insights (streaks, averages, totals)'),
            const SizedBox(height: 10),
            const _BenefitRow(text: 'Tag sessions with categories'),
            const SizedBox(height: 10),
            const _BenefitRow(text: 'Category analytics'),
            const SizedBox(height: 14),

            if (error != null && error.trim().isNotEmpty) ...[
              Text(
                error,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 10),
            ],

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: busy
                    ? null
                    : () async {
                        HapticFeedback.mediumImpact();

                        // If offerings are missing, try a reload first.
                        if (premium.offerings == null) {
                          await premium.reload();
                        }

                        final chosen = _bestPackage(premium.offerings);
                        if (chosen == null) {
                          // Still no packages — do nothing; error will show via lastError if any.
                          return;
                        }

                        await premium.purchasePackage(chosen);
                      },
                child: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(price.isEmpty ? 'Go Premium' : 'Go Premium • $price'),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      Navigator.pop(context);
                    },
                    child: const Text('Not now'),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: busy
                        ? null
                        : () async {
                            HapticFeedback.selectionClick();
                            await premium.restore();
                          },
                    child: const Text('Restore'),
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
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
