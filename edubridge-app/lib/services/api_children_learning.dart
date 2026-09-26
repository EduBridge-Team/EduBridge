// API implementations for children, evaluations, lessons, and progress.
part of 'api_service.dart';

Future<Map<String, dynamic>?> _apiGetChildren() async {
    try {
      final res = await ApiService.authGet('/children');
      final data = ApiService._decodeBody(res);
      if (res.statusCode == 200) {
        return data;
      }
      throw Exception(data['error'] ?? 'فشل جلب الأطفال');
    } catch (e) {
      ApiService._handleError(e);
    }
  }

Future<Map<String, dynamic>?> _apiAddChild({
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
  }) async {
    try {
      final token = await ApiService.getToken();
      final uri = Uri.parse('${Config.baseUrl}/children');

      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token';

      request.fields['name'] = name;
      request.fields['age'] = age.toString();
      if (disabilityType != null) {
        request.fields['disability_type'] = disabilityType;
      }
      if (disabilityDescription != null) {
        request.fields['disability_description'] = disabilityDescription;
      }
      if (specialNeeds != null) {
        request.fields['special_needs'] = specialNeeds;
      }
      if (preferredLearningStyle != null) {
        request.fields['preferred_learning_style'] =
            preferredLearningStyle;
      }
      if (strengths != null && strengths.isNotEmpty) {
        request.fields['strengths'] = jsonEncode(strengths);
      }
      if (challenges != null && challenges.isNotEmpty) {
        request.fields['challenges'] = jsonEncode(challenges);
      }

      if (idCardFile != null && await idCardFile.exists()) {
        request.files.add(
          await http.MultipartFile.fromPath(
              'id_card', idCardFile.path),
        );
      }
      if (birthCertFile != null && await birthCertFile.exists()) {
        request.files.add(
          await http.MultipartFile.fromPath(
              'birth_certificate', birthCertFile.path),
        );
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final data = ApiService.decodeMap(responseBody);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return ApiService._asStringMap(data['child']);
      }
      throw Exception(data['error'] ?? 'فشل إضافة الطفل');
    } catch (e) {
      ApiService._handleError(e);
    }
  }

