/// School identity uses its official email; director identity remains separate.
class SchoolAccountRequest {
  const SchoolAccountRequest({
    required this.name,
    required this.email,
    this.directorEmail = '',
    this.password = '',
    this.passwordConfirmation = '',
    this.inviteDirector = false,
    this.phone = '',
    this.address = '',
  });

  final String name;
  final String email;
  final String directorEmail;
  // Retained only for compatibility with existing Flutter callers. Passwords
  // must NEVER be sent during provisioning; they are set by the mailbox owner.
  final String password;
  final String passwordConfirmation;
  final bool inviteDirector;
  final String phone;
  final String address;

  Map<String, dynamic> toJson() => {
    'name': name.trim(),
    'school_email': email.trim().toLowerCase(),
    if (directorEmail.trim().isNotEmpty)
      'director_email': directorEmail.trim().toLowerCase(),
    if (directorEmail.trim().isNotEmpty && inviteDirector)
      'invite_director': true,
    if (phone.trim().isNotEmpty) 'phone': phone.trim(),
    if (address.trim().isNotEmpty) 'address': address.trim(),
  };
}

/// No password or activation token is returned to the administrator.
class SchoolAccount {
  const SchoolAccount({
    required this.schoolId,
    required this.accountId,
    required this.name,
    required this.email,
    required this.organizationId,
    this.invitationPending = false,
    this.directorAssigned = false,
    this.activationPending = true,
  });

  final int schoolId;
  final int? accountId;
  final String name;
  final String email;
  final int? organizationId;
  final bool invitationPending;
  final bool directorAssigned;
  final bool activationPending;

  factory SchoolAccount.fromJson(Map<String, dynamic> json) {
    final school = json['school'];
    final account = json['account'];
    final director = json['director'];
    final invitation = json['invitation'];
    if (school is! Map<String, dynamic> ||
        school['id'] is! int || (school['id'] as int) <= 0 ||
        school['name'] is! String || (school['name'] as String).trim().isEmpty ||
        school['email'] is! String ||
        school['activation_status'] != 'pending' ||
        !school.containsKey('organization_id') ||
        (school['organization_id'] != null &&
            (school['organization_id'] is! int || (school['organization_id'] as int) <= 0)) ||
        account is! Map<String, dynamic> ||
        account['id'] is! int || (account['id'] as int) <= 0 ||
        account['role'] != 'school_identity' ||
        account['email'] is! String ||
        (account['email'] as String).toLowerCase() != (school['email'] as String).toLowerCase()) {
      throw const FormatException('Invalid official school account response');
    }

    if (director != null && (director is! Map<String, dynamic> ||
        director['id'] is! int || (director['id'] as int) <= 0 ||
        director['email'] is! String ||
        (director['email'] as String).toLowerCase() == (school['email'] as String).toLowerCase())) {
      throw const FormatException('Invalid director assignment');
    }
    if (invitation != null && (invitation is! Map<String, dynamic> ||
        invitation['id'] is! int || (invitation['id'] as int) <= 0 ||
        invitation['email'] is! String || invitation['expires_at'] is! String ||
        DateTime.tryParse(invitation['expires_at'] as String) == null)) {
      throw const FormatException('Invalid director invitation');
    }
    if (director != null && invitation != null) {
      throw const FormatException('Ambiguous director state');
    }

    return SchoolAccount(
      schoolId: school['id'] as int,
      accountId: account['id'] as int,
      name: school['name'] as String,
      email: account['email'] as String,
      organizationId: school['organization_id'] as int?,
      invitationPending: invitation != null,
      directorAssigned: director != null,
    );
  }
}
