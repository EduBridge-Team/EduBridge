import '../../../model/enrollment/enrollment_models.dart';
import '../../../services/enrollment/enrollment_api_client.dart';
import '../domain/notification_destination.dart';

abstract interface class NotificationDestinationGateway {
  Future<NotificationChildDirectory> load();
  Future<NotificationChild> authorize(NotificationChildDirectory expected, int childId);
}
class NotificationDestinationRepository implements NotificationDestinationGateway {
  NotificationDestinationRepository({EnrollmentApiClient? client}) : _client = client ?? EnrollmentApiClient();
  final EnrollmentApiClient _client;
  Future<int> _parent() async {
    final data = await _client.get('/me');
    try {
      final user = enrollmentMap(data['user']);
      if (user['role'] != 'parent') throw const EnrollmentApiException(EnrollmentFailure.forbidden);
      return enrollmentId(user['id']);
    } on FormatException {
      throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
    }
  }
  @override
  Future<NotificationChildDirectory> load() async {
    final userId = await _parent();
    final data = await _client.get('/children');
    if (await _parent() != userId) throw const EnrollmentApiException(EnrollmentFailure.session);
    try {
      final children = enrollmentList(data['children']).map((raw) {
        final row = enrollmentMap(raw);
        return NotificationChild(enrollmentId(row['id']), enrollmentText(row['name']));
      }).toList();
      if (children.map((c) => c.id).toSet().length != children.length) throw const FormatException('Duplicate child');
      return NotificationChildDirectory(userId, children);
    } on FormatException {
      throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
    }
  }
  @override
  Future<NotificationChild> authorize(NotificationChildDirectory expected, int childId) async {
    if (!expected.children.any((c) => c.id == childId)) throw const EnrollmentApiException(EnrollmentFailure.validation);
    if (await _parent() != expected.userId) throw const EnrollmentApiException(EnrollmentFailure.session);
    final data = await _client.get('/children/$childId');
    if (await _parent() != expected.userId) throw const EnrollmentApiException(EnrollmentFailure.session);
    try {
      final row = enrollmentMap(data['child']);
      if (enrollmentId(row['id']) != childId) throw const FormatException('Foreign child');
      return NotificationChild(childId, enrollmentText(row['name']));
    } on FormatException {
      throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
    }
  }
}
