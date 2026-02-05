import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'state/session_engine.dart';
import 'services/clock.dart';
import 'services/prefs_storage_service.dart';
import 'services/premium_service.dart';

// Screens
import 'screens/home_screen.dart';
import 'screens/task_screen.dart';
import 'screens/duration_screen.dart';
import 'screens/confirm_screen.dart';
import 'screens/running_screen.dart';
import 'screens/outcome_screen.dart';
import 'screens/results_screen.dart';
import 'screens/history_screen.dart';

class FinishItApp extends StatelessWidget {
  const FinishItApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Locked palette + ADHD canvas
    const offWhite = Color(0xFFF7F7F4);
    const navy = Color(0xFF161526);

    final theme = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: offWhite,
      appBarTheme: const AppBarTheme(
        backgroundColor: offWhite,
        foregroundColor: navy,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: navy,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      // Global primary button style = "Completed" button style (navy + white)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: navy,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0x14000000), width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SessionEngine>(
          create: (_) {
            final engine = SessionEngine(
              storage: PrefsStorageService(),
              clock: Clock(),
            );
            engine.init();
            return engine;
          },
        ),
        ChangeNotifierProvider<PremiumService>(
          create: (_) {
            final s = PremiumService();
            s.init();
            return s;
          },
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Finish It',
        theme: theme,
        home: const AppRoot(),
      ),
    );
  }
}

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<SessionEngine>();

    switch (engine.flow) {
      case FlowState.idle:
        return const HomeScreen();
      case FlowState.draftTask:
        return const TaskScreen();
      case FlowState.draftDuration:
        return const DurationScreen();
      case FlowState.confirm:
        return const ConfirmScreen();
      case FlowState.running:
        return const RunningScreen();
      case FlowState.needsOutcome:
        return const OutcomeScreen();
      case FlowState.results:
        return const ResultsScreen();
      case FlowState.history:
        return const HistoryScreen();
    }
  }
}
