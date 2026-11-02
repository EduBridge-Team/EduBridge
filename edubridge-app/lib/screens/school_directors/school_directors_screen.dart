import 'package:flutter/material.dart';
import '../../services/schools/school_director_repository.dart';
import 'school_director_appointment_screen.dart';
import 'school_director_profiles_screen.dart';

class SchoolDirectorsScreen extends StatelessWidget {
  const SchoolDirectorsScreen({super.key, this.gateway});
  final SchoolDirectorGateway? gateway;
  @override
  Widget build(BuildContext context) => gateway == null
      ? const SchoolDirectorAppointmentScreen()
      : SchoolDirectorProfilesScreen(gateway: gateway);
}
