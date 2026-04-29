import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const SectionHeader({super.key, required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: GoogleFonts.oswald(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2)),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: Text('VER TODO',
                style: GoogleFonts.inter(
                    color: AppColors.gold,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1)),
          ),
      ],
    );
  }
}
