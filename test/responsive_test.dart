import 'package:boomblocks/theme/responsive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('detects tablets by shortest side', () {
    expect(BoomLayout.isTablet(const Size(390, 844)), isFalse);
    expect(BoomLayout.isTablet(const Size(800, 1280)), isTrue);
    expect(BoomLayout.isTablet(const Size(1280, 800)), isTrue);
  });

  test('wide game layout engages in landscape-like viewports', () {
    expect(BoomLayout.useWideGameLayout(const Size(390, 844)), isFalse);
    expect(BoomLayout.useWideGameLayout(const Size(1024, 768)), isTrue);
    expect(BoomLayout.useWideGameLayout(const Size(800, 360)), isTrue);
  });

  test('portrait board grows on tablets and stays capped on phones', () {
    final phone = BoomLayout.portraitBoardOuter(const Size(390, 844));
    final tablet = BoomLayout.portraitBoardOuter(const Size(800, 1280));
    expect(phone, lessThanOrEqualTo(420));
    expect(tablet, greaterThan(420));
    expect(tablet, lessThanOrEqualTo(680));
  });
}
