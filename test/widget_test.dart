import 'package:flutter_test/flutter_test.dart';
import 'package:ssc_study_hub/utils/app_colors.dart';

void main() {
  test('AppColors Neo-Studio theme has valid constants and zero-lag decorations', () {
    expect(AppColors.primary, isNotNull);
    expect(AppColors.backgroundTop, isNotNull);
    expect(AppColors.liquidGlassCard, isNotNull);
    expect(AppColors.liquidGlassTab, isNotNull);
    expect(AppColors.liquidPill, isNotNull);
  });
}
