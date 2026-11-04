import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

/// Code-drawn title plaque for screens whose artwork has no baked-in sign.
///
/// Cream stencil on a dark plate with a cyan rim, matching the signs in the
/// scene art. Do not place this on players, pass-the-phone, or ready art.
class ClassifiedPlaque extends StatelessWidget {
  const ClassifiedPlaque({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF10182E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 16,
          ),
          const BoxShadow(
            color: Color(0x80000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (subtitle != null) ...[
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: AppTextStyles.dossier(AppColors.paper, size: 13),
            ),
            const SizedBox(height: 4),
          ],
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: AppTextStyles.display(AppColors.accent, size: 28),
            ),
          ),
        ],
      ),
    );
  }
}
