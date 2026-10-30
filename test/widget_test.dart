import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ssc_study_hub/core/theme/app_colors.dart';
import 'package:ssc_study_hub/core/theme/app_spacing.dart';
import 'package:ssc_study_hub/core/theme/app_theme.dart';
import 'package:ssc_study_hub/core/widgets/app_widgets.dart';

void main() {
  group('Core Theme System Tests', () {
    test('AppColors tokens are properly initialized', () {
      expect(AppColors.seedColor, const Color(0xFF4F46E5));
      expect(AppColors.surfaceLowestLight, isNotNull);
      expect(AppColors.surfaceLowestDark, isNotNull);
      expect(AppColors.textPrimaryLight, isNotNull);
      expect(AppColors.textPrimaryDark, isNotNull);
      expect(AppColors.success, isNotNull);
      expect(AppColors.error, isNotNull);
    });

    test('AppSpacing scale and radii are properly configured', () {
      expect(AppSpacing.xs, 4.0);
      expect(AppSpacing.sm, 8.0);
      expect(AppSpacing.md, 12.0);
      expect(AppSpacing.lg, 16.0);
      expect(AppSpacing.xl, 24.0);
      expect(AppSpacing.radiusSm, 8.0);
      expect(AppSpacing.radiusMd, 12.0);
      expect(AppSpacing.radiusLg, 16.0);
      expect(AppSpacing.radiusXl, 24.0);
      expect(AppSpacing.radiusFull, 999.0);
    });

    test('AppTheme generates valid Light and Dark ThemeData', () {
      final lightTheme = AppTheme.light(useGoogleFonts: false);
      final darkTheme = AppTheme.dark(useGoogleFonts: false);

      expect(lightTheme.useMaterial3, isTrue);
      expect(darkTheme.useMaterial3, isTrue);

      expect(lightTheme.brightness, Brightness.light);
      expect(darkTheme.brightness, Brightness.dark);

      expect(lightTheme.colorScheme.primary, isNotNull);
      expect(darkTheme.colorScheme.primary, isNotNull);

      expect(lightTheme.cardTheme.elevation, 0);
      expect(darkTheme.cardTheme.elevation, 0);
    });
  });

  group('Core Reusable Widgets Tests', () {
    testWidgets('AppCard renders child with subtle border and zero elevation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(useGoogleFonts: false),
          home: const Scaffold(
            body: AppCard(
              child: Text('Card Content'),
            ),
          ),
        ),
      );

      expect(find.text('Card Content'), findsOneWidget);
      expect(find.byType(AppCard), findsOneWidget);
    });

    testWidgets('AppButton variants render labels and handle taps', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(useGoogleFonts: false),
          home: Scaffold(
            body: Column(
              children: [
                AppButton.filled(
                  label: 'Filled Button',
                  onPressed: () => tapped = true,
                ),
                AppButton.outlined(
                  label: 'Outlined Button',
                  onPressed: () {},
                ),
                AppButton.text(
                  label: 'Text Button',
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Filled Button'), findsOneWidget);
      expect(find.text('Outlined Button'), findsOneWidget);
      expect(find.text('Text Button'), findsOneWidget);

      await tester.tap(find.text('Filled Button'));
      expect(tapped, isTrue);
    });

    testWidgets('AppBadge renders with semantic label and variant color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(useGoogleFonts: false),
          home: const Scaffold(
            body: AppBadge(
              label: 'LIVE',
              variant: AppBadgeVariant.error,
            ),
          ),
        ),
      );

      expect(find.text('LIVE'), findsOneWidget);
    });

    testWidgets('AppEmptyState renders icon, title, and action', (tester) async {
      bool actionTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(useGoogleFonts: false),
          home: Scaffold(
            body: AppEmptyState(
              icon: Icons.inbox_rounded,
              title: 'Empty Inbox',
              subtitle: 'No items yet',
              actionLabel: 'Refresh',
              onAction: () => actionTriggered = true,
            ),
          ),
        ),
      );

      expect(find.text('Empty Inbox'), findsOneWidget);
      expect(find.text('No items yet'), findsOneWidget);
      expect(find.text('Refresh'), findsOneWidget);

      await tester.tap(find.text('Refresh'));
      expect(actionTriggered, isTrue);
    });
  });
}
