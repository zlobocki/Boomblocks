import 'package:boomblocks/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('BoomBlocks home shows play CTA', (tester) async {
    await tester.pumpWidget(const BoomBlocksApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Play'), findsOneWidget);
    expect(find.text('Top 10'), findsOneWidget);
    expect(find.text('Clear loot to score points'), findsOneWidget);
    expect(find.text('BoomBlocks'), findsWidgets);
  });
}
