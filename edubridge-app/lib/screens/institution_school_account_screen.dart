import 'package:flutter/material.dart';
import '../services/schools/school_account_repository.dart';
import 'schools/school_account_form.dart';

class InstitutionSchoolAccountScreen extends StatelessWidget {
  const InstitutionSchoolAccountScreen({super.key, this.repository});
  final SchoolAccountRepository? repository;

  @override
  Widget build(BuildContext context) => SchoolAccountForm(
    scope: SchoolAccountScope.affiliated,
    repository: repository,
  );
}
