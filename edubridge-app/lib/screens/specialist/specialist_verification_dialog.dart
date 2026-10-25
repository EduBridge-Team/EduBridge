import 'package:flutter/material.dart';

import '../../app_icons.dart';
import '../../l10n/l10n.dart';
import '../../theme.dart';

/// Presents verification requirements; the dashboard owns navigation and refresh.
class SpecialistVerificationDialog extends StatelessWidget {
  const SpecialistVerificationDialog({super.key, required this.onVerify});

  final VoidCallback onVerify;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.brandBlueLight.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  AppIcons.verified,
                  size: 48,
                  color: AppColors.brandBlueLight,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                context.l10n.verificationRequired,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: JisrColors.of(context).heading,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                context.l10n.specialistVerificationDescription,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: JisrColors.of(context).muted,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: double.infinity,
                  minHeight: 52,
                ),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandBlueLight,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(AppIcons.verified, size: 22),
                  label: Text(
                    context.l10n.verifyIdentityAndCertificate,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  onPressed: onVerify,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
