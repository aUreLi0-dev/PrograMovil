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

  final loading = true.obs;
  final cards = <CourseNode>[].obs;
  final statuses = <String, CourseStatus>{}.obs;
  final errorMessage = RxnString();
  final zoom = 1.0.obs;
  final focusRequests = 0.obs;

  final _electiveNormRows = <String, int>{};
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
      _refresh();
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
      _refresh();
    } catch (_) {
      errorMessage.value = 'No se pudo actualizar la malla.';
    } finally {
      loading.value = false;
    }
  }

  void _refresh() {
    final currentUser = user;
    if (currentUser == null) {
      cards.clear();
      statuses.clear();
      _electiveNormRows.clear();
      return;
    }

    final visible = _malla.visibleCoursesFor(currentUser);
    cards.assignAll(visible);
    statuses.assignAll(_malla.computeStatuses(currentUser));
    _computePoolLayout();
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

    final target =
        mandatoryCards
            .where(
              (course) =>
                  course.level == level &&
                  statuses[course.id] != CourseStatus.approved,
            )
            .toList()
          ..sort((a, b) => a.row.compareTo(b.row));

    if (target.isNotEmpty) return positionFor(target.first);

    return Offset(
      padding + (level - 1) * (cardWidth + columnGap),
      padding + sectionLabelHeight + levelHeaderHeight,
    );
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
    final current = statuses[courseId] ?? CourseStatus.locked;
    if (current == CourseStatus.locked) return;

    final next = switch (current) {
      CourseStatus.unlocked => CourseStatus.current,
      CourseStatus.current => CourseStatus.approved,
      CourseStatus.approved => CourseStatus.unlocked,
      CourseStatus.locked => CourseStatus.locked,
    };
    if (next == CourseStatus.locked) return;

    loading.value = true;
    errorMessage.value = null;
    try {
      await _malla.updateCourseStatus(courseId: courseId, nextStatus: next);
      _refresh();
      if (Get.isRegistered<AlertasService>()) {
        AlertasService.to.generarAlertas();
      }
    } catch (_) {
      errorMessage.value = 'No se pudo actualizar el estado del curso.';
      Get.snackbar('Malla', errorMessage.value!);
    } finally {
      loading.value = false;
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
}
