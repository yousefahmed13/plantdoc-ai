import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

TextStyle arabicFont({
  double size = 14,
  FontWeight weight = FontWeight.normal,
  Color color = AppColors.textPrimary,
  double height = 1.5,
}) {
  return GoogleFonts.cairo(fontSize: size, fontWeight: weight, color: color, height: height);
}

TextStyle englishFont({
  double size = 14,
  FontWeight weight = FontWeight.normal,
  Color color = AppColors.textPrimary,
  double height = 1.5,
}) {
  return GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color, height: height);
}

TextStyle appFont(
  bool isAr, {
  double size = 14,
  FontWeight weight = FontWeight.normal,
  Color color = AppColors.textPrimary,
  double height = 1.5,
}) {
  return isAr
      ? arabicFont(size: size, weight: weight, color: color, height: height)
      : englishFont(size: size, weight: weight, color: color, height: height);
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Color? borderColor;
  final double radius;
  final VoidCallback? onTap;

  const AppCard({
    Key? key,
    required this.child,
    this.padding,
    this.color,
    this.borderColor,
    this.radius = 16,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final container = Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? AppColors.card,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? AppColors.cardBorder, width: 1),
      ),
      child: child,
    );
    if (onTap != null) return GestureDetector(onTap: onTap, child: container);
    return container;
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final bool isAr;
  final Widget? trailing;

  const SectionHeader({Key? key, required this.title, required this.isAr, this.trailing})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: appFont(isAr,
                size: 13, weight: FontWeight.w700, color: AppColors.textSecondary)),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class StatusBadge extends StatelessWidget {
  final bool isOnline;
  final bool isAr;

  const StatusBadge({Key? key, required this.isOnline, required this.isAr}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (isOnline ? AppColors.primary : AppColors.amber).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: (isOnline ? AppColors.primary : AppColors.amber).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(
              color: isOnline ? AppColors.primary : AppColors.amber,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isOnline ? (isAr ? 'متصل' : 'Online') : (isAr ? 'غير متصل' : 'Offline'),
            style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isOnline ? AppColors.primary : AppColors.amber),
          ),
        ],
      ),
    );
  }
}

class LoadingOverlay extends StatelessWidget {
  final String message;
  final bool isAr;

  const LoadingOverlay({Key? key, required this.message, required this.isAr}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          const SizedBox(
            width: 36, height: 36,
            child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
          ),
          const SizedBox(height: 14),
          Text(message,
              style: appFont(isAr, size: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class ErrorBox extends StatelessWidget {
  final String message;
  final bool isAr;

  const ErrorBox({Key? key, required this.message, required this.isAr}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.red.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.red, size: 18),
          const SizedBox(width: 10),
          Expanded(
              child: Text(message,
                  style: appFont(isAr, size: 12, color: AppColors.red, height: 1.4))),
        ],
      ),
    );
  }
}
