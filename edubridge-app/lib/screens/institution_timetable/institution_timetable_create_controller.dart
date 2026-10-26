import '../../model/institutions/institution_timetable_draft.dart';
import '../../services/institution_timetable_repository.dart';
import '../enrollment/enrollment_state.dart';

class InstitutionTimetableCreateController extends EnrollmentState<TimetableCreationData> {
  InstitutionTimetableCreateController(this.writer) : super(writer.loadCreationData);
  final InstitutionTimetableCreator writer;
  int? createdId;
  Future<void> create(TimetableEntryDraft draft) => mutate(() async {
    createdId = await writer.createEntry(draft);
  });
}
