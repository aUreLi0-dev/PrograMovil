import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/services/auth_service.dart';
import '../home/home_controller.dart';

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
            onTap: () => Get.toNamed('/setup-carrera'),
          ),
          const SizedBox(height: 12),
          _InfoCard(
            icon: Icons.calendar_today,
            iconBg: colors.onSurface.withValues(alpha: 0.45),
            title: 'Horario',
            onTap: () => HomeController.to.currentTabIndex.value = 2,
          ),
        ],
      ),
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
