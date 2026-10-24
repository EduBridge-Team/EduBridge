import 'package:flutter/material.dart';
import '../../services/schools/school_account_repository.dart';
import '../schools/school_account_form.dart';

class AdminSchoolCreatePage extends StatelessWidget {
  const AdminSchoolCreatePage({super.key, this.repository});
  final SchoolAccountRepository? repository;

  @override
  Widget build(BuildContext context) => SchoolAccountForm(
    scope: SchoolAccountScope.independent,
    repository: repository,
  );
}
