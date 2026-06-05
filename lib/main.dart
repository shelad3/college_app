import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_shell.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState()..initMockData(),
      child: const CollegeApp(),
    ),
  );
}

class CollegeApp extends StatelessWidget {
  const CollegeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'College Portal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: Consumer<AppState>(
        builder: (context, appState, _) {
          if (appState.currentUser == null) {
            return const LoginScreen();
          }
          return const DashboardShell();
        },
      ),
    );
  }
}
