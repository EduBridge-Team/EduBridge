// lib/services/api_service.dart
// طبقة الاتصال بالـ API - كاملة ومتكاملة
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import 'websocket_service.dart';
import 'notification_listener_service.dart';

part 'api_core.dart';
part 'api_children_learning.dart';
part 'api_communication_users.dart';
part 'api_ministry.dart';
part 'api_homework_support.dart';
part 'api_profile_collaboration.dart';

class ApiService {
  static final ValueNotifier<bool> isAuthenticated = ValueNotifier(false);
  static final ValueNotifier<String?> userRole = ValueNotifier<String?>(null);

  static Future<void> initializeAuthState() => _apiCoreInitializeAuthState();

  // ═══════════════════════════════════════════════════════════
  //  معالج أخطاء موحّد
  // ═══════════════════════════════════════════════════════════
  static Never _handleError(Object error) => _apiCoreHandleError(error);

  static Map<String, dynamic> _decodeBody(http.Response res) => _apiCoreDecodeBody(res);

  // ═══════════════════════════════════════════════════════════
  //  ✅ Helpers عامة — استخدمها في الشاشات بدل jsonDecode
  // ═══════════════════════════════════════════════════════════

  /// فكّ JSON كـ Map بأمان — لا يفشل أبداً
  static Map<String, dynamic> decodeMap(String body) => _apiCoreDecodeMap(body);

  /// فكّ JSON كـ List بأمان
  static List<dynamic> decodeList(String body) => _apiCoreDecodeList(body);

  /// استخرج مفتاح من JSON كـ List بأمان
  /// مثال: ApiService.extractList(body, 'lessons')
  static List<dynamic> extractList(String body, String key) => _apiCoreExtractList(body, key);

  /// استخرج مفتاح من JSON كـ Map بأمان
  /// مثال: ApiService.extractMap(body, 'summary')
  static Map<String, dynamic>? extractMap(String body, String key) => _apiCoreExtractMap(body, key);

  // ═══════════════════════════════════════════════════════════
  //  ✅ Helper: تحويل آمن لأي Map من JSON إلى Map<String, dynamic>
  // ═══════════════════════════════════════════════════════════
  static Map<String, dynamic>? _asStringMap(dynamic value) => _apiCoreAsStringMap(value);

  // ===== دوال التخزين المحلي =====

  static Future<void> _saveToken(String token) => _apiCoreSaveToken(token);

  static Future<String?> getToken() => _apiCoreGetToken();

  static Future<void> saveUserData(Map<String, dynamic> user) => _apiCoreSaveUserData(user);

  static Future<String?> getRole() => _apiCoreGetRole();

  static Future<String?> getName() => _apiCoreGetName();

  static Future<int?> getUserId() => _apiCoreGetUserId();

  static Future<void> logout() => _apiCoreLogout();

  // ===== دوال المصادقة (Auth) =====

  static Future<String?> login(String email, String password) => _apiCoreLogin(email, password);

  static Future<String?> register(
      String name, String email, String password, String role,
      {String? phone, String? specialty}) =>
      _apiCoreRegister(name, email, password, role, phone: phone, specialty: specialty);

  static Future<bool> verifyToken() => _apiCoreVerifyToken();

  // ===== دوال الطلبات المحمية =====

  static Future<http.Response> authGet(String path) => _apiCoreAuthGet(path);

  static Future<http.Response> authPost(
      String path, Map<String, dynamic> body) =>
      _apiCoreAuthPost(path, body);

  static Future<http.Response> authPut(
      String path, Map<String, dynamic> body) =>
      _apiCoreAuthPut(path, body);

  static Future<http.Response> authDelete(String path) => _apiCoreAuthDelete(path);

  // Domain API facade. Implementations live in focused part files.
    static Future<Map<String, dynamic>?> getChildren() => _api_getChildren();

    static Future<Map<String, dynamic>?> addChild({
    required String name,
    required int age,
    String? disabilityType,
    String? disabilityDescription,
    String? specialNeeds,
    String? preferredLearningStyle,
    List<String>? strengths,
    List<String>? challenges,
    File? idCardFile,
    File? birthCertFile,
  }) => _api_addChild(name: name, age: age, disabilityType: disabilityType, disabilityDescription: disabilityDescription, specialNeeds: specialNeeds, preferredLearningStyle: preferredLearningStyle, strengths: strengths, challenges: challenges, idCardFile: idCardFile, birthCertFile: birthCertFile);

    static Future<Map<String, dynamic>?> getChildDetails(int childId) => _api_getChildDetails(childId);

    static Future<Map<String, dynamic>?> updateChild(
      int childId, Map<String, dynamic> data) => _api_updateChild(childId, data);

