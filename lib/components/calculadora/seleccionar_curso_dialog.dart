import 'package:flutter/material.dart';
import '../../constants/calculadora_constants.dart';
import '../../models/curso_seccion_model.dart';
import '../../pages/calculadora/calculadora_controller.dart';

class SeleccionarCursoDialog extends StatelessWidget {
  final CalculadoraController controller;
  final BuildContext parentContext;
  final void Function(BuildContext, int, CalculadoraController) onCursoSeleccionado;

  const SeleccionarCursoDialog({
    super.key,
    required this.controller,
    required this.parentContext,
    required this.onCursoSeleccionado,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            CalculadoraConstantes.seleccionarCurso,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(
            controller.cursos.length,
            (index) {
              final curso = controller.cursos[index];
              return _CursoItem(
                curso: curso,
                onTap: () {
                  Navigator.pop(context);
                  onCursoSeleccionado(parentContext, index, controller);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CursoItem extends StatelessWidget {
  final CursoSeccion curso;
  final VoidCallback onTap;

  const _CursoItem({
    required this.curso,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colors.primary.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sección: ${curso.codigoSeccion}', 
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                ),
                Text(
                  curso.nombre,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
