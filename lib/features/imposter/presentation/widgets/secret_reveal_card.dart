import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/game_constants.dart';
import '../../../../core/utils/haptic_service.dart';
import '../../../../core/widgets/spy_widgets.dart';
import '../../domain/entities/player_assignment.dart';

/// Press-and-hold dossier. The hold timing matches the original game:
/// the platform long-press timeout starts, then [GameConstants.holdToRevealMs]
/// fills the ring. Imposters never receive the secret word.
class SecretRevealCard extends StatefulWidget {
  const SecretRevealCard({
    super.key,
    required this.playerName,
    required this.assignment,
    required this.isRevealed,
    required this.onReveal,
    required this.haptics,
    this.animationsEnabled = true,
    this.height = 320,
  });

  final String playerName;
  final PlayerAssignment assignment;
  final bool isRevealed;
  final VoidCallback onReveal;
  final HapticService haptics;
  final bool animationsEnabled;
  final double height;

  @override
  State<SecretRevealCard> createState() => _SecretRevealCardState();
}

class _SecretRevealCardState extends State<SecretRevealCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flip;
  double _progress = 0;
  bool _holding = false;
  bool _midDone = false;
  DateTime? _started;

  @override
  void initState() {
    super.initState();
    _flip = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    if (widget.isRevealed) _flip.value = 1;
  }

  @override
  void didUpdateWidget(covariant SecretRevealCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRevealed && !oldWidget.isRevealed) {
      _flip.forward();
    } else if (!widget.isRevealed && oldWidget.isRevealed) {
      _flip.reverse();
      _progress = 0;
      _holding = false;
      _midDone = false;
    }
  }

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  Future<void> _startHold() async {
    if (widget.isRevealed) return;
    setState(() {
      _holding = true;
      _progress = 0;
      _midDone = false;
      _started = DateTime.now();
    });
    await widget.haptics.light();
    _tick();
  }

  void _tick() {
    if (!_holding || !mounted || widget.isRevealed) return;
    final started = _started;
    if (started == null) return;
    final elapsed = DateTime.now().difference(started).inMilliseconds;
    final p = (elapsed / GameConstants.holdToRevealMs).clamp(0.0, 1.0);
    setState(() => _progress = p);
    if (!_midDone && p >= 0.5) {
      _midDone = true;
      widget.haptics.selection();
    }
    if (p >= 1) {
      _complete();
      return;
    }
    Future<void>.delayed(const Duration(milliseconds: 16), _tick);
  }

  Future<void> _complete() async {
    _holding = false;
    await widget.haptics.medium();
    widget.onReveal();
    if (widget.animationsEnabled) {
      await _flip.forward();
    } else {
      _flip.value = 1;
    }
  }

  void _endHold() {
    if (widget.isRevealed) return;
    setState(() {
      _holding = false;
      _progress = 0;
      _midDone = false;
    });
  }

  Future<void> _a11y() async {
    if (widget.isRevealed) return;
    await widget.haptics.medium();
    widget.onReveal();
    if (widget.animationsEnabled) {
      await _flip.forward();
    } else {
      _flip.value = 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final a11y = MediaQuery.maybeOf(context)?.accessibleNavigation == true;
    return Semantics(
      label: widget.isRevealed
          ? 'Secret revealed for ${widget.playerName}'
          : 'Secret card for ${widget.playerName}. Press and hold to reveal.',
      button: true,
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _flip,
            builder: (context, _) {
              final angle = _flip.value * math.pi;
              final showBack = angle >= math.pi / 2;
              final flash = (1 - (angle - math.pi / 2).abs() / (math.pi / 2))
                  .clamp(0.0, 1.0);
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0012)
                  ..rotateY(angle),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    showBack
                        ? Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()..rotateY(math.pi),
                            child: _Face(
                              height: widget.height,
                              child: _Revealed(assignment: widget.assignment),
                            ),
                          )
                        : GestureDetector(
                            onLongPressStart: (_) => _startHold(),
                            onLongPressEnd: (_) => _endHold(),
                            onLongPressCancel: _endHold,
                            child: _Face(
                              height: widget.height,
                              child: _Hidden(pressed: _holding),
                            ),
                          ),
                    if (_progress > 0 && !showBack)
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: CircularProgressIndicator(
                          value: _progress,
                          strokeWidth: 8,
                          strokeCap: StrokeCap.round,
                          color: AppColors.primary,
                          backgroundColor: AppColors.ink.withValues(
                            alpha: 0.12,
                          ),
                        ),
                      ),
                    if (widget.animationsEnabled && flash > 0.15)
                      IgnorePointer(
                        child: Container(
                          height: widget.height,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppRadii.md),
                            color: AppColors.primary.withValues(
                              alpha: 0.28 * flash,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          if (a11y && !widget.isRevealed) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: _a11y,
              child: const Text('Tap to reveal (accessibility)'),
            ),
          ],
        ],
      ),
    );
  }
}

