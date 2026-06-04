import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ulima_plus/models/curso_delegado_model.dart';

import 'delegado_cursos_controller.dart';

class DelegadoCursosPage extends StatefulWidget {
  const DelegadoCursosPage({super.key});

  @override
  State<DelegadoCursosPage> createState() => _DelegadoCursosPageState();
}

class _DelegadoCursosPageState extends State<DelegadoCursosPage> {
  final DelegadoCursosController control = Get.put(
    DelegadoCursosController(),
  );

  static const Color _orange = Color(0xFFFF5A1F);
  static const Color _background = Color(0xFFF4F5F7);
  static const Color _text = Color(0xFF1F2933);
  static const Color _mutedText = Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    control.cargarCursos();
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.users, color: _orange, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Delegado de Aula',
                  style: TextStyle(
                    color: _orange,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Gestiona tus cursos asignados',
                  style: TextStyle(
                    color: _mutedText,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionChip(String codigoSeccion) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE5D4),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'Seccion $codigoSeccion',
        style: const TextStyle(
          color: _orange,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _courseCard(CursoDelegado curso) {
    return InkWell(
      onTap: () => control.abrirGestionCurso(curso),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionChip(curso.codigoSeccion),
                  const SizedBox(height: 10),
                  Text(
                    curso.nombreCurso,
                    style: const TextStyle(
                      color: _text,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.users,
                        size: 16,
                        color: _mutedText,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${curso.alumnosMatriculados} alumnos matriculados',
                        style: const TextStyle(
                          color: _mutedText,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(LucideIcons.bookOpen, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return const Center(
      child: Text(
        'No tienes cursos asignados como delegado.',
        textAlign: TextAlign.center,
        style: TextStyle(color: _mutedText, fontSize: 15),
      ),
    );
  }

  Widget _courseList() {
    return Obx(() {
      if (control.cargando.value) {
        return const Center(
          child: CircularProgressIndicator(color: _orange),
        );
      }

      if (control.cursosDelegado.isEmpty) {
        return _emptyState();
      }

      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
        itemCount: control.cursosDelegado.length,
        itemBuilder: (context, index) {
          return _courseCard(control.cursosDelegado[index]);
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          Expanded(child: _courseList()),
        ],
      ),
    );
  }
}
