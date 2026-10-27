import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:edubridge_app/features/notifications/data/notification_destination_repository.dart';
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';

class NotificationDestinationFixture {
  int userId = 4, detailStatus = 200, listStatus = 200, childId = 9;
  String role = 'parent';
  final children = <Map<String, dynamic>>[{'id': 9, 'name': 'نور'}, {'id': 8, 'name': 'أحمد'}];
  final paths = <String>[];
  Future<void> Function()? beforeDetail;
  void Function()? afterList, afterDetail;
  NotificationDestinationRepository get repository => NotificationDestinationRepository(client: EnrollmentApiClient(get: (path) async {
    paths.add(path);
    late Map<String, dynamic> body; var status = 200;
    if (path == '/me') {
      body = {'user': {'id': userId, 'role': role}};
    } else if (path == '/children') {
      body = {'children': children}; status = listStatus; afterList?.call();
    } else if (path == '/children/9') {
      await beforeDetail?.call(); afterDetail?.call();
      body = {'child': {'id': childId, 'name': 'نور — سجل محدث'}}; status = detailStatus;
    } else { throw StateError(path); }
    return http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json; charset=utf-8'});
  }, post: (path, body) async => throw StateError('No writes')));
}
