import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/malla_models.dart';
import '../../models/user_model.dart';
import '../../services/alertas_service.dart';
import '../../services/auth_service.dart';
import '../../services/malla_service.dart';

class MallaController extends GetxController {
  static const double cardWidth = 180;
  static const double cardHeight = 110;
  static const double columnGap = 40;
  static const double rowGap = 24;
  static const double padding = 24;
  static const double levelHeaderHeight = 32;
  static const double sectionLabelHeight = 36;
  static const double sectionGap = 80;

  final RxBool loading = true.obs;
  final RxList<CourseNode> cards = <CourseNode>[].obs;
  final RxMap<String, CourseStatus> statuses = <String, CourseStatus>{}.obs;
  final RxSet<String> updatingCourseIds = <String>{}.obs;
  final RxnString errorMessage = RxnString();
  final RxDouble zoom = 1.0.obs;
  final RxInt focusRequests = 0.obs;
  final RxInt renderTick = 0.obs;

  final _electiveNormRows = <String, int>{};
  String? _focusCourseId;
  int _mandatoryMaxRow = 0;
  int _electiveMaxRow = 0;

  late final MallaService _malla;
  late final AuthService _auth;

  UserModel? get user => _auth.currentUser;

  List<CourseNode> get mandatoryCards =>
      cards.where((course) => !course.isElective).toList();
  List<CourseNode> get electiveCards =>
      cards.where((course) => course.isElective).toList();

  double get _mandatorySectionBottom =>
      padding +
      sectionLabelHeight +
      levelHeaderHeight +
      (_mandatoryMaxRow + 1) * (cardHeight + rowGap);

  double get electiveSectionY => _mandatorySectionBottom + sectionGap;
  double get separatorY => _mandatorySectionBottom + sectionGap / 2;

  @override
  void onInit() {
    super.onInit();
    _malla = MallaService.to;
    _auth = AuthService.to;
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    loading.value = true;
    errorMessage.value = null;
    try {
      await _malla.load(force: true);
      _syncStateFromService();
    } catch (_) {
      errorMessage.value = 'No se pudo cargar la malla.';
      cards.clear();
      statuses.clear();
    } finally {
      loading.value = false;
    }
  }

  Future<void> reloadForUser() async {
    loading.value = true;
    errorMessage.value = null;
    try {
      await _malla.load(force: true);
      _syncStateFromService();
    } catch (_) {
      errorMessage.value = 'No se pudo actualizar la malla.';
    } finally {
      loading.value = false;
    }
  }

  void _syncStateFromService({bool updateFocusTarget = true}) {
    final currentUser = user;
    if (currentUser == null) {
      cards.clear();
      statuses.clear();
      _electiveNormRows.clear();
      return;
    }

    final visible = _malla.visibleCoursesFor(currentUser);
    cards.assignAll(visible);
    statuses.value = Map<String, CourseStatus>.from(
      _malla.computeStatuses(currentUser),
    );
    _computePoolLayout();
    if (updateFocusTarget) {
      _computeInitialFocusTarget();
    }
    _repaintCanvas();
  }

  void _computePoolLayout() {
    final mandatory = mandatoryCards;
    _mandatoryMaxRow = mandatory.isEmpty
        ? 0
        : mandatory.map((course) => course.row).reduce(max);

    _electiveNormRows.clear();
    final byLevel = <int, List<CourseNode>>{};
    for (final course in electiveCards) {
      byLevel.putIfAbsent(course.level, () => []).add(course);
    }

    _electiveMaxRow = 0;
    for (final levelCourses in byLevel.values) {
      levelCourses.sort((a, b) => a.row.compareTo(b.row));
      for (var index = 0; index < levelCourses.length; index++) {
        _electiveNormRows[levelCourses[index].id] = index;
        if (index > _electiveMaxRow) _electiveMaxRow = index;
      }
    }
  }

  void _computeInitialFocusTarget() {
    final level = currentStudentLevel;
    if (level == null) {
      _focusCourseId = null;
      return;
    }

    final target =
        mandatoryCards
            .where(
              (course) =>
                  course.level == level &&
                  statuses[course.id] != CourseStatus.approved,
            )
            .toList()
          ..sort((a, b) => a.row.compareTo(b.row));

    _focusCourseId = target.isEmpty ? null : target.first.id;
  }

  Offset positionFor(CourseNode course) {
    final x = padding + (course.level - 1) * (cardWidth + columnGap);
    if (!course.isElective) {
      return Offset(
        x,
        padding +
            sectionLabelHeight +
            levelHeaderHeight +
            course.row * (cardHeight + rowGap),
      );
    }

    final normalizedRow = _electiveNormRows[course.id] ?? 0;
    return Offset(
      x,
      electiveSectionY +
          levelHeaderHeight +
          normalizedRow * (cardHeight + rowGap),
    );
  }

