import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'systems/audio_settings.dart';
import 'systems/music_service.dart';
import 'theme/app_strings.dart';
import 'theme/app_theme.dart';
import 'theme/tile_texture.dart';
import 'ui/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Fonts ship in assets/google_fonts/ — never fetch over the network.
  GoogleFonts.config.allowRuntimeFetching = false;
  // Phones stay comfortable in portrait; tablets / foldables may rotate.
  // GameScreen picks a stacked or side-by-side layout from the viewport.
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await AudioSettings.load();
  // Don't block first paint on 21 tile decodes; painters fall back until
  // textures are ready.
  unawaited(TileTexture.load());
  runApp(const MinePuzzleApp());
}

class MinePuzzleApp extends StatefulWidget {
  const MinePuzzleApp({super.key});

  @override
  State<MinePuzzleApp> createState() => _MinePuzzleAppState();
}

class _MinePuzzleAppState extends State<MinePuzzleApp>
    with WidgetsBindingObserver {
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
    switch (state) {
      case AppLifecycleState.resumed:
        MusicService.instance.resume();
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        MusicService.instance.pause();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const HomeScreen(),
    );
  }
}
