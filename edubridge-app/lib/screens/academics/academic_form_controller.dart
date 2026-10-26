import 'package:flutter/foundation.dart';

import '../../model/schools/academic_catalog.dart';
import '../../services/enrollment/enrollment_api_client.dart';

/// The form depends on authoring state, not a school-portal transport or tenant.
abstract interface class AcademicFormController implements Listenable {
  AcademicFormData? get snapshot;
  bool get canWrite;
  bool get busy;
  EnrollmentFailure? get error;
  Future<void> reload();
  Future<bool> create(AcademicDraft draft);
}
