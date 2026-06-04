import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/components/footer/app_footer.dart';
import 'package:ulima_plus/components/header/app_header.dart';
import 'package:ulima_plus/pages/calculadora/calculadora_page.dart';
import 'package:ulima_plus/pages/horario/horario.dart';
import 'package:ulima_plus/pages/malla/malla_page.dart';
import '../perfil/perfil.dart';
import 'package:ulima_plus/pages/delegado_cursos/delegado_cursos_page.dart';

import 'home_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final HomeController control = Get.put(HomeController());

  List<Widget> _pages(bool mostrarDelegado) {
    return [
      const MallaPage(),
      const CalculadoraPage(),
      const HorarioPage(),
      if (mostrarDelegado) const DelegadoCursosPage(),
      const ProfilePage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Obx(() {
      final mostrarDelegado = control.mostrarDelegado.value;
      final pages = _pages(mostrarDelegado);
      final currentIndex = control.currentTabIndex.value.clamp(
        0,
        pages.length - 1,
      ).toInt();

      return Scaffold(
        backgroundColor: colors.surface,
        body: Column(
          children: [
            AppHeader(showLogout: currentIndex == pages.length - 1),
            Expanded(child: pages[currentIndex]),
          ],
        ),
        bottomNavigationBar: AppFooter(
          currentIndex: currentIndex,
          mostrarDelegado: mostrarDelegado,
          onTap: (index) {
            control.currentTabIndex.value = index;
          },
        ),
      );
    });
  }
}
