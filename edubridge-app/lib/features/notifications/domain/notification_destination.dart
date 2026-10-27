enum NotificationChildDestination { enrollment, evaluations, weeklyReports }

/// Legacy notifications carry no resource identity. Never parse names, numbers,
/// body text, or URLs as a child/resource identifier.
NotificationChildDestination? notificationChildDestination(String type) => switch (type) {
  'school_enrollment' => NotificationChildDestination.enrollment,
  'child_evaluated' => NotificationChildDestination.evaluations,
  'weekly_report_created' => NotificationChildDestination.weeklyReports,
  _ => null,
};
class NotificationChild {
  const NotificationChild(this.id, this.name);
  final int id;
  final String name;
}
class NotificationChildDirectory {
  NotificationChildDirectory(this.userId, List<NotificationChild> children) : children = List.unmodifiable(children);
  final int userId;
  final List<NotificationChild> children;
}
