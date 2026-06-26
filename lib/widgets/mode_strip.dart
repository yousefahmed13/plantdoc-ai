import 'package:flutter/material.dart';
import '../theme/plantdoc_theme.dart';

class ModeStrip extends StatelessWidget {
  final String activeMode;
  final bool isAr;

  const ModeStrip({Key? key, required this.activeMode, required this.isAr}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final modes = ['leaf', 'insect', 'grape', 'weather'];
    return Container(
      height: 36,
      color: PD.bg,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: modes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => _ModeChip(
          mode: modes[i],
          isActive: modes[i] == activeMode,
          isAr: isAr,
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String mode;
  final bool isActive;
  final bool isAr;

  const _ModeChip({
    required this.mode,
    required this.isActive,
    required this.isAr,
  });

  @override
  Widget build(BuildContext context) {
    final color = PD.modeColor(mode);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.15) : PD.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? color.withOpacity(0.4) : PD.border,
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(PD.modeEmoji(mode), style: const TextStyle(fontSize: 11)),
          const SizedBox(width: 5),
          Text(
            PD.modeLabel(mode, isAr),
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
              color: isActive ? color : PD.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
