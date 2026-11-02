/// Creates an official school login; a director's personal login is independent.
class SchoolAccountRequest {
  const SchoolAccountRequest({
    required this.name,
    required this.email,
    this.directorEmail = '',
    this.inviteDirector = false,
    this.phone = '',
    this.address = '',
    // Retained for API compatibility with old constructor callers.
    // Passwords are never transmitted by the provisioning form.
    this.password = '',
    this.passwordConfirmation = '',
  });

  final String name;
  final String email;
  final String directorEmail;
  final bool inviteDirector;
  final String phone;
  final String address;
  final String password;
  final String passwordConfirmation;

  Map<String, dynamic> toJson() => {
    'name': name.trim(),
    'email': email.trim().toLowerCase(),
    if (directorEmail.trim().isNotEmpty)
      'director_email': directorEmail.trim().toLowerCase(),
    if (directorEmail.trim().isNotEmpty && inviteDirector)
      'invite_director': true,
    if (phone.trim().isNotEmpty) 'phone': phone.trim(),
    if (address.trim().isNotEmpty) 'address': address.trim(),
  };
}

/// Public identifiers only. The official school mailbox owner receives a
/// separate activation email to set their own password.
class SchoolAccount {
  const SchoolAccount({
    required this.schoolId,
    required this.accountId,
    required this.name,
    required this.email,
    required this.organizationId,
    this.invitationPending = false,
    this.activationPending = false,
  });

  final int schoolId;
  final int? accountId;
  final String name;
  final String email;
  final int? organizationId;
  final bool invitationPending;
  final bool activationPending;

  factory SchoolAccount.fromJson(Map<String, dynamic> json) {
    final school = json['school'];
    final account = json['account'];
    final invitation = json['invitation'];
    if (school is! Map<String, dynamic> ||
        account is! Map<String, dynamic> ||
        school['id'] is! int ||
        (school['id'] as int) <= 0 ||
        school['name'] is! String ||
        (school['name'] as String).trim().isEmpty ||
        !school.containsKey('organization_id') ||
        (school['organization_id'] != null &&
            (school['organization_id'] is! int ||
                (school['organization_id'] as int) <= 0)) ||
        account['id'] is! int ||
        (account['id'] as int) <= 0 ||
        account['email'] is! String ||
        (account['email'] as String).trim().isEmpty ||
        account['role'] != 'school' ||
        account['activation_pending'] != true ||
        (invitation != null &&
            (invitation is! Map<String, dynamic> ||
                invitation['id'] is! int ||
                (invitation['id'] as int) <= 0 ||
                invitation['email'] is! String ||
                invitation['expires_at'] is! String ||
                DateTime.tryParse(invitation['expires_at'] as String) == null))) {
      throw const FormatException('Invalid official school account response');
    }
    return SchoolAccount(
      schoolId: school['id'] as int,
      accountId: account['id'] as int,
      name: school['name'] as String,
      email: account['email'] as String,
      organizationId: school['organization_id'] as int?,
      activationPending: true,
      invitationPending: invitation != null,
    );
  }
}
