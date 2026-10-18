import 'package:flutter/material.dart';
import '../screens/profile/profile_screen.dart';

/// Dashboard account entry with an explicit role label and profile destination.
class DashboardProfileIdentity extends StatelessWidget {
  const DashboardProfileIdentity({super.key, required this.roleLabel});

  final String roleLabel;

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: () => Navigator.push(context,
      MaterialPageRoute(builder: (_) => const ProfileScreen())),
    style: TextButton.styleFrom(
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
    ),
    icon: const Icon(Icons.account_circle_outlined, size: 40),
    label: Text(roleLabel, maxLines: 1, overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
  );
}
