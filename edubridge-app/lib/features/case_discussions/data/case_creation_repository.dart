import '../../../services/api_service.dart';
import '../domain/case_creation_directory.dart';
import '../domain/case_team_policy.dart';

/// Loads case creation inputs and delegates persistence to the existing API.
class CaseCreationRepository {
  List<Map<String, dynamic>> _records(List values) => values
      .whereType<Map>()
      .map((value) => Map<String, dynamic>.from(value))
      .toList();

  Future<CaseCreationDirectory> loadDirectory() async {
    final role = await ApiService.getRole();
    final userId = await ApiService.getUserId();
    final responses = await Future.wait([
      ApiService.authGet('/children'),
      ApiService.authGet('/users'),
    ]);
    if (responses.any((response) => response.statusCode != 200)) {
      throw StateError('Case team data could not be loaded');
    }
    final children = _records(
      ApiService.extractList(responses[0].body, 'children'),
    );
    final users = _records(ApiService.extractList(responses[1].body, 'users'));
    return CaseCreationDirectory(
      children: CaseTeamPolicy.assignedChildren(
        children,
        role: role,
        userId: userId,
      ),
      users: CaseTeamPolicy.eligibleUsers(users),
      currentUserId: userId,
    );
  }

  Future<bool> create({
    required int childId,
    required String topic,
    required String? description,
    required List<int> participantIds,
  }) async =>
      await ApiService.createCaseDiscussion(
        childId: childId,
        topic: topic,
        description: description,
        participantIds: participantIds,
      ) !=
      null;
}
