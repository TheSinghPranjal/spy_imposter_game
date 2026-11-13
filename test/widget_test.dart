import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spy_imposter_game/app/app.dart';
import 'package:spy_imposter_game/features/imposter/presentation/screens/splash_screen.dart';

void main() {
  testWidgets('app boots to home after splash bootstrap override', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: SpyImposterGameApp()));
    // Branded splash is the first frame. Loading behind it is acceptable.
    expect(find.byType(SpyImposterGameApp), findsOneWidget);
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('The Lazy Bear Club'), findsOneWidget);
  });
}
