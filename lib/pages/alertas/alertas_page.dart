import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/components/footer/app_footer.dart';
import 'package:ulima_plus/components/header/app_header.dart';
import 'package:ulima_plus/models/alerta_model.dart';
import 'package:ulima_plus/pages/alertas/alertas_controller.dart';
import 'package:ulima_plus/pages/home/home_controller.dart';
import 'package:ulima_plus/services/auth_service.dart';

class AlertasPage extends StatelessWidget {
  const AlertasPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AlertasController());
    final colors = Theme.of(context).colorScheme;

    controller.generarAlertas();

    return Scaffold(
      backgroundColor: colors.surface,
      body: Column(
        children: [
          const AppHeader(),
          // Sub-header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            color: colors.surface,
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: colors.onSurface),
                  onPressed: () => Get.back(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.notifications_none, color: colors.primary, size: 22),
                const SizedBox(width: 6),
                Text(
                  'Buzón de Alertas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.outline.withValues(alpha: 0.4)),
          // Lista de alertas
          Expanded(
            child: Obx(() {
              if (controller.cargando.value) {
                return Center(
                  child: CircularProgressIndicator(color: colors.primary),
                );
              }

              if (controller.alertas.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 64,
                        color: colors.onSurface.withValues(alpha: 0.25),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No tienes alertas pendientes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: colors.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                itemCount: controller.alertas.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  return _AlertCard(
                    alerta: controller.alertas[index],
                    controller: controller,
                  );
                },
              );
            }),
          ),
        ],
      ),
      bottomNavigationBar: Obx(() {
        final isDelegate = AuthService.to.isDelegate;
        final lastIndex = isDelegate ? 4 : 3;

        return AppFooter(
          currentIndex: HomeController.to.currentTabIndex.value.clamp(
            0,
            lastIndex,
          ),
          isDelegate: isDelegate,
          onTap: (index) {
            HomeController.to.currentTabIndex.value = index;
            Get.back();
          },
        );
      }),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alerta, required this.controller});

  final AlertaModel alerta;
  final AlertasController controller;

  Color _dotColor(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    switch (alerta.tipo) {
      case 'riesgo_academico':
        return const Color(0xFFE53935);
      case 'promedio_general':
        return const Color(0xFF1D6FDB);
      default:
        return primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dotColor = _dotColor(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outline.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: alerta.leido ? Colors.transparent : dotColor,
                  shape: BoxShape.circle,
                  border: alerta.leido
                      ? Border.all(color: colors.outline)
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  alerta.titulo,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: colors.onSurface,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              if (!alerta.leido)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'NUEVO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            alerta.mensaje,
            style: TextStyle(
              fontSize: 13,
              color: colors.onSurface.withValues(alpha: 0.7),
              height: 1.45,
            ),
          ),
          if (!alerta.leido) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => controller.marcarComoLeido(alerta.id),
                child: Text(
                  'Marcar como leído',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