  int? get currentStudentLevel {
    final rawLevel = _malla.lastPayload?['currentLevel'];
    if (rawLevel is num && rawLevel > 0) return rawLevel.toInt();
    return user?.courseProgress?.currentLevel;
  }

  Offset? focusOffsetForCurrentLevel() {
    final level = currentStudentLevel;
    if (level == null) return null;

    final targetId = _focusCourseId;
    if (targetId != null) {
      final target = mandatoryCards.firstWhereOrNull(
        (course) => course.id == targetId,
      );
      if (target != null) return positionFor(target);
    }

    return Offset(
      padding + (level - 1) * (cardWidth + columnGap),
      padding + sectionLabelHeight + levelHeaderHeight,
    );
  }

  bool isUpdating(String courseId) => updatingCourseIds.contains(courseId);

  void _repaintCanvas() => renderTick.value++;

  CourseStatus _nextStatus(CourseStatus current) {
    return switch (current) {
      CourseStatus.unlocked => CourseStatus.current,
      CourseStatus.current => CourseStatus.approved,
      CourseStatus.approved => CourseStatus.unlocked,
      CourseStatus.locked => CourseStatus.locked,
    };
  }

  Size canvasSize() {
    if (cards.isEmpty) return const Size(1200, 800);
    final maxLevel = cards.map((course) => course.level).reduce(max);
    final width = padding * 2 + maxLevel * (cardWidth + columnGap);
    final height = electiveCards.isEmpty
        ? _mandatorySectionBottom + padding
        : electiveSectionY +
              levelHeaderHeight +
              (_electiveMaxRow + 1) * (cardHeight + rowGap) +
              padding;
    return Size(width, height);
  }

  Future<void> cycleStatus(String courseId) async {
    if (updatingCourseIds.contains(courseId)) return;

    final previous = statuses[courseId] ?? CourseStatus.locked;
    if (previous == CourseStatus.locked) return;

    final next = _nextStatus(previous);

    _markCourseAsUpdating(courseId);
    _setVisibleStatus(courseId, next);
    unawaited(_persistStatusChange(courseId, previous, next));
  }

  Future<void> _persistStatusChange(
    String courseId,
    CourseStatus previous,
    CourseStatus next,
  ) async {
    try {
      final savedStatus = await _malla
          .updateCourseStatus(courseId: courseId, nextStatus: next)
          .timeout(const Duration(seconds: 8));
      _setVisibleStatus(courseId, savedStatus);
      _markCourseAsReady(courseId);

      unawaited(_reloadAfterSimulationSave());
    } catch (_) {
      _setVisibleStatus(courseId, previous);
      _markCourseAsReady(courseId);
      Get.snackbar('Malla', 'No se pudo actualizar el estado del curso.');
    }
  }

  Future<void> _reloadAfterSimulationSave() async {
    try {
      await _malla.load(force: true).timeout(const Duration(seconds: 8));
      _syncStateFromService(updateFocusTarget: false);
      if (Get.isRegistered<AlertasService>()) {
        unawaited(AlertasService.to.generarAlertas());
      }
    } catch (_) {
      Get.snackbar('Malla', 'Estado guardado. No se pudo recalcular la malla.');
    }
  }

  int get approvedCount =>
      statuses.values.where((status) => status == CourseStatus.approved).length;
  int get currentCount =>
      statuses.values.where((status) => status == CourseStatus.current).length;
  int get unlockedCount =>
      statuses.values.where((status) => status == CourseStatus.unlocked).length;
  int get totalVisible => cards.length;

  double get approvedRatio =>
      totalVisible == 0 ? 0 : approvedCount / totalVisible;

  void zoomIn() => zoom.value = (zoom.value + 0.1).clamp(0.5, 1.6);
  void zoomOut() => zoom.value = (zoom.value - 0.1).clamp(0.5, 1.6);
  void resetZoom() {
    zoom.value = 1.0;
    focusRequests.value++;
  }

  void _setVisibleStatus(String courseId, CourseStatus status) {
    statuses[courseId] = status;
    statuses.refresh();
    _repaintCanvas();
  }

  void _markCourseAsUpdating(String courseId) {
    updatingCourseIds.add(courseId);
    updatingCourseIds.refresh();
  }

  void _markCourseAsReady(String courseId) {
    updatingCourseIds.remove(courseId);
    updatingCourseIds.refresh();
  }
}
