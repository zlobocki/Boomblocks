import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../systems/legal_acceptance.dart';
import '../theme/app_strings.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

/// First-launch gate: user must accept Terms before using the game.
class TermsAcceptScreen extends StatefulWidget {
  const TermsAcceptScreen({super.key});

  @override
  State<TermsAcceptScreen> createState() => _TermsAcceptScreenState();
}

class _TermsAcceptScreenState extends State<TermsAcceptScreen> {
  String? _termsText;
  String? _privacyText;
  bool _showPrivacy = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadDocs();
  }

  Future<void> _loadDocs() async {
    final terms = await rootBundle.loadString('assets/legal/terms_of_use.md');
    final privacy =
        await rootBundle.loadString('assets/legal/privacy_policy.md');
    if (!mounted) return;
    setState(() {
      _termsText = terms;
      _privacyText = privacy;
    });
  }

  Future<void> _agree() async {
    if (_busy) return;
    setState(() => _busy = true);
    await LegalAcceptance.accept();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = _showPrivacy ? _privacyText : _termsText;
    return Scaffold(
      backgroundColor: BoomColors.skyBottom,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [BoomColors.skyTop, BoomColors.skyBottom],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppStrings.appName,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.fredoka(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: BoomColors.gold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _showPrivacy ? 'Privacy Policy' : 'Terms of Use',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: BoomColors.cream.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: BoomColors.hud.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: BoomColors.frameGold.withValues(alpha: 0.4),
                      ),
                    ),
                    child: body == null
                        ? const Center(child: CircularProgressIndicator())
                        : SingleChildScrollView(
                            child: SelectableText(
                              body,
                              style: GoogleFonts.nunito(
                                fontSize: 13.5,
                                height: 1.45,
                                fontWeight: FontWeight.w600,
                                color: BoomColors.cream.withValues(alpha: 0.92),
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Please read and accept the Terms to continue. '
                  'You can also review the Privacy Policy.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: BoomColors.dust.withValues(alpha: 0.95),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            setState(() => _showPrivacy = !_showPrivacy),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: BoomColors.cream,
                          side: BorderSide(
                            color: BoomColors.frameGold.withValues(alpha: 0.6),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          _showPrivacy ? 'Show Terms' : 'Privacy Policy',
                          style: GoogleFonts.nunito(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: body == null || _busy ? null : _agree,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFC45C26),
                          foregroundColor: BoomColors.cream,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          'I agree',
                          style: GoogleFonts.nunito(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Online copies:\n'
                  '${LegalAcceptance.termsUrl}\n'
                  '${LegalAcceptance.privacyUrl}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    height: 1.35,
                    color: BoomColors.dust.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
