import 'package:get/get.dart';

import '../models/malla_models.dart';
import '../models/user_model.dart';
import 'api_client.dart';

class MallaService extends GetxService {
  static MallaService get to => Get.find();

  static const String _mallaPath = '/api/v1/malla';
  static const String _simulationPath =
      '/api/v1/malla/simulation/course-status';
  static const String _clearSimulationPath = '/api/v1/malla/simulation';

  final ApiClient _apiClient = ApiClient();
  final RxList<CourseNode> _courses = <CourseNode>[].obs;
  final RxMap<String, CourseStatus> _statuses = <String, CourseStatus>{}.obs;
  Map<String, dynamic>? _lastPayload;

  List<CourseNode> get courses => _courses;
  Map<String, CourseStatus> get statuses =>
      Map<String, CourseStatus>.from(_statuses);
  Map<String, dynamic>? get lastPayload => _lastPayload;

  Future<void> load({bool force = false}) async {
    if (_courses.isNotEmpty && !force) return;

    final response = await _apiClient.getJson(_mallaPath);
    final data = response['data'] as Map<String, dynamic>?;
    final parsedCourses = _parseCourses(data?['courses']);

    _lastPayload = data;
    _courses.assignAll(parsedCourses);
    _statuses.assignAll(_statusMapFromCourses(parsedCourses));
  }

  Future<CourseStatus> updateCourseStatus({
    required String courseId,
    required CourseStatus nextStatus,
  }) async {
    final response = await _apiClient.putJson(
      _simulationPath,
      body: {
        'curriculumCourseId': courseId,
        'status': courseStatusToApiValue(nextStatus),
      },
    );
    final data = response['data'] as Map<String, dynamic>?;
    final updatedStatus = courseStatusFromJson(data?['status']);
    _statuses[courseId] = updatedStatus;
    return updatedStatus;
  }

  Future<void> clearSimulation() async {
    await _apiClient.deleteJson(_clearSimulationPath);
    await load(force: true);
  }

  Map<String, CourseStatus> computeStatuses(UserModel user) {
    return Map<String, CourseStatus>.from(_statuses);
  }

  List<CourseNode> visibleCoursesFor(UserModel user) {
    return List<CourseNode>.from(_courses);
  }

  List<CourseNode> _parseCourses(Object? rawCourses) {
    return ((rawCourses as List?) ?? const [])
        .map((item) => CourseNode.fromApiJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Map<String, CourseStatus> _statusMapFromCourses(List<CourseNode> courses) {
    return {for (final course in courses) course.id: course.status};
  }
}
