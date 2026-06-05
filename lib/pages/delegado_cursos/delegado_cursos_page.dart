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

  @override
  void initState() {
    super.initState();
    control.cargarCursos();
  }

  Widget _header(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.users, color: colors.primary, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delegado de Aula',
                  style: TextStyle(
                    color: colors.primary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Gestiona tus cursos asignados',
                  style: TextStyle(
                    color: colors.onSurface.withOpacity(0.6),
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

  Widget _sectionChip(BuildContext context, String codigoSeccion) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'Seccion $codigoSeccion',
        style: TextStyle(
          color: colors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _courseCard(BuildContext context, CursoDelegado curso) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => control.abrirGestionCurso(curso),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.outline),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
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
                  _sectionChip(context, curso.codigoSeccion),
                  const SizedBox(height: 10),
                  Text(
                    curso.nombreCurso,
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        LucideIcons.users,
                        size: 16,
                        color: colors.onSurface.withOpacity(0.6),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${curso.alumnosMatriculados} alumnos matriculados',
                        style: TextStyle(
                          color: colors.onSurface.withOpacity(0.6),
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
            Icon(LucideIcons.bookOpen, color: colors.onSurface.withOpacity(0.4)),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Text(
        'No tienes cursos asignados como delegado.',
        textAlign: TextAlign.center,
        style: TextStyle(color: colors.onSurface.withOpacity(0.6), fontSize: 15),
      ),
    );
  }

  Widget _courseList(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Obx(() {
      if (control.cargando.value) {
        return Center(
          child: CircularProgressIndicator(color: colors.primary),
        );
      }

      if (control.cursosDelegado.isEmpty) {
        return _emptyState(context);
      }

      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
        itemCount: control.cursosDelegado.length,
        itemBuilder: (context, index) {
          return _courseCard(context, control.cursosDelegado[index]);
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(context),
          Expanded(child: _courseList(context)),
        ],
      ),
    );
  }
}
