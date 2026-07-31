import 'package:boomblocks/main.dart';
import 'package:boomblocks/theme/app_strings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Mine Puzzle home shows play CTA', (tester) async {
    await tester.pumpWidget(const MinePuzzleApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Play'), findsOneWidget);
    expect(find.text('Top 10'), findsOneWidget);
    expect(find.text(AppStrings.tagline), findsOneWidget);
    expect(find.text(AppStrings.appName), findsWidgets);
  });
}
