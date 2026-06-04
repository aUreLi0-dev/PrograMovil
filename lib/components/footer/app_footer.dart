// lib/components/app_footer.dart

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AppFooter extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onTap;
  final bool mostrarDelegado;

  const AppFooter({
    super.key,
    required this.currentIndex,
    this.onTap,
    this.mostrarDelegado = false,
  });

  @override
  Widget build(BuildContext context) {
    ColorScheme colors = Theme.of(context).colorScheme;

    return BottomNavigationBar(
      currentIndex: currentIndex,

      onTap: (index) {
        if (onTap != null) {
          onTap!(index);
        }
      },

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

        if (mostrarDelegado)
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