    static Future<List<dynamic>> getChildLessons(int childId) => _api_getChildLessons(childId);

    static Future<Map<String, dynamic>?> evaluateChild({
    required int childId,
    required String evaluationType,
    required String cognitiveAssessment,
    required String motorAssessment,
    required String emotionalAssessment,
    required String socialAssessment,
    required String recommendations,
    int? assignedTeacherId,
    required String educationalPlan,
    required List<String> teachingMethods,
  }) => _api_evaluateChild(childId: childId, evaluationType: evaluationType, cognitiveAssessment: cognitiveAssessment, motorAssessment: motorAssessment, emotionalAssessment: emotionalAssessment, socialAssessment: socialAssessment, recommendations: recommendations, assignedTeacherId: assignedTeacherId, educationalPlan: educationalPlan, teachingMethods: teachingMethods);

    static Future<List<dynamic>> getChildEvaluations(int childId) => _api_getChildEvaluations(childId);

    static Future<Map<String, dynamic>?> assignTeacherToChild(
      int childId, int teacherId) => _api_assignTeacherToChild(childId, teacherId);

    static Future<List<dynamic>> getLessons() => _api_getLessons();

    static Future<Map<String, dynamic>?> getLessonDetails(
      int lessonId) => _api_getLessonDetails(lessonId);

    static Future<Map<String, dynamic>?> createLessonWithMedia({
    required String title,
    String? content,
    int? disabilityTypeId,
    List<File>? imageFiles,
    File? videoFile,
    File? audioFile,
    File? captionFile,
    File? signLanguageFile,
    String? audioDescription,
    String? targetType,
    List<int>? targetChildIds,
  }) => _api_createLessonWithMedia(title: title, content: content, disabilityTypeId: disabilityTypeId, imageFiles: imageFiles, videoFile: videoFile, audioFile: audioFile, captionFile: captionFile, signLanguageFile: signLanguageFile, audioDescription: audioDescription, targetType: targetType, targetChildIds: targetChildIds);

    static Future<List<dynamic>> getDisabilityTypes() => _api_getDisabilityTypes();

    static Future<Map<String, dynamic>?> getChildProgress(
      int childId) => _api_getChildProgress(childId);

    static Future<Map<String, dynamic>?> getChildProgressSummary(
      int childId) => _api_getChildProgressSummary(childId);

    static Future<Map<String, dynamic>?> markLessonProgress({
    required int childId,
    required int lessonId,
    required String status,
    int? score,
  }) => _api_markLessonProgress(childId: childId, lessonId: lessonId, status: status, score: score);

    static Future<List<dynamic>> getNotifications() => _api_getNotifications();

    static Future<int> getUnreadNotificationsCount() => _api_getUnreadNotificationsCount();

    static Future<void> markNotificationRead(int notificationId) => _api_markNotificationRead(notificationId);

    static Future<void> markAllNotificationsRead() => _api_markAllNotificationsRead();

    static Future<List<dynamic>> getConversations() => _api_getConversations();

    static Future<List<dynamic>> getMessages(int conversationId) => _api_getMessages(conversationId);

    static Future<void> sendMessage({
    required int conversationId,
    required String content,
    String? fileUrl,
  }) => _api_sendMessage(conversationId: conversationId, content: content, fileUrl: fileUrl);

    static Future<int> createConversation(
      int otherUserId, String subject) => _api_createConversation(otherUserId, subject);

    static Future<List<dynamic>> getConversationUsers() => _api_getConversationUsers();

    static Future<List<dynamic>> getUsers({String? role}) => _api_getUsers(role: role);

    static Future<List<dynamic>> getTeachers() => _api_getTeachers();

    static Future<List<dynamic>> getSpecialists() => _api_getSpecialists();

    static Future<List<dynamic>> getParents() => _api_getParents();

    static Future<Map<String, dynamic>?> updateUser(
      int userId, Map<String, dynamic> data) => _api_updateUser(userId, data);

    static Future<bool> deleteUser(int userId) => _api_deleteUser(userId);

    static Future<Map<String, dynamic>?> getDashboardStats() => _api_getDashboardStats();

    static Future<List<dynamic>> searchLessons(String query) => _api_searchLessons(query);

    static Future<String?> getVerificationStatus() => _api_getVerificationStatus();

    static Future<void> submitIdentityVerification({
    required String nationalId,
    required File idImage,
  }) => _api_submitIdentityVerification(nationalId: nationalId, idImage: idImage);

    static Future<bool> isVerified() => _api_isVerified();

    static Future<List<dynamic>> getVerificationRequests() => _api_getVerificationRequests();

    static Future<bool> approveVerification(int requestId) => _api_approveVerification(requestId);

