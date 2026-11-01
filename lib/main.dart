import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';
import 'screens/home.dart';
import 'store.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));
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
    return ListenableBuilder(
      listenable: AppStore.I,
      builder: (context, _) {
        final fikra = AppStore.I.mode == 'fikra';
        return MaterialApp(
          title: 'Injaz',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(fikra ? FikraColors.warm500 : InjazColors.primary),
          home: const HomeScreen(),
        );
      },
    );
  }
}
