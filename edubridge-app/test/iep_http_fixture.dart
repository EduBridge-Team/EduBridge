import 'dart:convert';

import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'package:edubridge_app/services/iep/iep_history_repository.dart';
import 'package:http/http.dart' as http;

const iepGoalText = 'هدف فردي أصلي — قراءة كلمات مألوفة باستقلالية';
Map<String, dynamic> iepGoalJson({int version = 102}) => {
  'id': 501,
  'plan_version_id': version,
  'title': iepGoalText,
  'baseline': 2,
  'target': 8,
  'unit': 'كلمات في المحاولة',
  'measurement_method': 'ملاحظة مباشرة مع تسجيل المحاولات',
  'responsible_name': 'المعلم — Teacher',
  'starts_on': '2026-09-01',
  'ends_on': '2027-06-01',
};
Map<String, dynamic> iepVersionJson({
  int id = 102,
  int number = 2,
  String status = 'draft',
}) => {
  'id': id,
  'plan_id': 10,
  'child_id': 8,
  'version_number': number,
  'evaluation_id': 11,
  'status': status,
  'summary': 'خطة فردية محفوظة بصياغة المختص الأصلية',
  'created_by_name': 'المختص',
  'return_reason': status == 'returned' ? 'أضف وسيلة قياس واضحة' : null,
  'created_at': '2026-10-25T08:00:00Z',
  'starts_on': '2026-09-01',
  'ends_on': '2027-06-30',
  'review_on': '2027-01-01',
  'goals': [iepGoalJson(version: id)],
  'accommodations': ['وقت إضافي حسب حاجة الطفل'],
  'review_comments': [
    {
      'id': 701,
      'plan_version_id': id,
      'text': 'تعليق مراجعة أصلي',
      'author_name': 'المراجع',
      'created_at': '2026-10-25T09:00:00Z',
    },
  ],
};
Map<String, dynamic> iepPlanJson() => {
  'id': 10,
  'child_id': 8,
  'title': 'خطة فردية للتواصل والتعلم — Individual plan',
  'is_closed': false,
  'current_approved_version_id': 101,
  'versions': [
    iepVersionJson(id: 101, number: 1, status: 'approved'),
    iepVersionJson(),
  ],
};
Map<String, dynamic> iepHistoryJson() => {
  'child_id': 8,
  'plans': [iepPlanJson()],
};

class IepHttpFixture {
  Map<String, dynamic> payload = iepHistoryJson();
  int status = 200;
  final reads = <String>[];
  IepHistoryRepository get repository => IepHistoryRepository(
    childId: 8,
    client: EnrollmentApiClient(
      get: (path) async {
        if (path != '/children/8/iep-plans')
          throw StateError('Unexpected GET $path');
        reads.add(path);
        return http.Response(
          jsonEncode(payload),
          status,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      },
      post: (path, body) async =>
          throw StateError('Read-only IEP must not POST'),
    ),
  );
}
