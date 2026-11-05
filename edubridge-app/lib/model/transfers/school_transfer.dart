import '../enrollment/enrollment_models.dart';

class TransferChoice {
  const TransferChoice(this.id, this.label, {this.childId});
  final int id;
  final String label;
  final int? childId;
}

class IncomingSchoolTransfer {
  const IncomingSchoolTransfer(
      this.id, this.childId, this.sourceSchoolId, this.version);
  final int id, childId, sourceSchoolId, version;
  factory IncomingSchoolTransfer.fromJson(
      Map<String, dynamic> row, int school) {
    if (enrollmentId(row['destination_school_id']) != school ||
        row['status'] != 'pending_destination') {
      throw const FormatException('Transfer destination mismatch');
    }
    final source = enrollmentId(row['source_school_id']);
    if (source == school) throw const FormatException('Same-school transfer');
    return IncomingSchoolTransfer(enrollmentId(row['id']),
        enrollmentId(row['child_id']), source, enrollmentId(row['version']));
  }
}

class SchoolTransferDirectory {
  SchoolTransferDirectory(
      {required List<TransferChoice> enrollments,
      required List<TransferChoice> schools,
      required List<TransferChoice> sections,
      required List<IncomingSchoolTransfer> incoming})
      : enrollments = List.unmodifiable(enrollments),
        schools = List.unmodifiable(schools),
        sections = List.unmodifiable(sections),
        incoming = List.unmodifiable(incoming);
  final List<TransferChoice> enrollments, schools, sections;
  final List<IncomingSchoolTransfer> incoming;
}
