import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ptirecycle/main.dart';
import 'package:ptirecycle/providers/auth_provider.dart';
import 'package:ptirecycle/providers/parking_provider.dart';

void main() {
  testWidgets('SiParku app launches and shows splash screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => ParkingProvider()),
        ],
        child: const SiParkuApp(),
      ),
    );

    // Verify splash screen elements appear
    expect(find.text('SiParku'), findsOneWidget);
    expect(find.text('Parkir Cerdas, Tanpa Ribet'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}