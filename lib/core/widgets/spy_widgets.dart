import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Night gradient used by screens that do not have scene art.
class SpyScaffold extends StatelessWidget {
  const SpyScaffold({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 16, 20, 24),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final lifted = Theme.of(context).scaffoldBackgroundColor == AppColors.night;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: lifted
                ? const [AppColors.night, Color(0xFF1C2748), AppColors.card]
                : const [AppColors.background, AppColors.night],
          ),
        ),
        child: SafeArea(
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

enum SpyButtonStyle { primary, secondary, danger, gold, neonOutline }

/// Pill button. Primary is neon cyan, secondary is an outline, danger is red.
/// Gold and neonOutline are the glowing home-menu buttons.
class SpyButton extends StatefulWidget {
  const SpyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.style = SpyButtonStyle.primary,
    this.height = 56,
    this.fontSize = 18,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final SpyButtonStyle style;
  final double height;
  final double fontSize;

  @override
  State<SpyButton> createState() => _SpyButtonState();
}

class _SpyButtonState extends State<SpyButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    if (widget.style == SpyButtonStyle.gold ||
        widget.style == SpyButtonStyle.neonOutline) {
      return _buildNeon(context);
    }
    final enabled = widget.onPressed != null;
    final primary = widget.style == SpyButtonStyle.primary;
    final danger = widget.style == SpyButtonStyle.danger;
    final fill = switch (widget.style) {
      SpyButtonStyle.primary =>
        _pressed ? AppColors.primaryPressed : AppColors.primary,
      // Gold and neonOutline are drawn by _buildNeon and never reach here.
      SpyButtonStyle.secondary ||
      SpyButtonStyle.gold ||
      SpyButtonStyle.neonOutline => Colors.transparent,
      SpyButtonStyle.danger =>
        _pressed ? const Color(0xFFD42032) : AppColors.imposter,
    };
    final fg = widget.style == SpyButtonStyle.secondary
        ? AppColors.primary
        : AppColors.buttonInk;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: GestureDetector(
          onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
          onTap: widget.onPressed,
          child: AnimatedScale(
            scale: _pressed ? 0.97 : 1,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: Container(
              height: 56,
              width: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(AppRadii.pill),
                border: Border.all(
                  color: widget.style == SpyButtonStyle.secondary
                      ? AppColors.primary
                      : Colors.white.withValues(
                          alpha: primary || danger ? 0.55 : 0,
                        ),
                  width: widget.style == SpyButtonStyle.secondary ? 2 : 0,
                ),
                boxShadow: enabled && widget.style != SpyButtonStyle.secondary
                    ? [
                        BoxShadow(
                          color:
                              (danger ? AppColors.imposter : AppColors.primary)
                                  .withValues(alpha: 0.45),
                          blurRadius: 18,
                        ),
                      ]
                    : null,
              ),
              foregroundDecoration: widget.style == SpyButtonStyle.secondary
                  ? null
                  : BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withValues(alpha: 0.45),
                          width: 2,
                        ),
                      ),
                    ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, size: 22, color: fg),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        widget.label,
                        maxLines: 1,
                        style: AppTextStyles.display(
                          fg,
                          size: 18,
                        ).copyWith(letterSpacing: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNeon(BuildContext context) {
    final enabled = widget.onPressed != null;
    final gold = widget.style == SpyButtonStyle.gold;
    final glow = gold ? const Color(0xFFFFB020) : AppColors.primary;
    final fg = gold ? AppColors.buttonInk : AppColors.primary;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: GestureDetector(
          onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
          onTap: widget.onPressed,
          child: AnimatedScale(
            scale: _pressed ? 0.97 : 1,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: Container(
              height: widget.height,
              width: double.infinity,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.pill),
                gradient: gold
                    ? LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: _pressed
                            ? const [Color(0xFFF2C740), Color(0xFFE59A0C)]
                            : const [
                                Color(0xFFFFE27A),
                                Color(0xFFFFC52E),
                                Color(0xFFF5A10F),
                              ],
                      )
                    : null,
                color: gold ? null : const Color(0xE6081226),
                border: Border.all(
                  color: gold ? const Color(0xFFFFE9A8) : AppColors.primary,
                  width: gold ? 1.5 : 2.5,
                ),
                boxShadow: enabled
                    ? [
                        BoxShadow(
                          color: glow.withValues(alpha: gold ? 0.6 : 0.5),
                          blurRadius: 22,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, size: widget.fontSize * 1.5, color: fg),
                    const SizedBox(width: 12),
                  ],
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        widget.label,
                        maxLines: 1,
                        style: TextStyle(
                          fontFamily: AppFonts.body,
                          fontWeight: FontWeight.w900,
                          fontSize: widget.fontSize,
                          letterSpacing: 0.6,
                          color: fg,
                          shadows: gold
                              ? null
                              : [Shadow(color: glow, blurRadius: 10)],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Night card. Optional cream folder tab on the top left.
class DossierCard extends StatelessWidget {
  const DossierCard({
    super.key,
    required this.child,
    this.tabLabel,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.onTap,
  });

  final Widget child;
  final String? tabLabel;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.cardBorder, width: 1.5),
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
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 10,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.08),
                      Colors.white.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                padding.left,
                padding.top + (tabLabel == null ? 0 : 10),
                padding.right,
                padding.bottom,
              ),
              child: child,
            ),
          ],
        ),
      ),
    );

    final body = tabLabel == null
        ? card
        : Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(padding: const EdgeInsets.only(top: 14), child: card),
              Positioned(
                left: 16,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(8),
                    ),
                  ),
                  child: Text(
                    tabLabel!,
                    style: AppTextStyles.dossier(AppColors.ink, size: 12),
                  ),
                ),
              ),
            ],
          );

    if (onTap == null) return body;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: body,
    );
  }
}

