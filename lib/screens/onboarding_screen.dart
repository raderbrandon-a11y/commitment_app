// lib/screens/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app.dart';

import '../theme/app_theme.dart';


class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static const String seenKey = 'seenOnboarding';

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;

  Color get navy => AppTheme.navy;
  Color get coral => AppTheme.coral;
  Color get gold => AppTheme.gold;

  Future<void> _hapticTap() async {
    await HapticFeedback.selectionClick();
  }

  Future<void> _complete() async {
    await _hapticTap();
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(OnboardingScreen.seenKey, true);

  if (!mounted) return;
  Navigator.of(context).pushReplacement(
    MaterialPageRoute(builder: (_) => const AppRoot()),
  );
  }

  Future<void> _skip() async => _complete();

  Future<void> _next() async {
    await _hapticTap();
    if (_page >= _pages.length - 1) {
      await _complete();
      return;
    }
    await _pageController.nextPage(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() => _page = index);
  }

  List<_OnboardPageData> get _pages => <_OnboardPageData>[
        _OnboardPageData(
          eyebrow: 'Finish It',
          title: 'Close loops.\nUnlock momentum.',
          body:
              'Pick one thing. Give it a short timer.\nFinish with an honest outcome.',
          icon: Icons.check_circle_outline,
        ),
        _OnboardPageData(
          eyebrow: 'How it works',
          title: 'Task → Duration → Focus',
          body:
              'Set a simple commitment, then stay with it until the timer ends.',
          icon: Icons.timer_outlined,
        ),
        _OnboardPageData(
          eyebrow: 'Outcomes',
          title: 'Progress counts—even imperfect progress.',
          body:
              'Completed, Partially Completed, or Barely Started.\nNo shame. Just data.',
          icon: Icons.insights_outlined,
        ),
      ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _pages.length - 1;

    return Scaffold(
      backgroundColor: navy,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _skip,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white.withOpacity(0.85),
                      textStyle: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    child: const Text('Skip'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  children: _pages
                      .map(
                        (p) => _OnboardPage(
                          data: p,
                          navy: navy,
                          coral: coral,
                          gold: gold,
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _Dots(
                    count: _pages.length,
                    index: _page,
                    active: gold,
                    inactive: Colors.white.withOpacity(0.25),
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isLast ? coral : gold,
                        foregroundColor: navy,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(isLast ? 'Start' : 'Next'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardPageData {
  final String eyebrow;
  final String title;
  final String body;
  final IconData icon;

  _OnboardPageData({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.icon,
  });
}

class _OnboardPage extends StatelessWidget {
  const _OnboardPage({
    required this.data,
    required this.navy,
    required this.coral,
    required this.gold,
  });

  final _OnboardPageData data;
  final Color navy;
  final Color coral;
  final Color gold;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.10),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: Colors.white.withOpacity(0.10)),
              ),
              child: Icon(
                data.icon,
                size: 44,
                color: gold,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              data.eyebrow.toUpperCase(),
              style: TextStyle(
                color: Colors.white.withOpacity(0.70),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              data.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w900,
                height: 1.08,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            Text(
              data.body,
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 26),
            Container(
              width: 120,
              height: 6,
              decoration: BoxDecoration(
                color: coral.withOpacity(0.85),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({
    required this.count,
    required this.index,
    required this.active,
    required this.inactive,
  });

  final int count;
  final int index;
  final Color active;
  final Color inactive;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(count, (i) {
        final isActive = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.only(right: 8),
          width: isActive ? 18 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? active : inactive,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}
