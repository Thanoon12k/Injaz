import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';
import 'screens/home.dart';
import 'screens/welcome.dart';
import 'store.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppStore.I.load();
  try {
    await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseKey)
        .timeout(const Duration(seconds: 8));
    AppStore.I.supabaseReady = true;
  } catch (e) {
    debugPrint('Supabase unavailable, staying offline: $e');
  }
  runApp(const InjazApp());
  AppStore.I.startAutoSync();
}

class InjazApp extends StatefulWidget {
  const InjazApp({super.key});
  @override
  State<InjazApp> createState() => _InjazAppState();
}

class _InjazAppState extends State<InjazApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) AppStore.I.syncNow();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Injaz',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      home: ListenableBuilder(
        listenable: AppStore.I,
        builder: (context, _) {
          final s = AppStore.I;
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: s.signedIn || s.offlineChosen
                ? const HomeScreen(key: ValueKey('home'))
                : const WelcomeScreen(key: ValueKey('welcome')),
          );
        },
      ),
    );
  }
}
