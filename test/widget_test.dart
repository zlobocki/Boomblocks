import 'package:boomblocks/main.dart';
import 'package:boomblocks/systems/legal_acceptance.dart';
import 'package:boomblocks/theme/app_strings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpBoot(WidgetTester tester) async {
    await tester.pumpWidget(const MinePuzzleApp());
    await tester.pump(); // BootScreen starts
    await tester.pump(); // after LegalAcceptance.load
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('Mine Puzzle home shows play CTA after terms accepted',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      LegalAcceptance.prefsKey: LegalAcceptance.termsVersion,
    });
    await LegalAcceptance.load();

    await pumpBoot(tester);
    expect(find.text('Play'), findsOneWidget);
    expect(find.text('Top 10'), findsOneWidget);
    expect(find.text(AppStrings.tagline), findsOneWidget);
    expect(find.text(AppStrings.appName), findsWidgets);
  });

  testWidgets('shows Terms gate when not yet accepted', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await LegalAcceptance.load();
    expect(LegalAcceptance.accepted, isFalse);

    await pumpBoot(tester);
    expect(find.text('I agree'), findsOneWidget);
    expect(find.text('Terms of Use'), findsOneWidget);
    expect(find.text('Play'), findsNothing);
  });
}
