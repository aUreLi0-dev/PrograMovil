import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/curso_delegado_model.dart';
import '../models/section_representative_model.dart';
import 'api_client.dart';
import 'enrollment_service.dart';

class SectionRepresentativeService {
  static final SectionRepresentativeService _instance =
      SectionRepresentativeService._internal();

  factory SectionRepresentativeService() => _instance;

  SectionRepresentativeService._internal();

  final ApiClient _apiClient = ApiClient();
  final EnrollmentService _enrollmentService = EnrollmentService();
  List<SectionRepresentative>? _cachedRepresentatives;
  List<CursoDelegado>? _cachedDelegateSections;

  Future<List<CursoDelegado>> fetchDelegateSections({bool force = false}) async {
    if (_cachedDelegateSections != null && !force) {
      return _cachedDelegateSections!;
    }

    final response = await _apiClient.getJson('/api/v1/delegate/sections');
    final raw = response['data'] as List? ?? const [];
    _cachedDelegateSections = raw
        .map((item) => CursoDelegado.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    return _cachedDelegateSections!;
  }

  void clearCache() {
    _cachedRepresentatives = null;
    _cachedDelegateSections = null;
  }

  Future<List<SectionRepresentative>> fetchRepresentatives() async {
    if (_cachedRepresentatives != null) return _cachedRepresentatives!;
    try {
      final String response =
          await rootBundle.loadString('assets/data/section_representative.json');
      final data = json.decode(response);
      final List<dynamic> raw = data['sectionRepresentatives'] ?? [];
      _cachedRepresentatives =
          raw.map((r) => SectionRepresentative.fromJson(r)).toList();
      return _cachedRepresentatives!;
    } catch (e) {
      debugPrint('Error cargando representantes: $e');
      return [];
    }
  }

  Future<String> getRoleInSection(String idSeccion, String studentCode) async {
    final representatives = await fetchRepresentatives();

    for (final rep in representatives) {
      final enrollment = await _enrollmentService.findById(rep.enrollmentId);

      if (enrollment != null &&
          enrollment.idSeccion == idSeccion &&
          enrollment.studentCode == studentCode) {
        return rep.role;
      }
    }

    return 'estudiante';
  }

  Future<String> findHighestRoleByStudentCode(String studentCode) async {
    try {
      final sections = await fetchDelegateSections(force: true);
      if (sections.any((section) => section.rol == 'delegado')) {
        return 'delegado';
      }
      if (sections.any((section) => section.rol == 'subdelegado')) {
        return 'subdelegado';
      }
      return 'estudiante';
    } catch (e) {
      debugPrint('Error consultando rol de delegado en backend: $e');
    }

    final representatives = await fetchRepresentatives();
    String highestRole = 'estudiante';

    for (final rep in representatives) {
      final enrollment = await _enrollmentService.findById(rep.enrollmentId);

      if (enrollment != null && enrollment.studentCode == studentCode) {
        if (rep.role == 'delegado') return 'delegado';
        if (rep.role == 'subdelegado') highestRole = 'subdelegado';
      }
    }

    return highestRole;
  }

  Future<bool> isRepresentativeInAnySection(String studentCode) async {
    try {
      final sections = await fetchDelegateSections(force: true);
      return sections.isNotEmpty;
    } catch (e) {
      debugPrint('Error consultando representantes en backend: $e');
    }

    final representatives = await fetchRepresentatives();

    for (final rep in representatives) {
      final enrollment = await _enrollmentService.findById(rep.enrollmentId);

      if (enrollment != null &&
          enrollment.studentCode == studentCode &&
          (rep.role == 'delegado' || rep.role == 'subdelegado')) {
        return true;
      }
    }

    return false;
  }
}
