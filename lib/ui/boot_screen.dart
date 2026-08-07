import 'package:flutter/material.dart';

import '../systems/legal_acceptance.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'terms_accept_screen.dart';

/// Loads legal acceptance, then routes to Terms gate or Home.
class BootScreen extends StatefulWidget {
  const BootScreen({super.key});

  @override
  State<BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends State<BootScreen> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await LegalAcceptance.load();
    if (!mounted) return;
    final next = LegalAcceptance.accepted
        ? const HomeScreen()
        : const TermsAcceptScreen();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => next),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: BoomColors.skyBottom,
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
