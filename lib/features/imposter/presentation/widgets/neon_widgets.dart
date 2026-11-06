import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

const _silver = [
  Color(0xFFFFFFFF),
  Color(0xFFE4E9F2),
  Color(0xFF8E99AE),
  Color(0xFFEDF1F7),
];
const _gold = [
  Color(0xFFFFF3A6),
  Color(0xFFFFCB2E),
  Color(0xFFF29A0A),
  Color(0xFFFFD75C),
];

/// Home menu title: crosshair emblem, "SPY IMPOSTER GAME" and the tagline.
class SpyGameTitle extends StatelessWidget {
  const SpyGameTitle({super.key});

  /// Fixed height so the home screen can place the artwork under it.
  static const height = 168.0;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: 'Spy Imposter Game. Everyone knows the word. One of you doesn\'t.',
      excludeSemantics: true,
      child: SizedBox(
        height: height,
        child: Column(
          children: [
            const SizedBox(
              height: 56,
              width: double.infinity,
              child: CustomPaint(painter: _EmblemPainter()),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 64,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.skewX(-0.16),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _TitleWord('SPY', _silver),
                      SizedBox(width: 10),
                      _TitleWord('IMPOSTER', _gold),
                      SizedBox(width: 10),
                      _TitleWord('GAME', _silver),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 22,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Everyone knows the word. One of you doesn\'t.',
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.8),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 2,
              width: 200,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0x00FF2A3D),
                    Color(0xFFFF2A3D),
                    Color(0x00FF2A3D),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.imposter.withValues(alpha: 0.7),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TitleWord extends StatelessWidget {
  const _TitleWord(this.text, this.colors);

  final String text;
  final List<Color> colors;

  static const _style = TextStyle(
    fontFamily: AppFonts.numbers,
    fontSize: 60,
    fontWeight: FontWeight.w600,
    height: 1,
    letterSpacing: -0.5,
  );

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dark outline and drop shadow.
        Text(
          text,
          style: _style.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 6
              ..strokeJoin = StrokeJoin.round
              ..color = const Color(0xFF070A16),
            shadows: const [
              Shadow(color: Colors.black, blurRadius: 10, offset: Offset(0, 4)),
            ],
          ),
        ),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: colors,
            stops: const [0, 0.45, 0.72, 1],
          ).createShader(rect),
          child: Text(text, style: _style.copyWith(color: Colors.white)),
        ),
      ],
    );
  }
}

/// Red crosshair with a spy in a fedora, drawn above the title.
class _EmblemPainter extends CustomPainter {
  const _EmblemPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    const cy = 30.0;
    const r = 25.0;
    const red = Color(0xFFFF2A3D);

    final glow = Paint()
      ..color = red.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final line = Paint()
      ..color = red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    // Ring and the top tick.
    final ring = Rect.fromCircle(center: Offset(cx, cy), radius: r);
    canvas.drawArc(ring, math.pi, math.pi, false, glow);
    canvas.drawArc(ring, math.pi, math.pi, false, line);
    canvas.drawLine(Offset(cx, cy - r - 4), Offset(cx, cy - r + 6), line);

    // Horizontal lines fading out to the sides.
    final span = math.min(170.0, size.width / 2 - 8);
    for (final dir in [-1.0, 1.0]) {
      final start = Offset(cx + dir * (r + 2), cy + 4);
      final end = Offset(cx + dir * span, cy + 4);
      final shader = LinearGradient(
        colors: [red, red.withValues(alpha: 0)],
      ).createShader(Rect.fromPoints(start, end));
      canvas.drawLine(
        start,
        end,
        Paint()
          ..shader = shader
          ..strokeWidth = 2,
      );
      canvas.drawLine(
        start,
        end,
        Paint()
          ..shader = shader
          ..strokeWidth = 5
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }

    // Spy: head, glasses, then the fedora on top.
    final head = Paint()..color = const Color(0xFF1B2030);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 16), width: 26, height: 24),
      head,
    );
    final lens = Paint()..color = const Color(0xFFC9D3E6);
    for (final dx in [-6.5, 6.5]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(cx + dx, cy + 13),
            width: 10,
            height: 6,
          ),
          const Radius.circular(3),
        ),
        lens,
      );
    }
    final hat = Paint()..color = const Color(0xFF14171F);
    final crown = Path()
      ..moveTo(cx - 14, cy + 6)
      ..lineTo(cx - 12, cy - 8)
      ..quadraticBezierTo(cx - 6, cy - 13, cx, cy - 9)
      ..quadraticBezierTo(cx + 6, cy - 13, cx + 12, cy - 8)
      ..lineTo(cx + 14, cy + 6)
      ..close();
    canvas.drawPath(crown, hat);
    canvas.drawRect(
      Rect.fromLTRB(cx - 13.4, cy + 1, cx + 13.4, cy + 5),
      Paint()..color = const Color(0xFF3B4152),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 7), width: 46, height: 9),
      hat,
    );
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, cy + 7), width: 46, height: 9),
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = const Color(0xFF5A6175)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Round button with a glowing cyan ring.
class NeonCircleButton extends StatelessWidget {
  const NeonCircleButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.size = 52,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xCC07122A),
        border: Border.all(color: AppColors.primary, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.45),
            blurRadius: 14,
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          icon: Icon(icon, color: AppColors.primary, size: size * 0.5),
        ),
      ),
    );
  }
}