/// Cream label that stays readable on the night artwork.
class CreamPill extends StatelessWidget {
  const CreamPill({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.paper.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        boxShadow: const [
          BoxShadow(
            color: Color(0x59000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Rotated stencil stamp. Used for REDACTED, CLASSIFIED, and IMPOSTER.
class ClassifiedStamp extends StatelessWidget {
  const ClassifiedStamp({
    super.key,
    required this.text,
    this.color = AppColors.imposter,
    this.angle = -0.105,
    this.filled = false,
  });

  final String text;
  final Color color;
  final double angle;

  /// Filled stamps use dark text so the mark stays readable on cream paper.
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final ink = filled ? AppColors.buttonInk : color;
    return Opacity(
      opacity: 0.92,
      child: Transform.rotate(
        angle: angle,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: filled ? color : Colors.transparent,
            border: Border.all(
              color: filled ? AppColors.buttonInk : color,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              border: Border.all(
                color: filled ? AppColors.buttonInk : color,
                width: 1,
              ),
            ),
            child: Text(
              text,
              style: AppTextStyles.display(
                ink,
                size: 16,
              ).copyWith(letterSpacing: 1.4),
            ),
          ),
        ),
      ),
    );
  }
}

class DashedRoundedBorderPainter extends CustomPainter {
  const DashedRoundedBorderPainter({
    required this.color,
    required this.radius,
    required this.inset,
  });

  final Color color;
  final double radius;
  final double inset;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(inset),
      Radius.circular(radius),
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    const dash = 7.0, gap = 6.0;
    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += dash + gap) {
        canvas.drawPath(metric.extractPath(d, d + dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(DashedRoundedBorderPainter old) =>
      old.color != color || old.radius != radius || old.inset != inset;
}

/// Round control used for back and settings. At least 48dp.
class SpyIconButton extends StatelessWidget {
  const SpyIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card.withValues(alpha: 0.92),
      shape: const CircleBorder(
        side: BorderSide(color: AppColors.primary, width: 1.5),
      ),
      elevation: 4,
      shadowColor: Colors.black54,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        icon: Icon(icon, color: AppColors.primary),
      ),
    );
  }
}
