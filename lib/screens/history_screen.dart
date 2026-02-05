import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/outcomes.dart';
import '../models/session.dart';
import '../services/premium_service.dart';
import '../state/session_engine.dart';
import '../widgets/premium_paywall_sheet.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const String _prefsDebugPremiumKey = 'debug_premium_override';
  bool _debugPremiumOverride = false;
  bool _debugLoaded = false;

  int? _touchedIndex;

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

  void _showPaywall() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const PremiumPaywallSheet(),
    );
  }

  String _prettyOutcome(Outcome? o) {
    if (o == null) return 'Unlogged';
    switch (o) {
      case Outcome.completed:
        return 'Completed';
      case Outcome.partial:
        return 'Partially completed';
      case Outcome.incomplete:
        return 'Barely started';
    }
  }

  IconData _outcomeIcon(Outcome? o) {
    if (o == null) return Icons.help_outline;
    switch (o) {
      case Outcome.completed:
        return Icons.check_circle_outline;
      case Outcome.partial:
        return Icons.remove_circle_outline;
      case Outcome.incomplete:
        return Icons.cancel_outlined;
    }
  }

  Color _outcomeColor(BuildContext context, Outcome? o) {
    final scheme = Theme.of(context).colorScheme;
    if (o == null) return scheme.outline;
    switch (o) {
      case Outcome.completed:
        return const Color(0xFF161526);
      case Outcome.partial:
        return const Color(0xFFF2B749);
      case Outcome.incomplete:
        return const Color(0xFFF28891);
    }
  }

  Future<void> _refreshWithHaptic() async {
    HapticFeedback.selectionClick();
    await context.read<SessionEngine>().refreshHistory();
  }

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<SessionEngine>();
    final premium = context.watch<PremiumService>();

    final realPremium = _isPremiumSafe(premium);
    final isPremium = kDebugMode ? _debugPremiumOverride : realPremium;

    final visibleSessions = engine.visibleHistory(isPremium: isPremium);
    final allSessions = engine.history;

    final sessionsForChart = isPremium ? allSessions : visibleSessions;
    final sessionsForList = visibleSessions;

    int completed = 0;
    int partial = 0;
    int barely = 0;
    int unlogged = 0;

    for (final s in sessionsForChart) {
      final o = s.outcome;
      if (o == null) {
        unlogged++;
      } else if (o == Outcome.completed) {
        completed++;
      } else if (o == Outcome.partial) {
        partial++;
      } else {
        barely++;
      }
    }

    final scheme = Theme.of(context).colorScheme;

    final colors = <Color>[
      const Color(0xFF161526), // completed
      const Color(0xFFF2B749), // partial
      const Color(0xFFF28891), // barely
      scheme.outlineVariant, // unlogged
    ];

    final counts = [completed, partial, barely, unlogged];
    final total = counts.fold<int>(0, (a, b) => a + b);

    String percentLabel(int value) {
      if (total <= 0 || value <= 0) return '';
      final p = (value / total) * 100.0;
      if (p < 5) return '';
      return '${p.toStringAsFixed(0)}%';
    }

    List<PieChartSectionData> buildSections() {
      if (total == 0) return [];
      return List.generate(4, (i) {
        final value = counts[i];
        if (value == 0) return PieChartSectionData(value: 0, showTitle: false);
        final touched = _touchedIndex == i;
        return PieChartSectionData(
          value: value.toDouble(),
          color: colors[i],
          radius: touched ? 62 : 56,
          showTitle: true,
          title: percentLabel(value),
          titleStyle: TextStyle(
            fontSize: touched ? 14 : 12,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
          titlePositionPercentageOffset: 0.62,
        );
      });
    }

    Widget legendRow(String label, int count, Color color) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            Text(
              '$count',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
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
                _debugPremiumOverride
                    ? Icons.workspace_premium
                    : Icons.workspace_premium_outlined,
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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              HapticFeedback.selectionClick();
              await engine.refreshHistory();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshWithHaptic,
        child: ListView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            if (kDebugMode && !_debugLoaded)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    const Icon(Icons.assignment_outlined),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isPremium ? 'Total tasks' : 'Recent tasks (last 3)',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '${isPremium ? allSessions.length : sessionsForList.length}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            if (!isPremium)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_outline),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Premium insights (streaks, averages, totals), category tags, and category analytics are locked on Free.',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _showPaywall,
                        child: const Text('Unlock'),
                      ),
                    ],
                  ),
                ),
              ),

            if (!isPremium) const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Outcomes',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: SizedBox(
                        width: 220,
                        height: 220,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            PieChart(
                              PieChartData(
                                sections: buildSections(),
                                sectionsSpace: 3,
                                centerSpaceRadius: 56,
                                borderData: FlBorderData(show: false),
                                pieTouchData: PieTouchData(
                                  touchCallback: (event, response) {
                                    if (!mounted) return;
                                    final idx = response
                                        ?.touchedSection?.touchedSectionIndex;
                                    if (!event.isInterestedForInteractions ||
                                        idx == null) {
                                      setState(() => _touchedIndex = null);
                                      return;
                                    }
                                    if (_touchedIndex != idx) {
                                      HapticFeedback.selectionClick();
                                    }
                                    setState(() => _touchedIndex = idx);
                                  },
                                ),
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${sessionsForList.length}',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: scheme.primary,
                                  ),
                                ),
                                Text(
                                  'tasks',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (completed > 0) legendRow('Completed', completed, colors[0]),
                    if (partial > 0) legendRow('Partially', partial, colors[1]),
                    if (barely > 0) legendRow('Barely', barely, colors[2]),
                    if (unlogged > 0) legendRow('Unlogged', unlogged, colors[3]),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            if (isPremium) _CategoryAnalyticsCard(sessions: allSessions),

            if (isPremium) const SizedBox(height: 16),

            Text(
              isPremium ? 'All sessions' : 'Recent sessions',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),

            if (sessionsForList.isEmpty)
              const _EmptyHistoryState()
            else
              Card(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sessionsForList.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final s = sessionsForList[i];
                    return ListTile(
                      leading: Icon(
                        _outcomeIcon(s.outcome),
                        color: _outcomeColor(context, s.outcome),
                      ),
                      title: Text(
                        s.task,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        '${s.durationMinutes} min • ${_prettyOutcome(s.outcome)}'
                        '${isPremium && (s.category?.isNotEmpty ?? false) ? ' • ${s.category}' : ''}',
                      ),
                      trailing: s.endedEarly
                          ? const Icon(Icons.timer_off_outlined)
                          : null,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryStats {
  int total = 0;
  int completed = 0;
  int partial = 0;
  int barely = 0;

  void add(Session s) {
    total++;
    final o = s.outcome;
    if (o == Outcome.completed) completed++;
    if (o == Outcome.partial) partial++;
    if (o == Outcome.incomplete) barely++;
  }
}

class _CategoryAnalyticsCard extends StatelessWidget {
  final List<Session> sessions;
  const _CategoryAnalyticsCard({required this.sessions});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final map = <String, _CategoryStats>{};

    for (final s in sessions) {
      final key = (s.category?.trim().isNotEmpty ?? false)
          ? s.category!.trim()
          : 'Uncategorized';

      map.putIfAbsent(key, () => _CategoryStats()).add(s);
    }

    final rows = map.entries.toList()
      ..sort((a, b) => b.value.total.compareTo(a.value.total));

    Widget cell(String text, {bool bold = false, TextAlign align = TextAlign.left}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          text,
          textAlign: align,
          style: TextStyle(
            fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
            color: align == TextAlign.left ? scheme.onSurfaceVariant : scheme.onSurface,
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Category breakdown',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),

            // Header row
            Row(
              children: [
                Expanded(flex: 4, child: cell('Category', bold: true)),
                Expanded(flex: 2, child: cell('Total', bold: true, align: TextAlign.right)),
                Expanded(flex: 2, child: cell('C', bold: true, align: TextAlign.right)),
                Expanded(flex: 2, child: cell('P', bold: true, align: TextAlign.right)),
                Expanded(flex: 2, child: cell('B', bold: true, align: TextAlign.right)),
              ],
            ),
            Divider(height: 1, color: scheme.outlineVariant),
            const SizedBox(height: 2),

            for (final e in rows) ...[
              Row(
                children: [
                  Expanded(flex: 4, child: cell(e.key)),
                  Expanded(flex: 2, child: cell('${e.value.total}', align: TextAlign.right)),
                  Expanded(flex: 2, child: cell('${e.value.completed}', align: TextAlign.right)),
                  Expanded(flex: 2, child: cell('${e.value.partial}', align: TextAlign.right)),
                  Expanded(flex: 2, child: cell('${e.value.barely}', align: TextAlign.right)),
                ],
              ),
              Divider(height: 1, color: scheme.outlineVariant),
            ],

            const SizedBox(height: 6),
            Text(
              'C = Completed, P = Partial, B = Barely started',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHistoryState extends StatelessWidget {
  const _EmptyHistoryState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = scheme.secondary.withAlpha(140);

    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.history_toggle_off, size: 76, color: tint),
            const SizedBox(height: 22),
            Text(
              'No sessions yet',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a task to build your history.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.outline,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 18),
            Text(
              'Pull down to refresh.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.outline,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
