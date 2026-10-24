/// Contract for provisioning a school identity, separate from a school record.
class SchoolAccountRequest {
  const SchoolAccountRequest({
    required this.name,
    required this.email,
    required this.password,
    required this.passwordConfirmation,
    this.phone = '',
    this.address = '',
  });

  final String name;
  final String email;
  final String password;
  final String passwordConfirmation;
  final String phone;
  final String address;

  Map<String, dynamic> toJson() => {
    'name': name.trim(),
    'email': email.trim(),
    'password': password,
    'password_confirmation': passwordConfirmation,
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
  });

  final int schoolId;
  final int accountId;
  final String name;
  final String email;
  final int? organizationId;

  factory SchoolAccount.fromJson(Map<String, dynamic> json) {
    final school = json['school'];
    final account = json['account'];
    if (school is! Map<String, dynamic> ||
        account is! Map<String, dynamic> ||
        school['id'] is! int ||
        (school['id'] as int) <= 0 ||
        account['id'] is! int ||
        (account['id'] as int) <= 0 ||
        school['name'] is! String ||
        (school['name'] as String).trim().isEmpty ||
        account['email'] is! String ||
        account['role'] != 'school' ||
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