/// "SETTINGS" style page heading: gold stencil text over a red brush stroke.
class BrushTitle extends StatelessWidget {
  const BrushTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: CustomPaint(
        foregroundPainter: const _BrushPainter(),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              text,
              maxLines: 1,
              style: AppTextStyles.display(AppColors.accent, size: 40).copyWith(
                shadows: [
                  Shadow(
                    color: AppColors.accent.withValues(alpha: 0.45),
                    blurRadius: 14,
                  ),
                  const Shadow(
                    color: Colors.black,
                    blurRadius: 4,
                    offset: Offset(0, 2),
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

class _BrushPainter extends CustomPainter {
  const _BrushPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height - 6;
    final w = size.width;
    final path = Path()
      ..moveTo(w * 0.08, y + 2)
      ..quadraticBezierTo(w * 0.45, y - 3, w * 0.98, y - 4)
      ..quadraticBezierTo(w * 0.55, y + 1, w * 0.2, y + 5)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFE0182B));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Pinned polaroid of a spy silhouette.
class SpyPolaroid extends StatelessWidget {
  const SpyPolaroid({super.key});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Transform.rotate(
        angle: 0.09,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(6, 6, 6, 16),
              decoration: BoxDecoration(
                color: const Color(0xFFE9EDF3),
                borderRadius: BorderRadius.circular(2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xAA000000),
                    blurRadius: 12,
                    offset: Offset(2, 6),
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/settings_mugshot.webp',
                width: 84,
                height: 68,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 84,
                  height: 68,
                  color: const Color(0xFF3A4660),
                ),
              ),
            ),
            // Push pin.
            Positioned(
              top: -7,
              left: 60,
              child: Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: Alignment(-0.4, -0.4),
                    colors: [Color(0xFFFF7A7A), Color(0xFFC5101F)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x99000000),
                      blurRadius: 4,
                      offset: Offset(1, 3),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Section heading on a dark ribbon that fades to the right.
class SectionRibbon extends StatelessWidget {
  const SectionRibbon({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.fromLTRB(6, 6, 56, 6),
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.horizontal(left: Radius.circular(24)),
            gradient: LinearGradient(
              colors: [Color(0xF2091530), Color(0xD9091530), Color(0x00091530)],
              stops: [0, 0.7, 1],
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0E1D3D),
                  border: Border.all(color: const Color(0xFF2C4777)),
                ),
                child: Icon(icon, size: 20, color: const Color(0xFFDDE5F5)),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: AppTextStyles.display(
                  AppColors.textPrimary,
                  size: 19,
                ).copyWith(letterSpacing: 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Translucent navy panel with a soft blue rim.
class NeonPanel extends StatelessWidget {
  const NeonPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xC70A1530),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xB33468B5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2F7BFF).withValues(alpha: 0.18),
            blurRadius: 18,
          ),
          const BoxShadow(
            color: Color(0x66000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// One option in a row of pill choices. Selected is gold.
class ChoicePill extends StatelessWidget {
  const ChoicePill({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.buttonInk : AppColors.textPrimary;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            gradient: selected
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFFFE27A),
                      Color(0xFFFFC52E),
                      Color(0xFFF5A10F),
                    ],
                  )
                : null,
            color: selected ? null : const Color(0xFF14244A),
            border: Border.all(
              color: selected
                  ? const Color(0xFFFFE9A8)
                  : const Color(0xFF3D5A90),
              width: 1.5,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.55),
                      blurRadius: 14,
                    ),
                  ]
                : null,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 22, color: fg),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Settings row: icon, label, divider, cyan switch.
class NeonToggleRow extends StatelessWidget {
  const NeonToggleRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 26, color: const Color(0xFFC3CEE6)),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(width: 1.5, height: 28, color: const Color(0x663D5A90)),
              const SizedBox(width: 14),
              Switch(
                value: value,
                onChanged: onChanged,
                thumbColor: const WidgetStatePropertyAll(Colors.white),
                trackColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? AppColors.primary
                      : const Color(0xFF26324F),
                ),
                trackOutlineColor: const WidgetStatePropertyAll(
                  Colors.transparent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
