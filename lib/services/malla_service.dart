import 'package:get/get.dart';

import '../models/malla_models.dart';
import '../models/user_model.dart';
import 'api_client.dart';

class MallaService extends GetxService {
  static MallaService get to => Get.find();

  final ApiClient _apiClient = ApiClient();
  final RxList<CourseNode> _courses = <CourseNode>[].obs;
  final RxMap<String, CourseStatus> _statuses = <String, CourseStatus>{}.obs;
  Map<String, dynamic>? _lastPayload;

  List<CourseNode> get courses => _courses;
  Map<String, CourseStatus> get statuses => Map.unmodifiable(_statuses);
  Map<String, dynamic>? get lastPayload => _lastPayload;

  Future<void> load({bool force = false}) async {
    if (_courses.isNotEmpty && !force) return;

    final response = await _apiClient.getJson('/api/v1/malla');
    final data = response['data'] as Map<String, dynamic>?;
    final rawCourses = (data?['courses'] as List?) ?? const [];
    final parsedCourses = rawCourses
        .map((item) => CourseNode.fromApiJson(Map<String, dynamic>.from(item)))
        .toList();

    _lastPayload = data;
    _courses.assignAll(parsedCourses);
    _statuses.assignAll({
      for (final course in parsedCourses) course.id: course.status,
    });
  }

  Future<CourseStatus> updateCourseStatus({
    required String courseId,
    required CourseStatus nextStatus,
  }) async {
    final response = await _apiClient.putJson(
      '/api/v1/malla/simulation/course-status',
      body: {
        'curriculumCourseId': courseId,
        'status': courseStatusToApiValue(nextStatus),
      },
    );
    final data = response['data'] as Map<String, dynamic>?;
    final updatedStatus = courseStatusFromJson(data?['status']);
    await load(force: true);
    return updatedStatus;
  }

  Future<void> clearSimulation() async {
    await _apiClient.deleteJson('/api/v1/malla/simulation');
    await load(force: true);
  }

  Map<String, CourseStatus> computeStatuses(UserModel user) {
    return statuses;
  }

  List<CourseNode> visibleCoursesFor(UserModel user) {
    return List<CourseNode>.unmodifiable(_courses);
  }
}
