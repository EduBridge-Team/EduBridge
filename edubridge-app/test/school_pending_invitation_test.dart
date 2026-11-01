import 'package:edubridge_app/model/schools/school_account.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('school email receipt contains only school login details', () {
    final account = SchoolAccount.fromJson({
      'school': {
        'id': 5, 'name': 'School', 'email': 'school@example.org',
        'organization_id': null,
      },
      'account': {'id': 8, 'email': 'school@example.org', 'role': 'school'},
      'verification_email_sent': true,
    });
    expect(account.verificationEmailSent, isTrue);
    expect(account.accountId, 8);
    expect(account.email, 'school@example.org');
    expect(
      const SchoolAccountRequest(
        name: 'School',
        email: 'SCHOOL@example.org',
        password: 'secure-school-password',
        passwordConfirmation: 'secure-school-password',
      ).toJson(),
      {
        'name': 'School',
        'email': 'school@example.org',
        'password': 'secure-school-password',
        'password_confirmation': 'secure-school-password',
      },
    );
  });

  test('director invitation is not mistaken for a school account', () {
    expect(
      () => SchoolAccount.fromJson({
        'school': {'id': 5, 'name': 'School', 'organization_id': null},
        'invitation': {
          'id': 8,
          'email': 'director@example.org',
          'expires_at': '2026-11-07T12:00:00Z',
        },
      }),
      throwsFormatException,
    );
  });
}
