import '../../model/institutions/institution_enrollment_history.dart';
import '../../services/institution_enrollment_history_repository.dart';
import '../../services/enrollment/enrollment_api_client.dart';
import '../enrollment/enrollment_state.dart';

class InstitutionEnrollmentController extends EnrollmentState<InstitutionEnrollmentHistory> {
  InstitutionEnrollmentController(this.gateway) : super(gateway.load);
  final InstitutionEnrollmentHistoryGateway gateway;
  bool get supportsTransfer => gateway is InstitutionEnrollmentTransferGateway;
  bool get supportsWithdrawal => gateway is InstitutionEnrollmentWithdrawalGateway;
  Future<void> withdraw(int enrollmentId) => mutate(() async {
    if (gateway case final InstitutionEnrollmentWithdrawalGateway writer) {
      await writer.withdraw(enrollmentId);
    } else {
      throw const EnrollmentApiException(EnrollmentFailure.unavailable);
    }
  });
  Future<void> transfer(int enrollmentId, int sectionId) => mutate(() async {
    if (gateway case final InstitutionEnrollmentTransferGateway writer) {
      await writer.transfer(enrollmentId, sectionId);
    }
  });
}