Future<Map<String, dynamic>?> _apiGetChildDetails(int childId) async {
    try {
      final res = await ApiService.authGet('/children/$childId');
      final data = ApiService._decodeBody(res);
      if (res.statusCode == 200) {
        return ApiService._asStringMap(data['child']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

Future<Map<String, dynamic>?> _apiUpdateChild(
      int childId, Map<String, dynamic> data) async {
    try {
      final res = await ApiService.authPut('/children/$childId', data);
      final responseData = ApiService._decodeBody(res);
      if (res.statusCode == 200) {
        return ApiService._asStringMap(responseData['child']);
      }
      throw Exception(responseData['error'] ?? 'فشل تحديث بيانات الطفل');
    } catch (e) {
      ApiService._handleError(e);
    }
  }

Future<List<dynamic>> _apiGetChildLessons(int childId) async {
    try {
      final res = await ApiService.authGet('/children/$childId/lessons');
      final data = ApiService._decodeBody(res);
      if (res.statusCode == 200) {
        return data['lessons'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

Future<Map<String, dynamic>?> _apiEvaluateChild({
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
  }) async {
    try {
      final res = await ApiService.authPost('/evaluations/child/$childId', {
        'evaluation_type': evaluationType,
        'cognitive_assessment': cognitiveAssessment,
        'motor_assessment': motorAssessment,
        'emotional_assessment': emotionalAssessment,
        'social_assessment': socialAssessment,
        'recommendations': recommendations,
        'assigned_teacher_id': assignedTeacherId,
        'educational_plan': educationalPlan,
        'teaching_methods': teachingMethods,
      });

      final data = ApiService._decodeBody(res);
      if (res.statusCode == 200 || res.statusCode == 201) {
        return ApiService._asStringMap(data['evaluation']);
      }
      throw Exception(data['error'] ?? 'فشل تقييم الطفل');
    } catch (e) {
      ApiService._handleError(e);
    }
  }

Future<List<dynamic>> _apiGetChildEvaluations(int childId) async {
    try {
      final res = await ApiService.authGet('/evaluations/child/$childId');
      final data = ApiService._decodeBody(res);
      if (res.statusCode == 200) {
        return data['evaluations'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

Future<Map<String, dynamic>?> _apiAssignTeacherToChild(
      int childId, int teacherId) async {
    try {
      final res = await ApiService.authPost('/children/$childId/assign-teacher', {
        'teacher_id': teacherId,
      });

      final data = ApiService._decodeBody(res);
      if (res.statusCode == 200) {
        return data['child'];
      }
      throw Exception(data['error'] ?? 'فشل تعيين المعلم');
    } catch (e) {
      ApiService._handleError(e);
    }
  }

Future<List<dynamic>> _apiGetLessons() async {
    try {
      final res = await ApiService.authGet('/lessons');
      final data = ApiService._decodeBody(res);
      if (res.statusCode == 200) {
        return data['lessons'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

Future<Map<String, dynamic>?> _apiGetLessonDetails(
      int lessonId) async {
    try {
      final res = await ApiService.authGet('/lessons/$lessonId');
      final data = ApiService._decodeBody(res);
      if (res.statusCode == 200) {
        return ApiService._asStringMap(data['lesson']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

Future<Map<String, dynamic>?> _apiCreateLessonWithMedia({
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
  }) async {
    try {
      final token = await ApiService.getToken();
      final uri = Uri.parse('${Config.baseUrl}/lessons');

      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..fields['title'] = title;

      if (content != null && content.trim().isNotEmpty) {
        request.fields['content'] = content.trim();
      }
      if (disabilityTypeId != null) {
        request.fields['disability_type_id'] = disabilityTypeId.toString();
      }
      if (targetType != null) {
        request.fields['target_type'] = targetType;
      }
      if (targetChildIds != null && targetChildIds.isNotEmpty) {
        request.fields['target_child_ids'] = jsonEncode(targetChildIds);
      }
      if (audioDescription != null && audioDescription.trim().isNotEmpty) {
        request.fields['audio_description'] = audioDescription.trim();
      }

      if (imageFiles != null) {
        for (final image in imageFiles) {
          if (await image.exists()) {
            request.files.add(
              await http.MultipartFile.fromPath('images[]', image.path),
            );
          }
        }
      }

      if (videoFile != null && await videoFile.exists()) {
        request.files.add(
          await http.MultipartFile.fromPath('video', videoFile.path),
        );
      }
      if (audioFile != null && await audioFile.exists()) {
        request.files.add(
          await http.MultipartFile.fromPath('audio', audioFile.path),
        );
      }

      if (captionFile != null && await captionFile.exists()) {
        request.files.add(
          await http.MultipartFile.fromPath('caption', captionFile.path),
        );
      }
      if (signLanguageFile != null && await signLanguageFile.exists()) {
        request.files.add(
          await http.MultipartFile.fromPath(
              'sign_language', signLanguageFile.path),
        );
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final data = ApiService.decodeMap(responseBody);

      if (response.statusCode == 201) {
        return ApiService._asStringMap(data['lesson']);
      }
      throw Exception(data['error'] ?? 'فشل إنشاء الدرس');
    } catch (e) {
      ApiService._handleError(e);
    }
  }

Future<List<dynamic>> _apiGetDisabilityTypes() async {
    try {
      final res = await ApiService.authGet('/disability-types');
      final data = ApiService._decodeBody(res);
      if (res.statusCode == 200) {
        return data['disability_types'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

Future<Map<String, dynamic>?> _apiGetChildProgress(
      int childId) async {
    try {
      final res = await ApiService.authGet('/progress/child/$childId');
      final data = ApiService._decodeBody(res);
      if (res.statusCode == 200) return ApiService._asStringMap(data);
      return null;
    } catch (e) {
      return null;
    }
  }

Future<Map<String, dynamic>?> _apiGetChildProgressSummary(
      int childId) async {
    try {
      final res = await ApiService.authGet('/progress/child/$childId/summary');
      final data = ApiService._decodeBody(res);
      if (res.statusCode == 200) {
        return ApiService._asStringMap(data['summary']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

Future<Map<String, dynamic>?> _apiMarkLessonProgress({
    required int childId,
    required int lessonId,
    required String status,
    int? score,
  }) async {
    try {
      final res = await ApiService.authPost('/progress', {
        'child_id': childId,
        'lesson_id': lessonId,
        'status': status,
        'score': score,
      });

      final data = ApiService._decodeBody(res);
      if (res.statusCode == 200 || res.statusCode == 201) {
        return ApiService._asStringMap(data['progress']);
      }
      throw Exception(data['error'] ?? 'فشل تسجيل التقدم');
    } catch (e) {
      ApiService._handleError(e);
    }
  }
