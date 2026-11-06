import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/game_constants.dart';
import '../../../../core/utils/haptic_service.dart';
import '../../../../core/widgets/spy_widgets.dart';
import '../../../../services/ads/ads_service.dart';
import '../../../../services/ads/banner_ad_slot.dart';
import '../../domain/enums/app_theme_mode.dart';
import '../../domain/enums/difficulty.dart';
import '../../domain/enums/game_phase.dart';
import '../providers/game_controller.dart';
import '../providers/game_session.dart';
import '../widgets/classified_plaque.dart';
import '../widgets/neon_widgets.dart';
import '../widgets/secret_reveal_card.dart';

const _sceneSize = Size(1090, 2260);

class GameFlowScreen extends ConsumerStatefulWidget {
  const GameFlowScreen({super.key});

  @override
  ConsumerState<GameFlowScreen> createState() => _GameFlowScreenState();
}

class _GameFlowScreenState extends ConsumerState<GameFlowScreen>
    with WidgetsBindingObserver {
  final _nameController = TextEditingController();
  String? _nameError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nameController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      ref.read(gameControllerProvider.notifier).onAppObscured();
    }
  }

  Future<void> _confirmExit() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave this mission?'),
        content: const Text(
          'The dossiers for this round are already assigned.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('KEEP PLAYING'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('EXIT ROUND'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) {
      ref.read(gameControllerProvider.notifier).exitRound();
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(gameControllerProvider);
    final ctrl = ref.read(gameControllerProvider.notifier);

    return PopScope(
      canPop: !session.phase.isRevealFlow,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop && session.phase.isRevealFlow) {
          await _confirmExit();
        }
      },
      // These screens draw their own full-bleed artwork, so they skip the
      // padded scaffold.
      child:
          session.phase == GamePhase.home ||
              session.phase == GamePhase.playerSetup ||
              session.phase == GamePhase.configuration ||
              session.phase == GamePhase.settings ||
              session.phase.isRevealFlow ||
              session.phase == GamePhase.allRevealed ||
              session.phase == GamePhase.roundReady
          ? _buildBody(session, ctrl)
          : SpyScaffold(child: _buildBody(session, ctrl)),
    );
  }

  Widget _buildBody(GameSession session, GameController ctrl) {
    final body = _phaseBody(session, ctrl);
    // Home menu and the between-rounds screen only. Reveal phases, including
    // pass-the-phone and the secret card, never get a banner.
    if (!session.phase.showsBanner) return body;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: body),
        const BannerAdSlot(),
      ],
    );
  }

  Widget _phaseBody(GameSession session, GameController ctrl) {
    switch (session.phase) {
      case GamePhase.splash:
        return const Center(child: CircularProgressIndicator());
      case GamePhase.home:
        return _HomeView(
          onStart: ctrl.startPlayerSetup,
          onSettings: ctrl.openSettings,
          onHowTo: ctrl.openHowToPlay,
        );
      case GamePhase.howToPlay:
        return _HowToPlayView(onBack: ctrl.goHome);
      case GamePhase.playerSetup:
        return _PlayerSetupView(
          session: session,
          nameController: _nameController,
          nameError: _nameError,
          onChanged: () => setState(() => _nameError = null),
          onAdd: () {
            final err = ctrl.addPlayer(_nameController.text);
            setState(() => _nameError = err);
            if (err == null) _nameController.clear();
          },
          onRemove: ctrl.removePlayer,
          onContinue: ctrl.goToConfiguration,
          onBack: ctrl.goHome,
        );
      case GamePhase.configuration:
        return _ConfigurationView(session: session, ctrl: ctrl);
      case GamePhase.passPhone:
      case GamePhase.readyToReveal:
      case GamePhase.revealing:
      case GamePhase.revealed:
        return _RevealView(session: session, ctrl: ctrl);
      case GamePhase.allRevealed:
        return _AllRevealedView(onContinue: ctrl.showRoundReady);
      case GamePhase.roundReady:
        return _RoundReadyView(
          session: session,
          onNext: ctrl.startNextRound,
          onHome: ctrl.goHome,
        );
      case GamePhase.settings:
        return _SettingsView(session: session, ctrl: ctrl);
      case GamePhase.error:
        return _ErrorView(
          message: session.errorMessage,
          onRetry: ctrl.bootstrap,
        );
    }
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView({
    required this.onStart,
    required this.onSettings,
    required this.onHowTo,
  });

  final VoidCallback onStart;
  final VoidCallback onSettings;
  final VoidCallback onHowTo;

  static const _background = 'assets/images/home_background.webp';

  /// Rows of artwork above the moon, painted over to plain night sky so the
  /// title can be drawn in code below the status bar.
  static const _skyBand = 300.0;

  /// Bottom edge of the folders in the artwork.
  static const _foldersBottom = 1185.0;

  /// Same colour as the top of the artwork, so the gap above it is seamless.
  static const _sky = Color(0xFF070916);

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: _sky,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final scale = math.max(
            constraints.maxWidth / _sceneSize.width,
            constraints.maxHeight / _sceneSize.height,
          );
          final titleTop = topInset + 12;
          final titleBottom = titleTop + SpyGameTitle.height;
          // Push the art down so the moon sits just under the title. On short
          // screens give up to 24px of that back so the folders clear the
          // buttons.
          final wanted = titleBottom + 6 - _skyBand * scale;
          final bottomInset = MediaQuery.paddingOf(context).bottom;
          final buttonsTop = constraints.maxHeight - bottomInset - 24 - 142;
          final fitsAbove = buttonsTop - 8 - _foldersBottom * scale;
          final imageTop = math.max(
            0.0,
            math.max(wanted - 24, math.min(wanted, fitsAbove)),
          );
          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                top: imageTop,
                left: 0,
                right: 0,
                height: _sceneSize.height * scale,
                child: const _SceneImage(_background),
              ),
              Positioned(
                top: titleTop,
                left: 16,
                right: 16,
                child: const SpyGameTitle(),
              ),
              Positioned(
                top: topInset + 8,
                right: 14,
                child: NeonCircleButton(
                  icon: Icons.settings_rounded,
                  tooltip: 'Settings',
                  size: 48,
                  onPressed: onSettings,
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SpyButton(
                        label: 'PLAY',
                        icon: Icons.play_arrow_rounded,
                        style: SpyButtonStyle.gold,
                        height: 64,
                        fontSize: 28,
                        onPressed: onStart,
                      ),
                      const SizedBox(height: 18),
                      SpyButton(
                        label: 'HOW TO PLAY',
                        icon: Icons.menu_book_rounded,
                        style: SpyButtonStyle.neonOutline,
                        height: 60,
                        fontSize: 22,
                        onPressed: onHowTo,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HowToPlayView extends StatelessWidget {
  const _HowToPlayView({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    const steps = [
      (
        'BRIEF THE TEAM',
        'Add 3 to 20 agent names. The imposter is never Agent 1 or Agent 2.',
      ),
      (
        'OPEN THE DOSSIERS',
        'Pass the phone. Everyone else sees the secret word. The imposter does not.',
      ),
      (
        'FIND THE IMPOSTER',
        'Talk and vote outside the app, then start another mission.',
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: SpyIconButton(
            icon: Icons.arrow_back_rounded,
            tooltip: 'Back',
            onPressed: onBack,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView(
            children: [
              DossierCard(
                tabLabel: 'CASE FILE',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'HOW TO PLAY',
                      style: AppTextStyles.dossier(AppColors.accent, size: 18),
                    ),
                    for (var i = 0; i < steps.length; i++) ...[
                      const SizedBox(height: 14),
                      const _DashedRule(),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${i + 1}',
                            style: AppTextStyles.number(
                              AppColors.accent,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  steps[i].$1,
                                  style: AppTextStyles.dossier(
                                    AppColors.textPrimary,
                                    size: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  steps[i].$2,
                                  style: AppTextStyles.body(
                                    AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SpyButton(label: 'GOT IT', onPressed: onBack),
      ],
    );
  }
}

class _PlayerSetupView extends StatelessWidget {
  const _PlayerSetupView({
    required this.session,
    required this.nameController,
    required this.nameError,
    required this.onChanged,
    required this.onAdd,
    required this.onRemove,
    required this.onContinue,
    required this.onBack,
  });

  final GameSession session;
  final TextEditingController nameController;
  final String? nameError;
  final VoidCallback onChanged;
  final VoidCallback onAdd;
  final void Function(String id) onRemove;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  static const _avatarColors = [
    AppColors.primary,
    AppColors.accent,
    AppColors.civilian,
    Color(0xFF8EB4FF),
    AppColors.imposter,
    AppColors.paper,
  ];

  static const _background = 'assets/images/players_background.webp';
  static const _artSize = Size(940, 1672);

  /// Top of the moon and the rooftop railing, in artwork pixels.
  static const _moonTop = 223.0;
  static const _railing = 680.0;

  /// Colour of the artwork's top edge, used above it when it is pushed down.
  static const _sky = Color(0xFF000927);
  static const _signHeight = 76.0;

  @override
  Widget build(BuildContext context) {
    final players = session.players;
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;
    final keyboardOpen = keyboard > 0;

    return Scaffold(
      backgroundColor: _sky,
      resizeToAvoidBottomInset: false,
      body: LayoutBuilder(
        builder: (context, c) {
          final scale = math.max(
            c.maxWidth / _artSize.width,
            c.maxHeight / _artSize.height,
          );
          final signTop = media.padding.top + 10;
          final signBottom = signTop + _signHeight;
          // Push the art down so the moon shows below the sign.
          final imageTop = math.max(0.0, signBottom + 12 - _moonTop * scale);
          final bottomPad = keyboardOpen
              ? keyboard + 12
              : media.padding.bottom + 16;
          // Badge sits on the railing, but never so low that the agent list
          // gets less than ~150px on a short screen.
          final badgeTop = keyboardOpen
              ? signBottom + 14
              : math.max(
                  signBottom + 14,
                  math.min(
                    imageTop + _railing * scale - 8,
                    c.maxHeight - bottomPad - 410,
                  ),
                );
          const signLeft = 80.0;
          const signRight = 16.0;

          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                top: imageTop,
                left: 0,
                right: 0,
                height: _artSize.height * scale,
                child: Image.asset(
                  _background,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  excludeFromSemantics: true,
                  errorBuilder: (_, _, _) =>
                      const ColoredBox(color: AppColors.night),
                ),
              ),
              // Chains run from the top edge of the screen down to the sign.
              Positioned(
                top: 0,
                left: signLeft + 30,
                child: HangingChain(length: signTop + 8),
              ),
              Positioned(
                top: 0,
                right: signRight + 30,
                child: HangingChain(length: signTop + 8),
              ),
              Positioned(
                top: signTop,
                left: signLeft,
                right: signRight,
                child: const NeonSign('WHO\'S PLAYING?', height: _signHeight),
              ),
              Positioned(
                top: signTop + (_signHeight - 52) / 2,
                left: 16,
                child: NeonCircleButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: 'Back',
                  onPressed: onBack,
                ),
              ),
              Positioned(
                top: badgeTop,
                left: 24,
                right: 24,
                bottom: bottomPad,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: GoldBadge(
                        icon: Icons.groups_rounded,
                        label: GameConstants.bestWithLabel,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _NameInput(
                      controller: nameController,
                      error: nameError,
                      onChanged: onChanged,
                      onAdd: onAdd,
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: players.isEmpty
                          ? const _DashedNote()
                          : ListView.separated(
                              padding: const EdgeInsets.only(bottom: 8),
                              itemCount: players.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, i) {
                                final p = players[i];
                                return _AgentTile(
                                  initials: p.initials,
                                  position: p.position,
                                  name: p.name,
                                  color:
                                      _avatarColors[i % _avatarColors.length],
                                  onRemove: () => onRemove(p.id),
                                );
                              },
                            ),
                    ),
                    if (!keyboardOpen) ...[
                      const SizedBox(height: 12),
                      Center(
                        child: CreamPill(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.groups_rounded,
                                size: 22,
                                color: AppColors.ink,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '${players.length} / '
                                '${GameConstants.maxPlayers} agents',
                                style: AppTextStyles.label(
                                  AppColors.ink,
                                ).copyWith(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SpyButton(
                        label: 'NEXT',
                        icon: Icons.arrow_forward_rounded,
                        height: 60,
                        fontSize: 20,
                        onPressed: players.length >= GameConstants.minPlayers
                            ? onContinue
                            : null,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Full-bleed scene. Content starts below [artBottom] image pixels so a
/// baked-in sign stays visible and cards sit on the dark floor.
class _SceneScaffold extends StatelessWidget {
  const _SceneScaffold({
    required this.image,
    required this.artBottom,
    required this.reserve,
    this.onBack,
    required this.children,
  });

  final String image;
  final double artBottom;

  /// Minimum vertical space kept for [children], so a tall sign never
  /// pushes the cards off a short screen.
  final double reserve;
  final VoidCallback? onBack;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;
    final scale = math.max(
      media.size.width / _sceneSize.width,
      media.size.height / _sceneSize.height,
    );
    final available =
        media.size.height - media.padding.vertical - keyboard - 16;
    final rawTop = artBottom * scale + 8 - media.padding.top;
    final cappedTop = math.max(
      onBack == null ? 0.0 : 56.0,
      available - reserve,
    );
    final contentTop = math.min(
      math.max(rawTop, onBack == null ? 0.0 : 56.0),
      cappedTop,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _SceneImage(image),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + keyboard),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: keyboard > 0 && onBack != null ? 56 : contentTop,
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: onBack == null
                          ? null
                          : Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: SpyIconButton(
                                icon: Icons.arrow_back_rounded,
                                tooltip: 'Back',
                                onPressed: onBack!,
                              ),
                            ),
                    ),
                  ),
                  ...children,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SceneImage extends StatelessWidget {
  const _SceneImage(this.asset);

  final String asset;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      excludeFromSemantics: true,
      errorBuilder: (_, _, _) => const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.night, AppColors.background],
          ),
        ),
      ),
    );
  }
}

class _DashedRule extends StatelessWidget {
  const _DashedRule();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 1,
      child: CustomPaint(
        painter: DashedRoundedBorderPainter(
          color: AppColors.cardBorder,
          radius: 0,
          inset: 0,
        ),
      ),
    );
  }
}

class _DashedNote extends StatelessWidget {
  const _DashedNote();

  @override
  Widget build(BuildContext context) {
    final base = AppTextStyles.body(
      AppColors.textPrimary,
    ).copyWith(fontSize: 17);
    return Align(
      alignment: Alignment.topCenter,
      child: CustomPaint(
        painter: const DashedRoundedBorderPainter(
          color: AppColors.primary,
          radius: 18,
          inset: 1,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            color: const Color(0xB3060C1C),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.person_add_alt_1_rounded,
                color: AppColors.primary,
                size: 28,
              ),
              const SizedBox(width: 14),
              Flexible(
                child: Text.rich(
                  TextSpan(
                    style: base,
                    children: [
                      const TextSpan(text: 'Add at least '),
                      TextSpan(
                        text: '${GameConstants.minPlayers} agents',
                        style: base.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const TextSpan(text: ' to start.'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NameInput extends StatelessWidget {
  const _NameInput({
    required this.controller,
    required this.error,
    required this.onChanged,
    required this.onAdd,
  });

  final TextEditingController controller;
  final String? error;
  final VoidCallback onChanged;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 62,
          padding: const EdgeInsets.fromLTRB(18, 0, 6, 0),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: Border.all(
              color: error != null
                  ? AppColors.imposter
                  : const Color(0xFF9FE9FF),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: (error != null ? AppColors.imposter : AppColors.primary)
                    .withValues(alpha: 0.45),
                blurRadius: 16,
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.person_outline_rounded,
                color: AppColors.ink,
                size: 30,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: (_) => onChanged(),
                  textInputAction: TextInputAction.done,
                  textCapitalization: TextCapitalization.words,
                  onSubmitted: (_) => onAdd(),
                  maxLength: GameConstants.maxNameLength,
                  style: AppTextStyles.title(AppColors.ink),
                  cursorColor: AppColors.primary,
                  decoration: InputDecoration(
                    hintText: 'Agent name',
                    hintStyle: AppTextStyles.title(
                      AppColors.ink.withValues(alpha: 0.35),
                    ),
                    counterText: '',
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              Container(
                width: 1.5,
                height: 34,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                color: AppColors.ink.withValues(alpha: 0.18),
              ),
              Semantics(
                button: true,
                label: 'Add agent',
                child: Material(
                  color: AppColors.primary,
                  shape: const CircleBorder(),
                  shadowColor: AppColors.primary,
                  elevation: 6,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onAdd,
                    child: const SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(
                        Icons.add_rounded,
                        color: AppColors.buttonInk,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Center(
              child: CreamPill(
                child: Text(
                  error!,
                  style: AppTextStyles.label(AppColors.imposter),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AgentTile extends StatelessWidget {
  const _AgentTile({
    required this.initials,
    required this.position,
    required this.name,
    required this.color,
    required this.onRemove,
  });

  final String initials;
  final int position;
  final String name;
  final Color color;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.cardBorder, width: 1.5),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: color,
            child: Text(
              initials,
              style: AppTextStyles.label(AppColors.buttonInk),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            position.toString().padLeft(2, '0'),
            style: AppTextStyles.number(AppColors.accent, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: AppTextStyles.title(AppColors.textPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            tooltip: 'Remove $name',
            onPressed: onRemove,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            icon: const Icon(
              Icons.close_rounded,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfigurationView extends StatelessWidget {
  const _ConfigurationView({required this.session, required this.ctrl});

  final GameSession session;
  final GameController ctrl;

  @override
  Widget build(BuildContext context) {
    final settings = session.settings;
    final playerCount = session.players.length;
    final maxImp = GameConstants.maxImpostersFor(playerCount);
    final count = settings.imposterCount;

    return _SceneScaffold(
      image: 'assets/images/ready_background.webp',
      artBottom: 640,
      reserve: 420,
      onBack: ctrl.editPlayers,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: CreamPill(
                    child: Text(
                      'DIFFICULTY',
                      style: AppTextStyles.dossier(AppColors.ink, size: 13),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final d in Difficulty.values) ...[
                      if (d != Difficulty.values.first)
                        const SizedBox(width: 8),
                      Expanded(
                        child: _DifficultyPill(
                          difficulty: d,
                          selected: settings.difficulty == d,
                          onTap: () => ctrl.setDifficulty(d),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                _StepperCard(
                  title: 'Imposters',
                  subtitle: 'Maximum for $playerCount agents: $maxImp',
                  value: count,
                  onMinus: count > 1
                      ? () => ctrl.setImposterCount(count - 1)
                      : null,
                  onPlus: count < maxImp
                      ? () => ctrl.setImposterCount(count + 1)
                      : null,
                ),
                const SizedBox(height: 12),
                DossierCard(
                  onTap: () => ctrl.setShowHint(!settings.showHint),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hint for the imposter',
                              style: AppTextStyles.title(AppColors.textPrimary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'A tiny clue. Never the word itself.',
                              style: AppTextStyles.body(
                                AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: settings.showHint,
                        onChanged: ctrl.setShowHint,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SpyButton(
          label: 'EDIT AGENTS',
          icon: Icons.groups_rounded,
          style: SpyButtonStyle.secondary,
          onPressed: ctrl.editPlayers,
        ),
        const SizedBox(height: 10),
        SpyButton(
          label: 'START MISSION',
          icon: Icons.play_arrow_rounded,
          onPressed: ctrl.startRound,
        ),
      ],
    );
  }
}

class _DifficultyPill extends StatelessWidget {
  const _DifficultyPill({
    required this.difficulty,
    required this.selected,
    required this.onTap,
  });

  final Difficulty difficulty;
  final bool selected;
  final VoidCallback onTap;

  String get _label => switch (difficulty) {
    Difficulty.easy => 'Easy',
    Difficulty.medium => 'Medium',
    Difficulty.hard => 'Hard',
  };

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$_label difficulty',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          height: 48,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.accent : AppColors.cardRaised,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.cardBorder,
              width: 1.5,
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _label,
              maxLines: 1,
              style: AppTextStyles.label(
                selected ? AppColors.buttonInk : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepperCard extends StatelessWidget {
  const _StepperCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  final String title;
  final String subtitle;
  final int value;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  @override
  Widget build(BuildContext context) {
    return DossierCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.title(AppColors.textPrimary),
                ),
              ),
              _StepButton(icon: Icons.remove_rounded, onPressed: onMinus),
              SizedBox(
                width: 36,
                child: Text(
                  '$value',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.number(AppColors.accent),
                ),
              ),
              _StepButton(icon: Icons.add_rounded, onPressed: onPlus),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: AppTextStyles.body(AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(
          side: BorderSide(color: AppColors.primary, width: 2),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
        ),
      ),
    );
  }
}

class _RevealView extends StatelessWidget {
  const _RevealView({required this.session, required this.ctrl});

  final GameSession session;
  final GameController ctrl;

  /// Whether the "pass the phone" hand-off screen is showing, rather than the
  /// secret card.
  static bool showsPassPhone(GameSession session) =>
      session.phase.isRevealFlow &&
      session.currentPlayer != null &&
      (session.privacyLocked || session.phase == GamePhase.passPhone);

  @override
  Widget build(BuildContext context) {
    final player = session.currentPlayer;
    if (player == null) return const SizedBox.shrink();
    final haptics = HapticService(enabled: session.settings.hapticEnabled);

    if (showsPassPhone(session)) {
      return _PassPhoneView(
        playerId: player.id,
        playerName: player.name,
        privacyLocked: session.privacyLocked,
        animate: session.settings.animationsEnabled,
        onReady: session.privacyLocked
            ? ctrl.unlockPrivacy
            : ctrl.confirmReadyToReveal,
      );
    }

    final assignment = session.currentAssignment;
    if (assignment == null) return const SizedBox.shrink();
    final revealed = session.isCardRevealed;

    return _SceneScaffold(
      image: 'assets/images/your_turn_background.webp',
      artBottom: 520,
      reserve: 500,
      children: [
        ClassifiedPlaque(
          subtitle: 'YOUR TURN',
          title: player.name.toUpperCase(),
        ),
        const SizedBox(height: 10),
        Center(
          child: CreamPill(
            child: Text(
              revealed ? 'Keep this secret' : 'Hold to reveal',
              style: AppTextStyles.label(AppColors.ink),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) {
              final w = math.min(
                box.maxWidth * 0.86,
                (box.maxHeight - 8) / 1.25,
              );
              return Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: w,
                  child: SecretRevealCard(
                    playerName: player.name,
                    assignment: assignment,
                    isRevealed: revealed,
                    onReveal: ctrl.revealCurrentPlayer,
                    haptics: haptics,
                    animationsEnabled: session.settings.animationsEnabled,
                    height: w * 1.25,
                  ),
                ),
              );
            },
          ),
        ),
        if (revealed) ...[
          const SizedBox(height: 10),
          SpyButton(
            label: session.isLastPlayer ? 'SEAL THE FILE' : 'HIDE AND PASS',
            icon: session.isLastPlayer
                ? Icons.verified_rounded
                : Icons.arrow_forward_rounded,
            onPressed: session.isLastPlayer
                ? ctrl.finishRevealPhase
                : ctrl.passToNextPlayer,
          ),
        ],
      ],
    );
  }
}

class _PassPhoneView extends StatelessWidget {
  const _PassPhoneView({
    required this.playerId,
    required this.playerName,
    required this.privacyLocked,
    required this.animate,
    required this.onReady,
  });

  final String playerId;
  final String playerName;
  final bool privacyLocked;
  final bool animate;
  final VoidCallback onReady;

  @override
  Widget build(BuildContext context) {
    Widget card = DossierCard(
      tabLabel: 'HAND-OFF',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            privacyLocked ? 'Screen hidden. Dossier sealed.' : 'Pass to',
            textAlign: TextAlign.center,
            style: AppTextStyles.dossier(AppColors.textSecondary, size: 14),
          ),
          const SizedBox(height: 8),
          const CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.cardRaised,
            child: Icon(
              Icons.person_rounded,
              color: AppColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'Agent ${playerName.toUpperCase()}',
              maxLines: 1,
              style: AppTextStyles.display(AppColors.accent, size: 28),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            privacyLocked ? "Don't peek. Hand it back." : "Don't peek!",
            textAlign: TextAlign.center,
            style: AppTextStyles.body(AppColors.textPrimary),
          ),
        ],
      ),
    );
    if (animate) {
      // Scale only. A fade-in starts at opacity 0, which hides the name
      // until the animation finishes.
      card = card
          .animate(key: ValueKey(playerId))
          .scale(
            begin: const Offset(0.96, 0.96),
            duration: 200.ms,
            curve: Curves.easeOut,
          );
    }

    return _SceneScaffold(
      image: 'assets/images/pass_phone_background.webp',
      artBottom: 980,
      reserve: 340,
      children: [
        Expanded(
          child: Align(alignment: const Alignment(0, -0.15), child: card),
        ),
        SpyButton(label: "I'M ${playerName.toUpperCase()}", onPressed: onReady),
      ],
    );
  }
}

class _AllRevealedView extends StatelessWidget {
  const _AllRevealedView({required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return _SceneScaffold(
      image: 'assets/images/your_turn_background.webp',
      artBottom: 640,
      reserve: 340,
      children: [
        const ClassifiedPlaque(subtitle: 'CASE FILE', title: 'DOSSIERS SEALED'),
        const SizedBox(height: 16),
        const DossierCard(
          child: Text(
            'Everyone has seen their role.\nTime to find the imposter.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.4,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const Spacer(),
        SpyButton(
          label: 'START THE ROUND',
          icon: Icons.arrow_forward_rounded,
          onPressed: onContinue,
        ),
      ],
    );
  }
}

class _RoundReadyView extends StatelessWidget {
  const _RoundReadyView({
    required this.session,
    required this.onNext,
    required this.onHome,
  });

  final GameSession session;
  final VoidCallback onNext;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final starter = session.startingPlayer;
    final name = starter?.name ?? '?';
    return _SceneScaffold(
      image: 'assets/images/round_background.webp',
      artBottom: 640,
      reserve: 420,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const ClassifiedPlaque(
                  subtitle: 'MISSION LIVE',
                  title: 'THE ROUND BEGINS',
                ),
                const SizedBox(height: 14),
                DossierCard(
                  tabLabel: 'FIRST SPEAKER',
                  child: Column(
                    children: [
                      Text(
                        'Agent ${name.toUpperCase()}',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.display(
                          AppColors.accent,
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'speaks first',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body(AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const DossierCard(
                  child: Text(
                    'Give clues. Listen carefully. Find the imposter.\n'
                    'Put the phone down and start talking.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SpyButton(label: 'PLAY AGAIN', onPressed: onNext),
        const SizedBox(height: 10),
        SpyButton(
          label: 'HOME',
          style: SpyButtonStyle.secondary,
          onPressed: onHome,
        ),
      ],
    );
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView({required this.session, required this.ctrl});

  final GameSession session;
  final GameController ctrl;

  static const _background = 'assets/images/settings_background.webp';

  static IconData _themeIcon(AppThemeMode m) => switch (m) {
    AppThemeMode.system => Icons.brightness_auto_outlined,
    AppThemeMode.light => Icons.light_mode_outlined,
    AppThemeMode.dark => Icons.dark_mode_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final s = session.settings;
    const divider = Divider(
      height: 1,
      thickness: 1,
      indent: 16,
      endIndent: 16,
      color: Color(0x553D5A90),
    );
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Anchored to the bottom so the magnifier and the folder stay in
          // view.
          Image.asset(
            _background,
            fit: BoxFit.cover,
            alignment: Alignment.bottomCenter,
            excludeFromSemantics: true,
            errorBuilder: (_, _, _) => const ColoredBox(color: AppColors.night),
          ),
          // Darken the sky and skyline behind the controls.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xE6050C1E),
                  Color(0xD9061128),
                  Color(0x99061128),
                  Color(0x33061128),
                ],
                stops: [0, 0.5, 0.75, 0.9],
              ),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                SizedBox(
                  height: 116,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: 0,
                        right: 120,
                        top: 18,
                        child: Row(
                          children: [
                            NeonCircleButton(
                              icon: Icons.arrow_back_rounded,
                              tooltip: 'Back',
                              onPressed: ctrl.goHome,
                            ),
                            const SizedBox(width: 16),
                            const Flexible(child: BrushTitle('SETTINGS')),
                          ],
                        ),
                      ),
                      const Positioned(top: 10, right: 0, child: SpyPolaroid()),
                    ],
                  ),
                ),
                const SectionRibbon(
                  icon: Icons.settings_rounded,
                  label: 'APPEARANCE',
                ),
                const SizedBox(height: 12),
                NeonPanel(
                  child: Row(
                    children: [
                      for (final m in AppThemeMode.values) ...[
                        if (m != AppThemeMode.values.first)
                          const SizedBox(width: 10),
                        Expanded(
                          child: ChoicePill(
                            label: m.label,
                            icon: _themeIcon(m),
                            selected: s.themeMode == m,
                            onTap: () => ctrl.setThemeMode(m),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const SectionRibbon(
                  icon: Icons.sports_esports_rounded,
                  label: 'GAMEPLAY',
                ),
                const SizedBox(height: 12),
                NeonPanel(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Material(
                    type: MaterialType.transparency,
                    child: Column(
                      children: [
                        NeonToggleRow(
                          icon: Icons.vibration_rounded,
                          label: 'Haptic feedback',
                          value: s.hapticEnabled,
                          onChanged: ctrl.setHapticEnabled,
                        ),
                        divider,
                        NeonToggleRow(
                          icon: Icons.play_arrow_outlined,
                          label: 'Animations',
                          value: s.animationsEnabled,
                          onChanged: ctrl.setAnimationsEnabled,
                        ),
                        divider,
                        NeonToggleRow(
                          icon: Icons.volume_up_rounded,
                          label: 'Sound effects',
                          value: s.soundEnabled,
                          onChanged: ctrl.setSoundEnabled,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const _AdPrivacySection(),
                SpyButton(
                  label: 'RESET SETTINGS',
                  icon: Icons.refresh_rounded,
                  style: SpyButtonStyle.neonOutline,
                  height: 60,
                  fontSize: 20,
                  onPressed: ctrl.resetSettings,
                ),
                const SizedBox(height: 16),
                SpyButton(
                  label: 'HOW TO PLAY',
                  icon: Icons.menu_book_outlined,
                  style: SpyButtonStyle.neonOutline,
                  height: 60,
                  fontSize: 20,
                  onPressed: ctrl.openHowToPlay,
                ),
                const SizedBox(height: 20),
                Text(
                  'Spy Imposter Game  ·  1.0.0',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.label(AppColors.textSecondary).copyWith(
                    fontSize: 15,
                    shadows: const [Shadow(color: Colors.black, blurRadius: 6)],
                  ),
                ),
                // Room to scroll the magnifier and folder into view.
                const SizedBox(height: 200),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown only when UMP requires a privacy-options entry point.
class _AdPrivacySection extends ConsumerStatefulWidget {
  const _AdPrivacySection();

  @override
  ConsumerState<_AdPrivacySection> createState() => _AdPrivacySectionState();
}

class _AdPrivacySectionState extends ConsumerState<_AdPrivacySection> {
  late final Future<bool> _required;

  @override
  void initState() {
    super.initState();
    _required = ref.read(adsServiceProvider).privacyOptionsRequired;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _required,
      builder: (context, snapshot) {
        if (snapshot.data != true) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionRibbon(icon: Icons.privacy_tip_outlined, label: 'ADS'),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                ref.read(adsServiceProvider).showPrivacyOptions();
              },
              child: NeonPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ad privacy choices',
                      style: AppTextStyles.title(AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage how ads are personalized',
                      style: AppTextStyles.body(AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(),
        const ClassifiedStamp(text: 'ERROR', filled: true),
        const SizedBox(height: 16),
        Text(
          message ?? 'Something went wrong loading the word pack.',
          textAlign: TextAlign.center,
          style: AppTextStyles.title(AppColors.textPrimary),
        ),
        const Spacer(),
        SpyButton(label: 'TRY AGAIN', onPressed: onRetry),
      ],
    );
  }
}
