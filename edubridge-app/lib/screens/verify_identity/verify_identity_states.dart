// lib/screens/verify_identity/verify_identity_states.dart
part of 'verify_identity_screen.dart';

Widget buildVerifiedState({
  required BuildContext context,
  required JisrColors c,
  required bool isTeacherOrSpecialist,
}) {
  return Scaffold(
    appBar: JisrAppBar(title: context.l10n.verifyIdentity),
    body: Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: c.line),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified_user, size: 76, color: AppColors.green),
            const SizedBox(height: 16),
            Text(
              context.l10n.accountVerified,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: c.heading),
            ),
            const SizedBox(height: 8),
            Text(
              isTeacherOrSpecialist
                  ? context.l10n.professionalIdentityApproved
                  : context.l10n.identityApproved,
              textAlign: TextAlign.center,
              style: TextStyle(color: c.muted, fontSize: 15, height: 1.6),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                icon: const Icon(Icons.arrow_back),
                label: Text(context.l10n.returnAction),
                onPressed: () => Navigator.maybePop(context),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget buildPendingState({
  required BuildContext context,
  required JisrColors c,
  required bool isTeacherOrSpecialist,
  required bool loading,
  required Future<void> Function() onRefresh,
}) {
  return Scaffold(
    appBar: JisrAppBar(title: context.l10n.verifyIdentity),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.hourglass_top, size: 72, color: AppColors.tealDeep),
            const SizedBox(height: 16),
            Text(
              context.l10n.verificationPending,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: c.heading),
            ),
            const SizedBox(height: 8),
            Text(
              isTeacherOrSpecialist
                  ? context.l10n.professionalVerificationPending
                  : context.l10n.verificationPendingDescription,
              textAlign: TextAlign.center,
              style: TextStyle(color: c.muted, fontSize: 15, height: 1.6),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                icon: const Icon(Icons.refresh),
                label: Text(context.l10n.refreshStatus),
                onPressed: loading ? null : onRefresh,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.exit),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget buildRejectedState({
  required BuildContext context,
  required JisrColors c,
  required VoidCallback onRetry,
}) {
  return Scaffold(
    appBar: JisrAppBar(title: context.l10n.verifyIdentity),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cancel, size: 72, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              context.l10n.verificationRejected,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: c.heading),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.verificationRejectedDescription,
              textAlign: TextAlign.center,
              style: TextStyle(color: c.muted, fontSize: 15, height: 1.6),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: onRetry,
                child: Text(context.l10n.retryAction),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
