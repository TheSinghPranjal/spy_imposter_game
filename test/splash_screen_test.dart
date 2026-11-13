import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spy_imposter_game/app/app.dart';
import 'package:spy_imposter_game/app/theme/app_theme.dart';
import 'package:spy_imposter_game/core/constants/game_constants.dart';
import 'package:spy_imposter_game/features/imposter/presentation/screens/game_flow_screen.dart';
import 'package:spy_imposter_game/features/imposter/presentation/screens/splash_screen.dart';
import 'package:spy_imposter_game/features/imposter/presentation/widgets/neon_widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('splash shows the game name and studio byline, then the game', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: SpyImposterGameApp()));

    expect(find.byType(SpyGameTitle), findsOneWidget);
    expect(find.text('by'), findsOneWidget);
    expect(find.text('The Lazy Bear Club'), findsOneWidget);
    expect(find.byKey(SplashScreen.iconKey), findsOneWidget);

    await tester.pump(
      const Duration(milliseconds: GameConstants.splashDurationMs),
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('The Lazy Bear Club'), findsNothing);
    expect(find.byType(GameFlowScreen), findsOneWidget);
  });

  testWidgets('byline fits safe areas, small phones, tablets, and text scale', (
    tester,
  ) async {
    const sizes = <Size>[
      Size(320, 568),
      Size(360, 640),
      Size(390, 844),
      Size(667, 375),
      Size(768, 1024),
      Size(1024, 768),
    ];
    const themes = <ThemeData Function()>[AppTheme.light, AppTheme.dark];

    for (final theme in themes) {
      for (final size in sizes) {
        await _pumpSplash(tester, theme: theme(), size: size);
        expect(tester.takeException(), isNull);
        expect(find.text('by'), findsOneWidget);
        expect(find.text('The Lazy Bear Club'), findsOneWidget);
        expect(find.byType(SpyGameTitle), findsOneWidget);
      }
      await _pumpSplash(
        tester,
        theme: theme(),
        size: const Size(320, 568),
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('The Lazy Bear Club'), findsOneWidget);
    }
  });
}

Future<void> _pumpSplash(
  WidgetTester tester, {
  required ThemeData theme,
  required Size size,
  double textScale = 1,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  tester.view.padding = const FakeViewPadding(
    top: 47,
    bottom: 34,
    left: 0,
    right: 0,
  );
  tester.view.viewPadding = const FakeViewPadding(
    top: 47,
    bottom: 34,
    left: 0,
    right: 0,
  );
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPadding);
  addTearDown(tester.view.resetViewPadding);

  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      builder: (context, child) {
        final data = MediaQuery.of(context);
        return MediaQuery(
          data: data.copyWith(textScaler: TextScaler.linear(textScale)),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: SplashScreen(onFinished: () {}),
    ),
  );
  await tester.pump();
}
