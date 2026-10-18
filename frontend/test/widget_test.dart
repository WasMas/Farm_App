import 'package:fieldbook/app.dart';
import 'package:fieldbook/core/session_store.dart';
import 'package:flutter/material.dart';

import 'support/memory_tokens.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Unauthenticated users see a validated sign in form', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [tokenStoreProvider.overrideWithValue(MemoryTokens())],
        child: const FieldbookApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Back to the land.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('auth-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Enter a username'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
