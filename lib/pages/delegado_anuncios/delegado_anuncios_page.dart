import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'delegado_anuncios_controller.dart';

class DelegadoAnunciosPage extends StatefulWidget {
  const DelegadoAnunciosPage({Key? key}) : super(key: key);

  @override
  State<DelegadoAnunciosPage> createState() => _DelegadoAnunciosPageState();
}

class _DelegadoAnunciosPageState extends State<DelegadoAnunciosPage> {
  final DelegadoAnunciosController _controller = DelegadoAnunciosController();
  
  String nombreCurso = "";
  String idSeccion = "";

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    nombreCurso = args['curso'] ?? 'Curso no especificado';
    idSeccion = args['idSeccion'] ?? 'IS-856';

    _controller.cargarAnuncios(idSeccion, () {
      setState(() {});
    });
  }

  void _mostrarDialogoAgregar() {
    final TextEditingController tituloCtrl = TextEditingController();
    final TextEditingController mensajeCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Nuevo Anuncio', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tituloCtrl,
                decoration: InputDecoration(
                  labelText: 'Título',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: mensajeCtrl,
                decoration: InputDecoration(
                  labelText: 'Mensaje',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                if (tituloCtrl.text.isNotEmpty && mensajeCtrl.text.isNotEmpty) {
                  _controller.agregarAnuncioLocal(
                    tituloCtrl.text,
                    mensajeCtrl.text,
                    idSeccion,
                    () { setState(() {}); },
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Publicar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(nombreCurso, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        centerTitle: true,
        elevation: 0,
      ),
      body: _controller.cargando
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _controller.anuncios.length,
              itemBuilder: (context, index) {
                final anuncio = _controller.anuncios[index];
                
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                anuncio.titulo,
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                _controller.eliminarAnuncioLocal(index, () { setState(() {}); });
                              },
                              child: const Icon(LucideIcons.trash2, color: Colors.redAccent, size: 20),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(anuncio.mensaje, style: const TextStyle(fontSize: 14, height: 1.4)),
                        const SizedBox(height: 16),
                        Divider(height: 1, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(LucideIcons.user, size: 14, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(anuncio.autorCode, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                              ],
                            ),
                            Text(anuncio.fecha, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarDialogoAgregar,
        icon: const Icon(LucideIcons.plus),
        label: const Text('Nuevo'),
      ),
    );
  }
}