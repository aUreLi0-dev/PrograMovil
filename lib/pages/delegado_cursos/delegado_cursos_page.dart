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
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: _controller.cargando
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Delegado',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: colors.onSurface,
                          ),
                        ),
                        Text(
                          'Tus cursos a cargo',
                          style: TextStyle(
                            fontSize: 15,
                            color: colors.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _controller.cursosDelegado.isEmpty
                        ? Center(
                            child: Text(
                              "No tienes cursos a cargo",
                              style: TextStyle(
                                color: colors.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _controller.cursosDelegado.length,
                            itemBuilder: (context, index) {
                              final curso = _controller.cursosDelegado[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: colors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: colors.outline.withValues(alpha: 0.5),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: colors.shadow.withValues(alpha: 0.05),
                                      blurRadius: 5,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  title: Text(
                                    curso["curso"],
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: colors.onSurface,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Sección ${curso["seccion"]}',
                                    style: TextStyle(
                                      color: colors.primary,
                                    ),
                                  ),
                                  trailing: Icon(
                                    LucideIcons.chevronRight,
                                    size: 18,
                                    color: colors.onSurface,
                                  ),
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
