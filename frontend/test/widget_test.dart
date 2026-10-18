import 'package:fieldbook/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Fieldbook renders connection result', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          healthProvider.overrideWith(
            (ref) async => {'status': 'ok', 'database': 'postgresql'},
          ),
        ],
        child: const FieldbookApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Fieldbook'), findsOneWidget);
    expect(find.text('Django + postgresql · ok'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
