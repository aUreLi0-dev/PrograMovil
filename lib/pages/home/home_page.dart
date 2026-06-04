import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/components/footer/app_footer.dart';
import 'package:ulima_plus/components/header/app_header.dart';
import 'package:ulima_plus/pages/calculadora/calculadora_page.dart';
import 'package:ulima_plus/pages/horario/horario.dart';
import 'package:ulima_plus/pages/malla/malla_page.dart';
import 'package:ulima_plus/services/auth_service.dart';
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

  @override
  void initState() {
    super.initState();
    control.loadDelegateStatus();
  }

  List<Widget> _buildPages() {
    final isDelegate = AuthService.to.isDelegate;
    return [
      const MallaPage(),
      const CalculadoraPage(),
      const HorarioPage(),
      if (isDelegate) const DelegadoCursosPage(),
      const ProfilePage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: Column(
        children: [
          Obx(
            () => AppHeader(
              showLogout: control.currentTabIndex.value ==
                  (_buildPages().length - 1),
            ),
          ),
          Expanded(
            child: Obx(() {
              final pages = _buildPages();
              final idx = control.currentTabIndex.value.clamp(0, pages.length - 1);
              return pages[idx];
            }),
          ),
        ],
      ),
      bottomNavigationBar: Obx(
        () => AppFooter(
          currentIndex: control.currentTabIndex.value,
          onTap: (index) {
            control.currentTabIndex.value = index;
          },
        ),
      ),
    );
  }
}
