/// Contract for provisioning a school identity, separate from a school record.
class SchoolAccountRequest {
  const SchoolAccountRequest({
    required this.name,
    required this.email,
    this.password = '',
    this.passwordConfirmation = '',
    this.inviteDirector = false,
    this.phone = '',
    this.address = '',
  });

  final bool inviteDirector;
  final String name;
  final String email;
  final String password;
  final String passwordConfirmation;
  final String phone;
  final String address;

  Map<String, dynamic> toJson() => {
    'name': name.trim(),
    'director_email': email.trim().toLowerCase(),
    if (inviteDirector) 'invite_director': true,
    if (phone.trim().isNotEmpty) 'phone': phone.trim(),
    if (address.trim().isNotEmpty) 'address': address.trim(),
  };
}

/// Contains public identifiers only; provisioning must not replace the session.
class SchoolAccount {
  const SchoolAccount({
    required this.schoolId,
    required this.accountId,
    required this.name,
    required this.email,
    required this.organizationId,
    this.invitationPending = false,
  });

  final int schoolId;
  final int? accountId;
  final bool invitationPending;
  final String name;
  final String email;
  final int? organizationId;

  factory SchoolAccount.fromJson(Map<String, dynamic> json) {
    final school = json['school'];
    final account = json['director'];
    final invitation = json['invitation'];
    if (school is Map<String,dynamic> && invitation is Map<String,dynamic> &&
        school['id'] is int && (school['id'] as int)>0 && school['name'] is String &&
        (school['name'] as String).trim().isNotEmpty && invitation['id'] is int && (invitation['id'] as int)>0 &&
        invitation['email'] is String && invitation['expires_at'] is String && DateTime.tryParse(invitation['expires_at'] as String)!=null &&
        school.containsKey('organization_id') && (school['organization_id']==null || school['organization_id'] is int && (school['organization_id'] as int)>0)) {
      return SchoolAccount(schoolId:school['id'] as int,accountId:null,name:school['name'] as String,email:invitation['email'] as String,
        organizationId:school['organization_id'] as int?,invitationPending:true);
    }

    if (school is! Map<String, dynamic> ||
        account is! Map<String, dynamic> ||
        school['id'] is! int ||
        (school['id'] as int) <= 0 ||
        account['id'] is! int ||
        (account['id'] as int) <= 0 ||
        school['name'] is! String ||
        (school['name'] as String).trim().isEmpty ||
        account['email'] is! String ||
        !school.containsKey('organization_id') ||
        (school['organization_id'] != null &&
            (school['organization_id'] is! int ||
                (school['organization_id'] as int) <= 0))) {
      throw const FormatException('Invalid school account response');
    }
    return SchoolAccount(
      schoolId: school['id'] as int,
      accountId: account['id'] as int,
      name: school['name'] as String,
      email: account['email'] as String,
      organizationId: school['organization_id'] as int?,
    );
  }
}
