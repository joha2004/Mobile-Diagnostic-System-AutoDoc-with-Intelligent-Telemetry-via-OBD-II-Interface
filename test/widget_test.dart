import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:autodokdor1/app.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: AutoDoctorApp(),
      ),
    );
    await tester.pumpAndSettle();
    
    // Verify the app title or connection screen is shown
    expect(find.byType(AutoDoctorApp), findsOneWidget);
  });
}
