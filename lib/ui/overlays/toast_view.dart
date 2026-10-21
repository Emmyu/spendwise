import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/colors.dart';
import '../../theme/text.dart';

class ToastView extends StatelessWidget {
  const ToastView(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.toast,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(color: Color(0x66000000), blurRadius: 30, spreadRadius: -12, offset: Offset(0, 14)),
          ],
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.circleCheck, size: 18, color: AppColors.mint),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: AppText.style(14.5, color: AppColors.white))),
          ],
        ),
      ),
    );
  }
}
