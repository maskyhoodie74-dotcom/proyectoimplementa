import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  final IconData? icon;

  const SectionHeader({
    super.key,
    required this.title,
    this.onSeeAll,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: AppColors.maroonGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.gold, size: 14),
            ),
            const SizedBox(width: 10),
          ] else ...[
            Container(
              width: 3,
              height: 18,
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Text(
            title,
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Row(
                children: [
                  Text(
                    'Ver todos',
                    style: GoogleFonts.inter(
                      color: AppColors.gold,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(CupertinoIcons.chevron_right,
                      color: AppColors.gold, size: 12),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
