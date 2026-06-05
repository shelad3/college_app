import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:upgrader/upgrader.dart';
import 'config/supabase_config.dart';
import 'providers/app_state.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );

  final appcastURL =
      'https://raw.githubusercontent.com/${UpdateConfig.repoOwner}/${UpdateConfig.repoName}/main/appcast.xml';
  final upgrader = Upgrader(
    debugLogging: true,
    storeController: UpgraderStoreController(
      onAndroid: () => UpgraderAppcastStore(appcastURL: appcastURL),
      oniOS: () => UpgraderAppcastStore(appcastURL: appcastURL),
    ),
  );

  final appState = AppState()..initMockData();
  final savedUsername = await appState.restoreSession();
  if (savedUsername != null) {
    appState.autoLogin(savedUsername);
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appState),
      ],
      child: CollegeApp(upgrader: upgrader),
    ),
  );
}

class CollegeApp extends StatelessWidget {
  const CollegeApp({super.key, required this.upgrader});

  final Upgrader upgrader;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'College Portal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: UpgradeAlert(
        upgrader: upgrader,
        child: Consumer<AppState>(
          builder: (context, appState, _) {
            if (appState.currentUser == null) {
              return const LoginScreen();
            }
            return const DashboardShell();
          },
        ),
      ),
    );
  }
}
