import 'package:boomblocks/systems/legal_acceptance.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('accept persists terms version', () async {
    SharedPreferences.setMockInitialValues({});
    await LegalAcceptance.load();
    expect(LegalAcceptance.accepted, isFalse);
    await LegalAcceptance.accept();
    expect(LegalAcceptance.accepted, isTrue);

    LegalAcceptance.accepted = false;
    await LegalAcceptance.load();
    expect(LegalAcceptance.accepted, isTrue);
  });
}
