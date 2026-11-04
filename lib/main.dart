import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/constants/ad_config.dart';
import 'features/imposter/data/repositories/settings_repository.dart';
import 'features/imposter/presentation/providers/game_controller.dart';
import 'services/ads/ads_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Bundled under the SIL Open Font License. The license files ship with them.
  LicenseRegistry.addLicense(() async* {
    final nunito = await rootBundle.loadString('assets/fonts/OFL-Nunito.txt');
    final stencil = await rootBundle.loadString(
      'assets/fonts/OFL-StardosStencil.txt',
    );
    final courier = await rootBundle.loadString(
      'assets/fonts/OFL-CourierPrime.txt',
    );
    final oswald = await rootBundle.loadString('assets/fonts/OFL-Oswald.txt');
    yield LicenseEntryWithLineBreaks(['Nunito'], nunito);
    yield LicenseEntryWithLineBreaks(['Stardos Stencil'], stencil);
    yield LicenseEntryWithLineBreaks(['Courier Prime'], courier);
    yield LicenseEntryWithLineBreaks(['Oswald'], oswald);
  });
  await AdConfig.load();
  final ads = AdConfig.adsSupported
      ? MobileAdsService(isTestMode: AdConfig.isTestMode)
      : FakeAdsService();
  // UMP runs inside initialize(). Mobile Ads still starts when consent is
  // not required or the check fails, and stays off only when consent was
  // required and not granted.
  await ads.initialize();

  final prefs = await SharedPreferences.getInstance();
  final settingsRepo = SettingsRepository(prefs);

  final container = ProviderContainer(
    overrides: [
      settingsRepositoryProvider.overrideWithValue(settingsRepo),
      adsServiceProvider.overrideWithValue(ads),
    ],
  );

  await container.read(gameControllerProvider.notifier).bootstrap();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const SpyImposterGameApp(),
    ),
  );
}
