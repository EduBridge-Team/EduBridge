import 'package:flutter/material.dart';
import '../../model/iep/iep_evidence_filter.dart';
import 'iep_evidence_labels.dart';

class IepEvidenceFilters extends StatelessWidget {
  const IepEvidenceFilters({super.key, required this.controller, required this.kind,
    required this.oldestFirst, required this.onKind, required this.onOldest, required this.onSearch});
  final TextEditingController controller;
  final IepEvidenceKind kind;
  final bool oldestFirst;
  final ValueChanged<IepEvidenceKind> onKind;
  final ValueChanged<bool> onOldest;
  final ValueChanged<String> onSearch;
  @override
  Widget build(BuildContext context) {
    final l = IepEvidenceLabels(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      TextField(key: const ValueKey('iep-evidence-search'), controller: controller,
        onChanged: onSearch, decoration: InputDecoration(
          labelText: l.searchEvidence, prefixIcon: const Icon(Icons.search))),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final value in IepEvidenceKind.values) FilterChip(
          key: ValueKey('iep-evidence-filter-${value.name}'), selected: kind == value,
          label: Text(switch(value) {
            IepEvidenceKind.all => l.allEvidence,
            IepEvidenceKind.numeric => l.numericEvidence,
            IepEvidenceKind.qualitative => l.qualitativeEvidence,
          }), onSelected: (_) => onKind(value)),
      ]),
      SwitchListTile(key: const ValueKey('iep-evidence-oldest'), contentPadding: EdgeInsets.zero,
        title: Text(l.oldestFirst), value: oldestFirst, onChanged: onOldest),
      Text(l.filterNote),
    ]);
  }
}

