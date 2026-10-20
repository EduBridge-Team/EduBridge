import 'package:intl/intl.dart';
import '../l10n/generated/app_localizations.dart';
import '../model/learning_support_request_model.dart';
import '../model/learning_support_meeting_model.dart';

enum LearningSupportError { requestsLoad, meetingsLoad, reasonRequired, createFailed, dateTimeRequired, linkRequired, scheduleFailed }

/// Localized display labels only. Never use these labels as API values.
class LearningSupportPresentation {
  static const reasons = [
    'صعوبة في فهم الدروس',
    'تراجع في التقدم الدراسي',
    'صعوبة في التركيز أثناء التعلم',
    'الحاجة إلى تكييف طريقة عرض المحتوى',
    'صعوبة في التواصل داخل البيئة التعليمية',
    'الحاجة إلى خطة متابعة فردية',
    'صعوبة في إنجاز الواجبات',
    'الحاجة إلى دعم في مهارات الدراسة',
    'التنسيق بين الأسرة والفريق التعليمي',
    'أخرى',
  ];

  static String reason(String value, AppLocalizations strings) => switch (value) {
    'صعوبة في فهم الدروس' => strings.reasonUnderstandingLessons,
    'تراجع في التقدم الدراسي' => strings.supportReasonProgress,
    'صعوبة في التركيز أثناء التعلم' => strings.supportReasonFocus,
    'الحاجة إلى تكييف طريقة عرض المحتوى' => strings.supportReasonPresentation,
    'صعوبة في التواصل داخل البيئة التعليمية' => strings.reasonLearningCommunication,
    'الحاجة إلى خطة متابعة فردية' => strings.supportReasonIndividualPlan,
    'صعوبة في إنجاز الواجبات' => strings.supportReasonHomework,
    'الحاجة إلى دعم في مهارات الدراسة' => strings.supportReasonStudySkills,
    'التنسيق بين الأسرة والفريق التعليمي' => strings.supportReasonFamilyCoordination,
    'أخرى' => strings.otherDisability,
    _ => value,
  };

  static String urgency(String value, AppLocalizations strings) => switch (value) {
    'high' => strings.supportPriorityHighLabel,
    'low' => strings.supportPriorityLowLabel,
    _ => strings.supportPriorityMediumLabel,
  };

  static String requestStatus(LearningSupportRequestStatus value, AppLocalizations strings) => switch (value) {
    LearningSupportRequestStatus.pending => strings.underReview,
    LearningSupportRequestStatus.scheduled => strings.supportAppointmentSet,
    LearningSupportRequestStatus.completed => strings.supportCompleted,
    LearningSupportRequestStatus.cancelled => strings.supportCancelled,
  };

  static String meetingType(LearningSupportMeetingType value, AppLocalizations strings) => switch (value) {
    LearningSupportMeetingType.learningPlanning => strings.supportPlanning,
    LearningSupportMeetingType.followUp => strings.followUpEvaluation,
    LearningSupportMeetingType.teamReview => strings.supportTeamReview,
    LearningSupportMeetingType.parentReview => strings.supportParentReview,
    LearningSupportMeetingType.groupSupport => strings.supportGroup,
  };

  static String meetingStatus(LearningSupportMeetingStatus value, AppLocalizations strings) => switch (value) {
    LearningSupportMeetingStatus.scheduled => strings.supportScheduled,
    LearningSupportMeetingStatus.completed => strings.supportCompleted,
    LearningSupportMeetingStatus.cancelled => strings.supportCancelled,
    LearningSupportMeetingStatus.noShow => strings.supportNoShow,
  };

  static String error(LearningSupportError value, AppLocalizations strings) => switch (value) {
    LearningSupportError.requestsLoad => strings.supportRequestsLoadFailed,
    LearningSupportError.meetingsLoad => strings.supportMeetingsLoadFailed,
    LearningSupportError.reasonRequired => strings.supportReasonRequired,
    LearningSupportError.createFailed => strings.supportCreateFailed,
    LearningSupportError.dateTimeRequired => strings.supportDateTimeRequired,
    LearningSupportError.linkRequired => strings.supportLinkRequired,
    LearningSupportError.scheduleFailed => strings.supportScheduleFailed,
  };

  static String date(DateTime value, AppLocalizations strings) =>
      DateFormat.yMMMd(strings.localeName).add_Hm().format(value);
}
