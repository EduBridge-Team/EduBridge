import 'package:flutter/material.dart';

import '../../theme.dart';

/// A dashboard section identified by an explicit school ID and name.
/// Rows lacking either field remain visible, but are never assigned a guessed school.
class SpecialistChildSchoolGroup {
  SpecialistChildSchoolGroup({
    required this.schoolId,
    required this.schoolName,
    required List<Map<String, dynamic>> rows,
  }) : rows = List.unmodifiable(rows);

  final int? schoolId;
  final String? schoolName;
  final List<Map<String, dynamic>> rows;
  bool get hasSchool => schoolId != null && schoolName != null;
}

/// Groups only the already-authorized, already-filtered dashboard rows.
/// The server must supply school_id and school_name for every enrolled child.
/// Organization names, child names and school names alone never establish membership.
List<SpecialistChildSchoolGroup> groupSpecialistChildrenBySchool(
    List<Map<String, dynamic>> rows) {
  final grouped = <int?, List<Map<String, dynamic>>>{};
  final names = <int, String>{};
  final ambiguous = <int>{};

  for (final row in rows) {
    final child = row['child'];
    if (child is! Map) {
      grouped.putIfAbsent(null, () => []).add(row);
      continue;
    }

    final rawId = child['school_id'];
    final rawName = child['school_name'];
    final id = rawId is int && rawId > 0 ? rawId : null;
    final name = rawName is String ? rawName.trim() : '';
    if (id == null || name.isEmpty) {
      grouped.putIfAbsent(null, () => []).add(row);
      continue;
    }
    final previous = names[id];
    if (previous != null && previous != name) ambiguous.add(id);
    names[id] = name;
    grouped.putIfAbsent(id, () => []).add(row);
  }

  final result = <SpecialistChildSchoolGroup>[];
  final unknown = <Map<String, dynamic>>[];
  for (final entry in grouped.entries) {
    if (entry.key == null || ambiguous.contains(entry.key)) {
      unknown.addAll(entry.value);
    } else {
      result.add(SpecialistChildSchoolGroup(
        schoolId: entry.key,
        schoolName: names[entry.key]!,
        rows: entry.value,
      ));
    }
  }
  result.sort((a, b) => a.schoolName!.compareTo(b.schoolName!));
  if (unknown.isNotEmpty) {
    result.add(SpecialistChildSchoolGroup(
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
  });

  final List<Map<String, dynamic>> rows;
  final Widget Function(BuildContext context, Map<String, dynamic> row) childBuilder;

  @override
  Widget build(BuildContext context) {
    final groups = groupSpecialistChildrenBySchool(rows);
    // Older /children responses carry no school scope. Until the backend
    // supplies it, preserve the current cards with no guessed school label.
    if (groups.length == 1 && !groups.first.hasSchool) {
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
        return Padding(
          key: ValueKey('specialist-school-group-${group.schoolId ?? 'unknown'}'),
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.line),
            ),
            child: Row(children: [
              const Icon(Icons.school_outlined, color: AppColors.brandBlue),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  group.schoolName ??
                      (english ? 'School not specified' : 'المدرسة غير محددة'),
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
                    english ? '${group.rows.length} students' : '${group.rows.length} طلاب',
                    key: ValueKey('specialist-school-count-${group.schoolId ?? 'unknown'}'),
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
