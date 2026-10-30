import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ssc_study_hub/core/theme/app_colors.dart';
import 'package:ssc_study_hub/core/theme/app_spacing.dart';
import 'package:ssc_study_hub/core/theme/app_theme.dart';
import 'package:ssc_study_hub/core/widgets/app_widgets.dart';

void main() {
  group('Core Theme System Tests', () {
    test('AppColors tokens are properly initialized with dark-first studio palette', () {
      expect(AppColors.seedColor, const Color(0xFF6366F1));
      expect(AppColors.primaryAccent, const Color(0xFF6366F1));
      expect(AppColors.backgroundDark, const Color(0xFF0A0A0F));
      expect(AppColors.surfaceDark, const Color(0xFF13131A));
      expect(AppColors.surfaceVariantDark, const Color(0xFF1C1C28));
      expect(AppColors.textPrimaryDark, const Color(0xFFF0F0F5));
      expect(AppColors.textSecondaryDark, const Color(0xFF8A8A9A));
      expect(AppColors.success, const Color(0xFF2ECC87));
      expect(AppColors.error, const Color(0xFFFF4D6A));
    });

    test('AppSpacing 4pt base grid and radii are properly configured', () {
      expect(AppSpacing.xs, 4.0);
      expect(AppSpacing.sm, 8.0);
      expect(AppSpacing.md, 16.0);
      expect(AppSpacing.lg, 24.0);
      expect(AppSpacing.xl, 32.0);
      expect(AppSpacing.xxl, 48.0);
      expect(AppSpacing.xxxl, 64.0);
      expect(AppSpacing.radiusSm, 8.0);
      expect(AppSpacing.radiusMd, 12.0);
      expect(AppSpacing.radiusLg, 16.0);
      expect(AppSpacing.radiusXl, 24.0);
      expect(AppSpacing.radiusPill, 999.0);
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
          theme: AppTheme.dark(useGoogleFonts: false),
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

    testWidgets('AppCard.primary and listItem render correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(useGoogleFonts: false),
          home: const Scaffold(
            body: Column(
              children: [
                AppCard.primary(child: Text('Primary Card')),
                AppCard.listItem(child: Text('List Item Card')),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Primary Card'), findsOneWidget);
      expect(find.text('List Item Card'), findsOneWidget);
    });

    testWidgets('AppButton variants render labels and handle taps', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(useGoogleFonts: false),
          home: Scaffold(
            body: Column(
              children: [
                AppButton.primaryCta(
                  label: 'Primary CTA',
                  onPressed: () => tapped = true,
                ),
                AppButton.filled(
                  label: 'Filled Button',
                  onPressed: () {},
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

      expect(find.text('Primary CTA'), findsOneWidget);
      expect(find.text('Filled Button'), findsOneWidget);
      expect(find.text('Outlined Button'), findsOneWidget);
      expect(find.text('Text Button'), findsOneWidget);

      await tester.tap(find.text('Primary CTA'));
      expect(tapped, isTrue);
    });

    testWidgets('AppBadge renders with semantic label and variant color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(useGoogleFonts: false),
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

    testWidgets('AppEmptyState renders visual, title, and action', (tester) async {
      bool actionTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(useGoogleFonts: false),
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

    testWidgets('AppFloatingIslandNav renders destinations and responds to taps', (tester) async {
      int tappedIndex = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(useGoogleFonts: false),
          home: Scaffold(
            bottomNavigationBar: AppFloatingIslandNav(
              selectedIndex: 0,
              onDestinationSelected: (idx) => tappedIndex = idx,
              destinations: const [
                AppNavDestination(
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home_rounded,
                  label: 'Home',
                ),
                AppNavDestination(
                  icon: Icons.menu_book_outlined,
                  selectedIcon: Icons.menu_book_rounded,
                  label: 'Study',
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Study'), findsOneWidget);

      await tester.tap(find.text('Study'));
      expect(tappedIndex, 1);
    });
  });
}
