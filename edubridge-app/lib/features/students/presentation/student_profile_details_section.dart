import 'package:flutter/material.dart';

import '../../../theme.dart';

class StudentProfileDetailsSection extends StatelessWidget {
  const StudentProfileDetailsSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.children,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Material(
        color: c.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: c.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 7,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            leading: Container(
              width: 47,
              height: 47,
              decoration: BoxDecoration(
                color: const Color(0xFFE4EFFA),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.brandBlue, size: 23),
            ),
            title: Text(
              title,
              style: TextStyle(
                color: c.heading,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            subtitle: subtitle.isEmpty
                ? null
                : Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: c.muted),
                  ),
            children: children,
          ),
        ),
      ),
    );
  }
}
