import 'package:edubridge_app/model/schools/school_account.dart';
import 'package:flutter_test/flutter_test.dart';
void main() {
  test('invitation receipt preserves pending state without fabricating a director', () {
    final account=SchoolAccount.fromJson({
      'school':{'id':5,'name':'School','organization_id':null},
      'invitation':{'id':8,'email':'director@example.org','expires_at':'2026-11-07T12:00:00Z'},
    });
    expect(account.invitationPending,isTrue);
    expect(account.accountId,isNull);
    expect(account.email,'director@example.org');
    expect(const SchoolAccountRequest(name:'School',email:'Director@example.org',inviteDirector:true).toJson(),{
      'name':'School','director_email':'director@example.org','invite_director':true,
    });
  });
  test('malformed invitation cannot be shown as a successful creation', () {
    expect(()=>SchoolAccount.fromJson({'school':{'id':5,'name':'School','organization_id':null},
      'invitation':{'id':8,'email':'director@example.org','expires_at':'bad'}}),throwsFormatException);
  });
}
