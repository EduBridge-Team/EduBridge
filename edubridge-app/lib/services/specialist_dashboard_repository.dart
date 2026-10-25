import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../model/specialist_dashboard_data.dart';
import '../model/specialist_progress_summary.dart';
import 'api_service.dart';

/// A rejected dashboard request; the screen supplies a localized fallback.
class SpecialistDashboardLoadException implements Exception {
  const SpecialistDashboardLoadException(this.message);

  final Object? message;
}

/// Loads and assembles dashboard data without holding widget state.
class SpecialistDashboardRepository {
  Future<SpecialistDashboardData> load({required int? currentUserId}) async {
    final responses = await Future.wait([
      ApiService.authGet('/children'),
      ApiService.authGet('/lessons'),
      ApiService.authGet('/disability-types'),
      ApiService.authGet('/users?role=teacher'),
      ApiService.authGet('/users?role=specialist'),
    ]);

    final childrenData = jsonDecode(responses[0].body);
    final lessonsData = jsonDecode(responses[1].body);
    final typesData = jsonDecode(responses[2].body);
    final teachersData = jsonDecode(responses[3].body);
    final specialistsData = jsonDecode(responses[4].body);

    if (responses[0].statusCode != 200) {
      throw SpecialistDashboardLoadException(childrenData['error']);
    }

    final children = (childrenData['children'] ?? []) as List;
    final rows = <Map<String, dynamic>>[];
    for (final child in children) {
      final pRes = await ApiService.authGet('/progress/child/${child['id']}');
      final pData = jsonDecode(pRes.body);
      final progress = pRes.statusCode == 200 ? (pData['progress'] ?? []) : [];
      rows.add({
        'child': child,
        'progress': progress,
        'stats': SpecialistProgressSummary.calculate(progress),
      });
    }

    String? specialty;
    try {
      final meRes = await ApiService.authGet('/me');
      if (meRes.statusCode == 200) {
        final meData = jsonDecode(meRes.body);
        final me = meData['user'] ?? meData;
        final spec = (me['specialty'] ?? '').toString().toLowerCase().trim();
        if (spec == 'learning_support' || spec.contains('نفس')) {
          specialty = 'learning_support';
        } else if (spec == 'educational' || spec.contains('تعليم')) {
          specialty = 'educational';
        }
      }
    } catch (e) {
      debugPrint('فشل /me: $e');
    }

    if (specialty == null) {
      final meUser = (specialistsData['users'] as List? ?? []).firstWhere(
        (u) => u['id'] == currentUserId,
        orElse: () => <String, dynamic>{},
      );
      final spec = (meUser['specialty'] ?? '').toString().toLowerCase().trim();
      if (spec == 'learning_support' || spec.contains('نفس')) {
        specialty = 'learning_support';
      } else if (spec == 'educational' || spec.contains('تعليم')) {
        specialty = 'educational';
      }
    }
    return SpecialistDashboardData(
      rows: rows,
      lessons: lessonsData['lessons'] ?? [],
      types: typesData['disability_types'] ?? [],
      teachers: teachersData['users'] ?? [],
      specialists: specialistsData['users'] ?? [],
      specialty: specialty,
    );
  }
}
