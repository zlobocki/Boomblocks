import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'systems/audio_settings.dart';
import 'systems/music_service.dart';
import 'theme/app_theme.dart';
import 'theme/tile_texture.dart';
import 'ui/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Fonts ship in assets/google_fonts/ — never fetch over the network.
  GoogleFonts.config.allowRuntimeFetching = false;
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await AudioSettings.load();
  // Don't block first paint on 21 tile decodes; painters fall back until
  // textures are ready.
  unawaited(TileTexture.load());
  runApp(const BoomBlocksApp());
}

class BoomBlocksApp extends StatefulWidget {
  const BoomBlocksApp({super.key});

  @override
  State<BoomBlocksApp> createState() => _BoomBlocksAppState();
}

class _BoomBlocksAppState extends State<BoomBlocksApp>
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
      title: 'BoomBlocks',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const HomeScreen(),
    );
  }
}
