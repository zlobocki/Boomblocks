import 'package:boomblocks/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('BoomBlocks home shows brand and play', (tester) async {
    await tester.pumpWidget(const BoomBlocksApp());
    // Home uses a repeating bob animation — avoid pumpAndSettle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('BoomBlocks'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);
    expect(find.text('Top 10'), findsOneWidget);
  });
}
