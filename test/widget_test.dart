import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_incident_reporting_app/app/app.dart';
import 'package:campus_incident_reporting_app/core/constants/app_strings.dart';
import 'package:campus_incident_reporting_app/shared/widgets/brand_logo.dart';
import 'package:campus_incident_reporting_app/shared/widgets/status_badge.dart';

void main() {
  testWidgets('Initial application shell renders branding and status tokens',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: CampusCareApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.appTagline), findsOneWidget);
    expect(find.byType(BrandLogo), findsNWidgets(2));
    expect(find.byType(StatusBadge), findsNWidgets(5));
    expect(find.text('Foundation Initialized'), findsOneWidget);
  });
}

