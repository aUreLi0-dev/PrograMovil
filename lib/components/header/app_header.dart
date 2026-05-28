import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/pages/alertas/alertas_page.dart';
import 'package:ulima_plus/services/alertas_service.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // Garantiza que el servicio exista para que el badge sea reactivo en
    // cualquier pantalla, sin depender del orden de registro en main().
    if (!Get.isRegistered<AlertasService>()) {
      Get.put(AlertasService(), permanent: true);
      AlertasService.to.generarAlertas();
    }

    return Container(
      padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
      decoration: BoxDecoration(
        color: MaterialTheme.headerColor(Theme.brightnessOf(context)),
        border: Border(
          bottom: BorderSide(
            color: colors.primaryContainer,
            width: 2.0,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ULIMA++',
                style: TextStyle(
                  color: colors.onPrimary,
                  fontSize: 20,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.bold,
                ),
              ),
              InkWell(
                onTap: () => Get.to(() => const AlertasPage()),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      Icons.notifications_none,
                      color: colors.onPrimary,
                      size: 30,
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Obx(() {
                        final hayNoLeidas =
                            AlertasService.to.alertas.isNotEmpty &&
                            AlertasService.to.sinLeer > 0;
                        if (!hayNoLeidas) return const SizedBox.shrink();
                        return Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Color.fromARGB(255, 29, 111, 219),
                            shape: BoxShape.circle,
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
