import 'package:flutter_test/flutter_test.dart';
import 'package:ssc_study_hub/main.dart';

void main() {
  testWidgets('SSC Study Hub App loads successfully',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SSCStudyHubApp());
    expect(find.byType(SSCStudyHubApp), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 1));
  });
}
