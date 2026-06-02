import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/services/auth_service.dart';
import '../horario/horario_semanal.dart';
import '../malla/malla_controller.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  String _roleLabel(String role) {
    switch (role) {
      case 'delegado':
        return 'DELEGADO';
      case 'subdelegado':
        return 'SUBDELEGADO';
      default:
        return 'ALUMNO';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final auth = AuthService.to;

    return Obx(() {
      final user = auth.currentUser;
      if (user == null) {
        return const Center(child: Text('No hay sesión activa.'));
      }

      final nombre = '${user.lastName} ${user.firstName}'.toUpperCase();
      final carrera = auth.getCareerName(user.careerId);
      final especialidad = user.especialidades
          .map((id) => auth.getEspecialidadName(id))
          .where((n) => n.isNotEmpty)
          .join(', ');

      return SingleChildScrollView(
      child: Column(
        children: [
          // Cabecera con datos del alumno.
          Container(
            width: double.infinity,
            color: MaterialTheme.primaryColor.withValues(alpha: 0.18),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(
              children: [
                Text(
                  _roleLabel(user.role),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: colors.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: colors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_outline,
                    size: 64,
                    color: colors.onSurface.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  nombre,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.code,
                  style: TextStyle(
                    fontSize: 16,
                    color: colors.onSurface.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  carrera,
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _InfoCard(
            icon: Icons.business_center,
            iconBg: MaterialTheme.blackColor,
            title: 'Especialidad',
            subtitle: especialidad.isEmpty
                ? 'Sin especialidad asignada'
                : especialidad.toUpperCase(),
            subtitleColor: MaterialTheme.primaryColor,
            onTap: () => _mostrarSelectorEspecialidad(context, auth, user),
          ),
          const SizedBox(height: 12),
          _InfoCard(
            icon: Icons.calendar_today,
            iconBg: colors.onSurface.withValues(alpha: 0.45),
            title: 'Horario',
            onTap: () => Get.to(() => const HorarioSemanalPage()),
          ),
        ],
        ),
      );
    });
  }

  /// Abre un selector (checkboxes) con las especialidades de la carrera del
  /// alumno. Al guardar, actualiza las especialidades y refresca la malla
  /// para que se filtren los electivos.
  void _mostrarSelectorEspecialidad(
    BuildContext context,
    AuthService auth,
    dynamic user,
  ) {
    final colors = Theme.of(context).colorScheme;
    final disponibles = auth.especialidades
        .where((e) => e['carrera_id'] == user.careerId && e['is_active'] == true)
        .toList()
      ..sort((a, b) {
        final oa = (a['display_order'] as num?)?.toInt() ?? 999;
        final ob = (b['display_order'] as num?)?.toInt() ?? 999;
        return oa.compareTo(ob);
      });

    final seleccion = <int>{...user.especialidades};

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: 20 + MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selecciona tu especialidad',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Puedes elegir una o más. La malla mostrará sus electivos.',
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...disponibles.map((e) {
                    final id = e['id'] as int;
                    final checked = seleccion.contains(id);
                    return CheckboxListTile(
                      value: checked,
                      activeColor: MaterialTheme.primaryColor,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(
                        e['name'] as String? ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colors.onSurface,
                        ),
                      ),
                      onChanged: (v) {
                        setSheetState(() {
                          if (v == true) {
                            seleccion.add(id);
                          } else {
                            seleccion.remove(id);
                          }
                        });
                      },
                    );
                  }),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MaterialTheme.primaryColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        await auth.updateEspecialidades(seleccion.toList());
                        // Refresca la malla si ya está construida.
                        if (Get.isRegistered<MallaController>()) {
                          Get.find<MallaController>().reloadForUser();
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: const Text('Guardar'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.subtitleColor,
  });

  final IconData icon;
  final Color iconBg;
  final String title;
  final VoidCallback onTap;
  final String? subtitle;
  final Color? subtitleColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: subtitleColor ??
                                colors.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: colors.onSurface.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