    static Future<bool> rejectVerification(int requestId) => _api_rejectVerification(requestId);

    static Future<List<dynamic>> searchByIdentity(String query) => _api_searchByIdentity(query);

    static Future<void> submitCertificate({
    required String title,
    required File file,
  }) => _api_submitCertificate(title: title, file: file);

    static Future<void> requestConsultation({
    required int childId,
    required String title,
    required String description,
  }) => _api_requestConsultation(childId: childId, title: title, description: description);

    static Future<Map<String, dynamic>?> submitForMinistryApproval({
    required int childId,
    required int evaluationId,
    required String educationalPlan,
    required String cognitiveAssessment,
    required String motorAssessment,
    required String emotionalAssessment,
    required String socialAssessment,
    required String recommendations,
    required List<String> teachingMethods,
    int? teacherId,
  }) => _api_submitForMinistryApproval(childId: childId, evaluationId: evaluationId, educationalPlan: educationalPlan, cognitiveAssessment: cognitiveAssessment, motorAssessment: motorAssessment, emotionalAssessment: emotionalAssessment, socialAssessment: socialAssessment, recommendations: recommendations, teachingMethods: teachingMethods, teacherId: teacherId);

    static Future<List<dynamic>> getPendingApprovals() => _api_getPendingApprovals();

    static Future<List<dynamic>> getAllApprovals({String? status}) => _api_getAllApprovals(status: status);

    static Future<bool> approveMinistryRequest(int approvalId) => _api_approveMinistryRequest(approvalId);

    static Future<bool> rejectMinistryRequest(
    int approvalId, {
    String? reason,
  }) => _api_rejectMinistryRequest(approvalId, reason: reason);

    static Future<List<dynamic>> getApprovalNotifications() => _api_getApprovalNotifications();

    static Future<String> getChildPlanStatus(int childId) => _api_getChildPlanStatus(childId);

    static Future<List<dynamic>> getMinistryUsers() => _api_getMinistryUsers();

    static Future<List<dynamic>> getMinistryChildren() => _api_getMinistryChildren();

    static Future<Map<String, dynamic>?> getMinistryStats() => _api_getMinistryStats();

    static Future<List<dynamic>> getHomeworks({int? childId}) => _api_getHomeworks(childId: childId);

    static Future<Map<String, dynamic>?> createHomework({
    required String title,
    required String description,
    required DateTime dueDate,
    String? subject,
    required List<int> assignedChildIds,
    List<File>? attachments,
  }) => _api_createHomework(title: title, description: description, dueDate: dueDate, subject: subject, assignedChildIds: assignedChildIds, attachments: attachments);

    static Future<Map<String, dynamic>?> submitHomework({
    required int homeworkId,
    required int childId,
    String? textAnswer,
    File? file,
    List<File>? files,
  }) => _api_submitHomework(homeworkId: homeworkId, childId: childId, textAnswer: textAnswer, file: file, files: files);

    static Future<bool> gradeHomework({
    required int submissionId,
    required int grade,
    String? feedback,
  }) => _api_gradeHomework(submissionId: submissionId, grade: grade, feedback: feedback);

    static Future<List<dynamic>> getLearningSupportMeetings({int? childId}) => _api_getLearningSupportMeetings(childId: childId);

    static Future<Map<String, dynamic>?> createLearningSupportMeeting({
    required int childId,
    required String type,
    required DateTime scheduledAt,
    int durationMinutes = 45,
    String? goals,
  }) => _api_createLearningSupportMeeting(childId: childId, type: type, scheduledAt: scheduledAt, durationMinutes: durationMinutes, goals: goals);

    static Future<bool> completeLearningSupportMeeting({
    required int sessionId,
    required String notes,
    required String recommendations,
    int? moodRating,
    List<String>? tags,
  }) => _api_completeLearningSupportMeeting(sessionId: sessionId, notes: notes, recommendations: recommendations, moodRating: moodRating, tags: tags);

    static Future<Map<String, dynamic>?> getWeeklyReport({
    required int childId,
    DateTime? weekStart,
  }) => _api_getWeeklyReport(childId: childId, weekStart: weekStart);

    static Future<List<dynamic>> getChildWeeklyReports(int childId) => _api_getChildWeeklyReports(childId);

    static Future<Map<String, dynamic>?> getCareTeam(int childId) => _api_getCareTeam(childId);

    static Future<bool> addCareTeamMember({
    required int childId,
    required int userId,
    required String role,
    String? specialty,
    String? subject,
  }) => _api_addCareTeamMember(childId: childId, userId: userId, role: role, specialty: specialty, subject: subject);

    static Future<bool> removeCareTeamMember({
    required int childId,
    required int userId,
  }) => _api_removeCareTeamMember(childId: childId, userId: userId);