class _Face extends StatelessWidget {
  const _Face({required this.child, required this.height});

  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: const Color(0xFFE4D3AC), width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x73000000),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.md - 1),
          child: Stack(
            fit: StackFit.expand,
            children: [
              const CustomPaint(painter: _DossierLinesPainter()),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleTag extends StatelessWidget {
  const _RoleTag({required this.imposter});

  final bool imposter;

  @override
  Widget build(BuildContext context) {
    return ClassifiedStamp(
      text: imposter ? 'IMPOSTER' : 'CIVILIAN',
      color: imposter ? AppColors.imposter : AppColors.civilian,
      filled: true,
    );
  }
}

class _DossierLinesPainter extends CustomPainter {
  const _DossierLinesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.ink.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    for (var y = 28.0; y < size.height; y += 22) {
      canvas.drawLine(Offset(16, y), Offset(size.width - 16, y), paint);
    }
  }

  @override
  bool shouldRepaint(_DossierLinesPainter oldDelegate) => false;
}

class _Hidden extends StatelessWidget {
  const _Hidden({required this.pressed});

  final bool pressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.topRight,
            child: ClassifiedStamp(text: 'TOP SECRET', filled: true),
          ),
          const Spacer(),
          AnimatedScale(
            scale: pressed ? 0.94 : 1,
            duration: const Duration(milliseconds: 120),
            child: Text(
              '?',
              style: AppTextStyles.display(AppColors.primary, size: 92)
                  .copyWith(
                    shadows: [
                      Shadow(
                        color: AppColors.primary.withValues(alpha: 0.45),
                        blurRadius: 18,
                      ),
                    ],
                  ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'CLASSIFIED DOSSIER',
            textAlign: TextAlign.center,
            style: AppTextStyles.dossier(AppColors.ink, size: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'PRESS & HOLD\nTO OPEN',
            textAlign: TextAlign.center,
            style: AppTextStyles.display(AppColors.ink, size: 22),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _Revealed extends StatelessWidget {
  const _Revealed({required this.assignment});

  final PlayerAssignment assignment;

  @override
  Widget build(BuildContext context) {
    final imposter = assignment.isImposter;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: imposter ? 1.35 : 1, end: 1),
              duration: Duration(milliseconds: imposter ? 200 : 1),
              curve: Curves.easeOut,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: _RoleTag(imposter: imposter),
            ),
          ),
          const Spacer(),
          Text(
            imposter ? 'YOU DON\'T KNOW THE WORD' : 'SECRET WORD',
            textAlign: TextAlign.center,
            style: AppTextStyles.dossier(AppColors.ink, size: 15),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              imposter ? 'IMPOSTER' : (assignment.word ?? ''),
              textAlign: TextAlign.center,
              style: AppTextStyles.display(
                imposter ? AppColors.imposter : AppColors.accent,
                size: imposter ? 32 : 36,
              ),
            ),
          ),
          if (imposter && assignment.hint != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.ink.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.7),
                ),
              ),
              child: Column(
                children: [
                  Text('HINT', style: AppTextStyles.dossier(AppColors.accent)),
                  const SizedBox(height: 4),
                  Text(
                    assignment.hint!,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.title(AppColors.ink),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            imposter ? 'Blend in. Do not peek.' : 'Remember the word.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body(AppColors.ink),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
