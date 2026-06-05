// lib/components/footer/app_footer.dart

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AppFooter extends StatelessWidget {
  final int currentIndex;
  final bool isDelegate;
  final ValueChanged<int>? onTap;

  const AppFooter({
    super.key,
    required this.currentIndex,
    required this.isDelegate,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      selectedItemColor: colors.primary,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      items: [
        const BottomNavigationBarItem(
          icon: Icon(LucideIcons.network),
          label: 'Malla',
        ),
        const BottomNavigationBarItem(
          icon: Icon(LucideIcons.calculator),
          label: 'Notas',
        ),
        const BottomNavigationBarItem(
          icon: Icon(LucideIcons.calendar),
          label: 'Horario',
        ),
        // Modulo extra para alumnos registrados en section_representative.
        if (isDelegate)
          const BottomNavigationBarItem(
            icon: Icon(LucideIcons.shield),
            label: 'Delegado',
          ),
        const BottomNavigationBarItem(
          icon: Icon(LucideIcons.user),
          label: 'Perfil',
        ),
      ],
    );
  }
}
