import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'delegado_anuncios_controller.dart';

class DelegadoAnunciosPage extends StatefulWidget {
  const DelegadoAnunciosPage({super.key});

  @override
  State<DelegadoAnunciosPage> createState() => _DelegadoAnunciosPageState();
}

class _DelegadoAnunciosPageState extends State<DelegadoAnunciosPage> {
  late final DelegadoAnunciosController control;

  @override
  void initState() {
    super.initState();
    control = Get.put(DelegadoAnunciosController());
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    control.cargarCurso(args);
  }

  @override
  void dispose() {
    Get.delete<DelegadoAnunciosController>();
    super.dispose();
  }

  Widget _topBar(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: colors.primary,
      padding: EdgeInsets.fromLTRB(
        18,
        MediaQuery.paddingOf(context).top + 12,
        18,
        18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => Get.back(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.chevronLeft, color: colors.onPrimary, size: 18),
                const SizedBox(width: 4),
                Text(
                  'Volver',
                  style: TextStyle(
                    color: colors.onPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Gestion de Delegado: ${control.codigoSeccion}',
            style: TextStyle(
              color: colors.onPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            control.nombreCurso,
            style: TextStyle(
              color: colors.onPrimary.withOpacity(0.8),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _courseSummary(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(LucideIcons.shield, color: colors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  control.rol,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Seccion ${control.codigoSeccion} - '
                  '${control.alumnosMatriculados} alumnos',
                  style: TextStyle(
                    color: colors.onSurface.withOpacity(0.6),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(BuildContext context, String text) {
    final colors = Theme.of(context).colorScheme;
    return Text(
      text,
      style: TextStyle(
        color: colors.onSurface.withOpacity(0.6),
        fontSize: 12,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  InputDecoration _inputDecoration(BuildContext context, String hint) {
    final colors = Theme.of(context).colorScheme;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: colors.onSurface.withOpacity(0.4)),
      filled: true,
      fillColor: colors.tertiaryContainer.withOpacity(0.3),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colors.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colors.primary, width: 1.5),
      ),
    );
  }

  Widget _announcementForm(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.outline),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.send, color: colors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Nuevo Anuncio',
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _label(context, 'TITULO'),
          const SizedBox(height: 8),
          TextField(
            controller: control.titulo,
            style: TextStyle(color: colors.onSurface),
            decoration: _inputDecoration(context, 'Fecha de exposiciones'),
          ),
          const SizedBox(height: 16),
          _label(context, 'MENSAJE'),
          const SizedBox(height: 8),
          TextField(
            controller: control.mensaje,
            maxLines: 6,
            style: TextStyle(color: colors.onSurface),
            decoration: _inputDecoration(
              context,
              'Escribe aqui el mensaje para la seccion',
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: control.publicarAnuncio,
              icon: const Icon(LucideIcons.send, size: 18),
              label: const Text(
                'Publicar Anuncio',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _columnaBarra({
    required BuildContext context,
    required String rango,
    required int cantidad,
    required Color color,
    required int maxCantidad,
  }) {
    final colors = Theme.of(context).colorScheme;
    
    // Altura máxima reservada para la barra física en píxeles
    double alturaMaximaGrafico = 70.0;
    
    // Regla de tres simple para calcular la altura de cada barra de forma proporcional
    double alturaCalculada = maxCantidad > 0 
        ? (cantidad / maxCantidad) * alturaMaximaGrafico 
        : 0;

    // Altura mínima para que la barra se note aunque tenga valor bajo
    double alturaMinima = cantidad > 0 ? 8.0 : 0.0;
    double alturaFinal = alturaCalculada < alturaMinima ? alturaMinima : alturaCalculada;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Cantidad de alumnos encima de la barra
        Text(
          '$cantidad',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        // La barra física de color
        Container(
          width: 28,
          height: alturaFinal,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ),
        const SizedBox(height: 6),
        // Etiqueta del rango de notas debajo
        Text(
          rango,
          style: TextStyle(
            fontSize: 10,
            color: colors.onSurface.withOpacity(0.5),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _estadisticasSalon(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Obx(() {
      final stats = control.estadisticas.value;
      if (stats == null) {
        return const SizedBox.shrink();
      }

      // Hallar la cantidad máxima del rango para escalar las barras de forma proporcional
      int maxCantidad = [
        stats.rango0_10,
        stats.rango11_13,
        stats.rango14_16,
        stats.rango17_20
      ].reduce((curr, next) => curr > next ? curr : next);

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.outline),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título de la sección
            Row(
              children: [
                Icon(LucideIcons.barChart2, color: colors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Estadísticas del Salón',
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            // Fila de Promedio General y Porcentaje de Aprobados
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PROMEDIO GENERAL',
                        style: TextStyle(
                          color: colors.onSurface.withOpacity(0.5),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${stats.promedioGeneral.toStringAsFixed(1)}',
                        style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 36,
                  color: colors.outline,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'APROBADOS',
                          style: TextStyle(
                            color: colors.onSurface.withOpacity(0.5),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${stats.porcentajeAprobados}%',
                        style: const TextStyle(
                          color: Color(0xFF2ECC71), // Verde agradable para aprobados
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // El Gráfico de Barras Nativos
          Container(
            height: 120,
            width: double.infinity,
            alignment: Alignment.bottomCenter,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _columnaBarra(
                  context: context,
                  rango: '0-10',
                  cantidad: stats.rango0_10,
                  color: const Color(0xFFE74C3C), // Rojo
                  maxCantidad: maxCantidad,
                ),
                _columnaBarra(
                  context: context,
                  rango: '11-13',
                  cantidad: stats.rango11_13,
                  color: const Color(0xFFE67E22), // Naranja
                  maxCantidad: maxCantidad,
                ),
                _columnaBarra(
                  context: context,
                  rango: '14-16',
                  cantidad: stats.rango14_16,
                  color: const Color(0xFF3498DB), // Azul
                  maxCantidad: maxCantidad,
                ),
                _columnaBarra(
                  context: context,
                  rango: '17-20',
                  cantidad: stats.rango17_20,
                  color: const Color(0xFF2ECC71), // Verde
                  maxCantidad: maxCantidad,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Subtítulo del gráfico
          Center(
            child: Text(
              'Distribución de notas parciales',
              style: TextStyle(
                color: colors.onSurface.withOpacity(0.4),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  });
}

  Widget _buildBody(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        _courseSummary(context),
        const SizedBox(height: 16),
        _announcementForm(context),
        const SizedBox(height: 16),
        _estadisticasSalon(context),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      body: Column(
        children: [
          _topBar(context),
          Expanded(child: _buildBody(context)),
        ],
      ),
    );
  }
}
