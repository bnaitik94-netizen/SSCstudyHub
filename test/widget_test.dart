import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ssc_study_hub/utils/app_colors.dart';

void main() {
  group('SSC Study Hub Liquid Theme Tests', () {
    test('AppColors palette tokens are properly defined', () {
      expect(AppColors.primary, const Color(0xFF6366F1));
      expect(AppColors.accent, const Color(0xFF38BDF8));
      expect(AppColors.liveRed, const Color(0xFFFF2A4B));
      expect(AppColors.textPrimary, const Color(0xFFFFFFFF));
    });

    test('Liquid Glass decorations are correctly configured', () {
      expect(AppColors.liquidGlassCard, isNotNull);
      expect(AppColors.liquidGlassTab, isNotNull);
      expect(AppColors.liquidPill, isNotNull);
    });

    testWidgets('Liquid Theme renders preview widget without crashing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              decoration: AppColors.liquidGlassCard,
              child: const Text('Liquid Theme Preview', style: TextStyle(color: AppColors.textPrimary)),
            ),
          ),
        ),
      );

      expect(find.text('Liquid Theme Preview'), findsOneWidget);
    });
  });
}
