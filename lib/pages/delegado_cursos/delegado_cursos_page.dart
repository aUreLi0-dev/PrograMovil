import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:get/get.dart';
import 'delegado_cursos_controller.dart';

class DelegadoCursosPage extends StatefulWidget {
  const DelegadoCursosPage({Key? key}) : super(key: key);

  @override
  State<DelegadoCursosPage> createState() => _DelegadoCursosPageState();
}

class _DelegadoCursosPageState extends State<DelegadoCursosPage> {
  final DelegadoCursosController _controller = DelegadoCursosController();

  @override
  void initState() {
    super.initState();
    _controller.cargarCursos(() {
      setState(() {});
    });
  }

  @override
Widget build(BuildContext context) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  final textColor = isDarkMode ? Colors.white : Colors.black87;
  final subTitleColor = isDarkMode ? Colors.white70 : Colors.grey.shade600;
  final cardColor = isDarkMode ? const Color(0xFF2D3035) : Colors.white;

  return Scaffold(
    backgroundColor: isDarkMode ? const Color(0xFF1A1C1E) : Colors.grey.shade50,
    body: SafeArea(
      child: _controller.cargando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Encabezado compacto
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delegado',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      Text(
                        'Tus cursos a cargo',
                        style: TextStyle(fontSize: 15, color: subTitleColor),
                      ),
                    ],
                  ),
                ),
                
                // Lista de cursos
                Expanded(
                  child: _controller.cursosDelegado.isEmpty
                      ? Center(child: Text("No tienes cursos a cargo", style: TextStyle(color: subTitleColor)))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _controller.cursosDelegado.length,
                          itemBuilder: (context, index) {
                            final curso = _controller.cursosDelegado[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: isDarkMode ? null : Border.all(color: Colors.grey.shade200),
                                boxShadow: isDarkMode ? [] : [
                                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2)),
                                ],
                              ),
                              child: ListTile(
                                title: Text(curso["curso"], style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                                subtitle: Text('Sección ${curso["seccion"]}', style: TextStyle(color: isDarkMode ? Colors.orangeAccent : Colors.grey.shade700)),
                                trailing: Icon(LucideIcons.chevronRight, size: 18, color: textColor),
                                onTap: () {
                                  Get.toNamed('/delegado-anuncios', arguments: {
                                    'curso': curso["curso"],
                                    'idSeccion': curso["idSeccion"]
                                  });
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    ),
  );
}
}