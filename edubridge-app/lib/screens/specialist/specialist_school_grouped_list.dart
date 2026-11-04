import 'package:flutter/material.dart';

import '../../theme.dart';

/// Groups never infer school membership from missing or incomplete API fields.
/// An explicit `not_enrolled` status + null school fields is required to classify
/// a followed child as outside schools.
enum SpecialistSchoolGroupKind { school, outsideSchools, unspecified }

/// A dashboard section identified by school, verified non-enrollment or unknown scope.
class SpecialistChildSchoolGroup {
  SpecialistChildSchoolGroup({
    required this.kind,
    required this.schoolId,
    required this.schoolName,
    required List<Map<String, dynamic>> rows,
  }) : rows = List.unmodifiable(rows);

  final SpecialistSchoolGroupKind kind;
  final int? schoolId;
  final String? schoolName;
  final List<Map<String, dynamic>> rows;
  bool get hasSchool => kind == SpecialistSchoolGroupKind.school;
}

/// Treat no-school as confirmed only when the server explicitly verifies that
/// there is no active school enrollment. A missing school ID alone proves nothing.
bool _hasVerifiedNoSchool(Map child) =>
    (child['school_membership_status'] == 'not_enrolled' ||
     child['school_membership_status'] == 'none') &&
    child.containsKey('school_id') &&
    child.containsKey('school_name') &&
    child['school_id'] == null &&
    child['school_name'] == null;

/// Groups only the already-authorized, already-filtered dashboard rows.
/// The server must supply school_id and school_name for every enrolled child.
/// Organization names, child names and school names alone never establish membership.
List<SpecialistChildSchoolGroup> groupSpecialistChildrenBySchool(
    List<Map<String, dynamic>> rows) {
  final grouped = <int, List<Map<String, dynamic>>>{};
  final outside = <Map<String, dynamic>>[];
  final unknown = <Map<String, dynamic>>[];
  final names = <int, String>{};
  final ambiguous = <int>{};

  for (final row in rows) {
    final child = row['child'];
    if (child is! Map) {
      unknown.add(row);
      continue;
    }

    if (_hasVerifiedNoSchool(child)) {
      outside.add(row);
      continue;
    }

    final rawId = child['school_id'];
    final rawName = child['school_name'];
    final id = rawId is int && rawId > 0 ? rawId : null;
    final name = rawName is String ? rawName.trim() : '';
    final membership = child['school_membership_status'];
    // Conflicting status or incomplete school identity cannot establish either
    // confirmed school membership or confirmed non-enrollment.
    if (id == null || name.isEmpty ||
        membership == 'not_enrolled' || membership == 'none') {
      unknown.add(row);
      continue;
    }
    final previous = names[id];
    if (previous != null && previous != name) ambiguous.add(id);
    names[id] = name;
    grouped.putIfAbsent(id, () => []).add(row);
  }

  final result = <SpecialistChildSchoolGroup>[];
  for (final entry in grouped.entries) {
    if (ambiguous.contains(entry.key)) {
      unknown.addAll(entry.value);
    } else {
      result.add(SpecialistChildSchoolGroup(
        kind: SpecialistSchoolGroupKind.school,
        schoolId: entry.key,
        schoolName: names[entry.key]!,
        rows: entry.value,
      ));
    }
  }
  result.sort((a, b) => a.schoolName!.compareTo(b.schoolName!));
  if (outside.isNotEmpty) {
    result.add(SpecialistChildSchoolGroup(
      kind: SpecialistSchoolGroupKind.outsideSchools,
      schoolId: null,
      schoolName: null,
      rows: outside,
    ));
  }
  if (unknown.isNotEmpty) {
    result.add(SpecialistChildSchoolGroup(
      kind: SpecialistSchoolGroupKind.unspecified,
      schoolId: null,
      schoolName: null,
      rows: unknown,
    ));
  }
  return List.unmodifiable(result);
}

/// A school heading is inserted immediately above the existing child cards.
/// Both "My children" and "Waiting list" reuse this exact widget.
class SpecialistSchoolGroupedSliver extends StatelessWidget {
  const SpecialistSchoolGroupedSliver({
    super.key,
    required this.rows,
    required this.childBuilder,
    this.isMyChildren = false,
  });

  final List<Map<String, dynamic>> rows;
  final Widget Function(BuildContext context, Map<String, dynamic> row) childBuilder;
  /// Wording for explicitly un-enrolled children differs on the waiting tab.
  final bool isMyChildren;

  @override
  Widget build(BuildContext context) {
    final groups = groupSpecialistChildrenBySchool(rows);
    // Older /children responses carry no school scope. Until the backend
    // supplies it, preserve the current cards with no guessed school label.
    if (groups.length == 1 &&
        groups.first.kind == SpecialistSchoolGroupKind.unspecified) {
      return SliverList.builder(
        itemCount: rows.length,
        itemBuilder: (context, i) => childBuilder(context, rows[i]),
      );
    }
    final c = JisrColors.of(context);
    final english = Localizations.localeOf(context).languageCode == 'en';
    final entries = <Object>[
      for (final group in groups) ...[group, ...group.rows],
    ];
    return SliverList.builder(
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final item = entries[index];
        if (item is Map<String, dynamic>) return childBuilder(context, item);
        final group = item as SpecialistChildSchoolGroup;
        final outside = group.kind == SpecialistSchoolGroupKind.outsideSchools;
        final unknown = group.kind == SpecialistSchoolGroupKind.unspecified;
        final groupKey = outside ? 'outside' : (unknown ? 'unknown' : '${group.schoolId}');
        final title = outside
            ? (isMyChildren
                ? (english ? 'Children followed outside schools'
                    : 'أطفال تحت المتابعة خارج المدارس')
                : (english ? 'Children outside schools' : 'أطفال خارج المدارس'))
            : group.schoolName ??
                (english ? 'School not specified' : 'المدرسة غير محددة');
        return Padding(
          key: ValueKey('specialist-school-group-$groupKey'),
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.line),
            ),
            child: Row(children: [
              Icon(outside ? Icons.people_outline :
                  unknown ? Icons.help_outline : Icons.school_outlined,
                  color: AppColors.brandBlue),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: c.heading, fontWeight: FontWeight.w800, fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.brandBlue.withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Text(
                    english
                        ? '${group.rows.length} children'
                        : '${group.rows.length} أطفال',
                    key: ValueKey('specialist-school-count-$groupKey'),
                    style: const TextStyle(
                      color: AppColors.brandBlue, fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ]),
          ),
        );
      },
    );
  }
}
