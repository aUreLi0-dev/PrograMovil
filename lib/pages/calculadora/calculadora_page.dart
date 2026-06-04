import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/calculadora_constants.dart';
import '../../components/calculadora/curso_card.dart';
import '../../components/calculadora/add_score.dart';
import '../../components/calculadora/seleccionar_curso_dialog.dart';
import 'calculadora_controller.dart';

class CalculadoraPage extends StatelessWidget {
  const CalculadoraPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CalculadoraController>();
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      // En tu darkScheme pusiste surface: Color(0xFF1F1F1F)
      backgroundColor: colors.surface, 
      body: Column(
        children: [ 
          // Header de Calculadora de Notas
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  CalculadoraConstantes.titulo,
                  style: TextStyle(
                    fontSize: 24, 
                    fontWeight: FontWeight.w900,
                    color: colors.onSurface,
                  ),
                ),
                Obx(() {
                  final cursosConNotas = controller.cursos
                      .where((curso) => curso.notas.isNotEmpty)
                      .length;
                  return Text(
                    '${CalculadoraConstantes.cursosConNotas} $cursosConNotas',
                    style: TextStyle(
                      color: colors.onSurface.withOpacity(0.7), 
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  );
                }),
              ],
            ),
          ),

          // Lista de cursos (solo los que tienen notas registradas)
          Expanded(
            child: Obx(() {
              final cursosConNotas = controller.cursos
                  .where((curso) => curso.notas.isNotEmpty)
                  .toList();

              if (cursosConNotas.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.assignment_ind,
                        size: 64,
                        color: colors.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        CalculadoraConstantes.sinNotas,
                        style: TextStyle(
                          fontSize: 16,
                          color: colors.onSurface.withOpacity(0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        CalculadoraConstantes.empezar,
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.onSurface.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                itemCount: cursosConNotas.length,
                itemBuilder: (context, index) {
                  final curso = cursosConNotas[index];
                  final cursoIndex = controller.cursos.indexOf(curso);
                  final notas = List<Map<String, dynamic>>.from(curso.notas);
                   
                   return CursoCard(
                     curso: curso,
                     cursoIndex: cursoIndex,
                     promedio: controller.calcularPromedio(cursoIndex),
                     sumaPesos: controller.sumaPesos(notas),
                    onDeleteNota: controller.eliminarNota,
                  );
                },
              );
            }),
          ),

          // Botón Agregar Nota - Versión mejorada
          Padding(
            padding: const EdgeInsets.all(20),
            child: Obx(() {
              final tieneNotas = controller.cursos.isNotEmpty;
              return ElevatedButton.icon(
                onPressed: tieneNotas
                    ? () {
                        // Mostrar diálogo para seleccionar curso si hay múltiples
                        if (controller.cursos.length == 1) {
                          _mostrarModalAgregarNota(context, 0, controller);
                        } else {
                          _mostrarDialogoSeleccionarCurso(
                            context,
                            controller,
                          );
                        }
                      }
                    : null,
                icon: const Icon(Icons.add),
                label: const Text(CalculadoraConstantes.registrarNota),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primaryContainer,
                  foregroundColor: colors.onPrimary,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  disabledBackgroundColor:
                      colors.primaryContainer.withOpacity(0.5),
                ),
              );
            }),
          ),
        ],
      ),

    );
  }

  /// Muestra el modal para agregar nota para un curso específico
  void _mostrarModalAgregarNota(
    BuildContext context,
    int cursoIndex,
    CalculadoraController controller,
  ) {
    final colors = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (_) => AddNota(
        cursoIndex: cursoIndex,
        cursoData: controller.cursos[cursoIndex],
      ),
    );
  }

  /// Muestra un diálogo para seleccionar el curso antes de agregar nota
  void _mostrarDialogoSeleccionarCurso(
    BuildContext context,
    CalculadoraController controller,
  ) {
    final colors = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (_) => SeleccionarCursoDialog(
        controller: controller,
        parentContext: context,
        onCursoSeleccionado: _mostrarModalAgregarNota,
      ),
    );
  }}