import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'accessibility/profile_avatar_button.dart';

/// Account greeting inside the dashboard bar, with role-specific context.
class DashboardProfileIdentity extends StatefulWidget {
  const DashboardProfileIdentity({
    super.key, required this.roleLabel, required this.subtitle,
  });

  final String roleLabel;
  final String subtitle;

  @override
  State<DashboardProfileIdentity> createState() => _DashboardProfileIdentityState();
}

class _DashboardProfileIdentityState extends State<DashboardProfileIdentity> {
  late final Future<String?> _name = ApiService.getName();

  @override
  Widget build(BuildContext context) => Row(children: [
    const ProfileAvatarButton(size: 48, backgroundColor: Colors.white,
        foregroundColor: Color(0xFF1768C5)),
    const SizedBox(width: 12),
    Expanded(child: FutureBuilder<String?>(
      future: _name,
      builder: (context, snapshot) {
        final name = snapshot.data?.trim();
        return Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('مرحباً، ${name == null || name.isEmpty ? widget.roleLabel : name}',
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 20,
                  fontWeight: FontWeight.w800)),
            const SizedBox(height: 3),
            Text(widget.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white.withValues(alpha: .87),
                  fontSize: 12)),
          ],
        );
      },
    )),
  ]);
}
