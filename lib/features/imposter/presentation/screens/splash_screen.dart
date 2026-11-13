import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/game_constants.dart';
import '../../../../core/widgets/spy_widgets.dart';
import '../widgets/neon_widgets.dart';
import 'game_flow_screen.dart';

/// Holds the branded splash, then reveals the game.
class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  static const _fade = Duration(milliseconds: 350);

  bool _done = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return AnimatedSwitcher(
      duration: reduceMotion ? Duration.zero : _fade,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: _done
          ? const GameFlowScreen(key: ValueKey('game'))
          : SplashScreen(
              key: const ValueKey('splash'),
              onFinished: () {
                if (mounted) setState(() => _done = true);
              },
            ),
    );
  }
}

/// Night splash: the game title, then "by / The Lazy Bear Club".
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  static const iconAsset = 'assets/branding/lazy_bear_club.png';
  static const iconKey = Key('lazy_bear_club_icon');

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(
      const Duration(milliseconds: GameConstants.splashDurationMs),
      () {
        if (mounted) widget.onFinished();
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SpyScaffold(
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Cap the column on tablets so the title stays a title, not a banner.
          final width = math.min(math.max(constraints.maxWidth, 280.0), 560.0);
          return Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: width,
                child: const Padding(
                  padding: EdgeInsets.fromLTRB(28, 12, 28, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SpyGameTitle(),
                      SizedBox(height: 40),
                      _StudioByline(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StudioByline extends StatelessWidget {
  const _StudioByline();

  @override
  Widget build(BuildContext context) {
    final byStyle = AppTextStyles.dossier(
      AppColors.textSecondary,
      size: 15,
    ).copyWith(letterSpacing: 3.6);
    final nameStyle = AppTextStyles.title(
      AppColors.textPrimary,
    ).copyWith(fontSize: 22, fontWeight: FontWeight.w800, height: 1.15);

    return Semantics(
      container: true,
      label: 'by The Lazy Bear Club',
      child: ExcludeSemantics(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('by', textAlign: TextAlign.center, style: byStyle),
              const SizedBox(height: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.45),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        SplashScreen.iconAsset,
                        key: SplashScreen.iconKey,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text('The Lazy Bear Club', style: nameStyle),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