    static Future<bool> evaluatePlanAppropriateness({
    required int childId,
    required int planId,
    required bool isAppropriate,
    String? notesForTeacher,
    List<String>? recommendedChanges,
  }) => _api_evaluatePlanAppropriateness(childId: childId, planId: planId, isAppropriate: isAppropriate, notesForTeacher: notesForTeacher, recommendedChanges: recommendedChanges);

    static Future<Map<String, dynamic>?> getMinistryStatistics() => _api_getMinistryStatistics();

    static Future<Map<String, dynamic>?> getMinistryProgressStats() => _api_getMinistryProgressStats();

    static Future<Map<String, dynamic>?> createLearningSupportRequest({
    required int childId,
    required String reason,
    String? description,
    String urgency = 'medium',
  }) => _api_createLearningSupportRequest(childId: childId, reason: reason, description: description, urgency: urgency);

    static Future<List<dynamic>> getLearningSupportRequests({
    int? childId,
    String? status,
  }) => _api_getLearningSupportRequests(childId: childId, status: status);

    static Future<bool> hasPendingLearningSupportRequest(int childId) => _api_hasPendingLearningSupportRequest(childId);

    static Future<bool> scheduleLearningSupportRequest({
    required int requestId,
    required DateTime scheduledAt,
    required String meetingLink,
    String? notes,
  }) => _api_scheduleLearningSupportRequest(requestId: requestId, scheduledAt: scheduledAt, meetingLink: meetingLink, notes: notes);

    static Future<bool> cancelLearningSupportRequest(int requestId) => _api_cancelLearningSupportRequest(requestId);

    static Future<Map<String, dynamic>?> getProfile() => _api_getProfile();

    static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => _api_changePassword(currentPassword: currentPassword, newPassword: newPassword);

    static Future<String?> uploadProfilePicture(File image) => _api_uploadProfilePicture(image);

    static Future<bool> removeProfilePicture() => _api_removeProfilePicture();

    static Future<String?> getSavedAvatarUrl() => _api_getSavedAvatarUrl();

    static Future<void> saveAvatarUrl(String? url) => _api_saveAvatarUrl(url);

    static Future<bool> addTeacherToChild({
    required int childId,
    required int teacherId,
  }) => _api_addTeacherToChild(childId: childId, teacherId: teacherId);

    static Future<bool> removeTeacherFromChild({
    required int childId,
    required int teacherId,
  }) => _api_removeTeacherFromChild(childId: childId, teacherId: teacherId);

    static Future<List<dynamic>> getChildTeachers(int childId) => _api_getChildTeachers(childId);

    static Future<Map<String, dynamic>?> getChildSpecialists(
      int childId) => _api_getChildSpecialists(childId);

    static Future<String?> assignSpecialist({
    required int childId,
    required int specialistId,
    required String specialty,
  }) => _api_assignSpecialist(childId: childId, specialistId: specialistId, specialty: specialty);

    static Future<bool> removeSpecialist({
    required int childId,
    required int specialistId,
  }) => _api_removeSpecialist(childId: childId, specialistId: specialistId);

    static Future<List<dynamic>> getCaseDiscussions({int? childId}) => _api_getCaseDiscussions(childId: childId);

    static Future<Map<String, dynamic>?> createCaseDiscussion({
    required int childId,
    required String topic,
    String? description,
    required List<int> participantIds,
  }) => _api_createCaseDiscussion(childId: childId, topic: topic, description: description, participantIds: participantIds);

    static Future<Map<String, dynamic>?> getCaseDiscussionDetails(
      int discussionId) => _api_getCaseDiscussionDetails(discussionId);

    static Future<Map<String, dynamic>?> addCaseMessage({
    required int discussionId,
    required String content,
    String type = 'text',
  }) => _api_addCaseMessage(discussionId: discussionId, content: content, type: type);

    static Future<bool> resolveCaseDiscussion(int discussionId) => _api_resolveCaseDiscussion(discussionId);

    static Future<String?> suggestSpecialistToChild({
    required int childId,
    required int specialistId,
    required String specialty,
    required String reason,
  }) => _api_suggestSpecialistToChild(childId: childId, specialistId: specialistId, specialty: specialty, reason: reason);

    static Future<List<dynamic>> getMySpecialistSuggestions({
    String? status,
  }) => _api_getMySpecialistSuggestions(status: status);

    static Future<String?> acceptSuggestion(int suggestionId) => _api_acceptSuggestion(suggestionId);

    static Future<String?> rejectSuggestion(
    int suggestionId, {
    String? reason,
  }) => _api_rejectSuggestion(suggestionId, reason: reason);

    static Future<void> deleteAccount() => _api_deleteAccount();
}
