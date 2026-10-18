import 'package:flutter/material.dart';
import '../../theme.dart';

/// S29 waiting-list empty state, below the existing live dashboard metrics.
class SpecialistWaitingEmptyS29 extends StatelessWidget {
  final bool isSearch;
  const SpecialistWaitingEmptyS29({super.key, this.isSearch = false});

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 132,
          height: 132,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? c.tintTeal : const Color(0xFFD8F2F6),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isSearch ? Icons.search_rounded : Icons.access_time_rounded,
            size: 46,
            color: const Color(0xFF2187E7),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          isSearch ? 'لا يوجد أطفال مطابقون للبحث' : 'لا يوجد أطفال في قائمة الانتظار',
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: TextStyle(color: c.heading, fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
