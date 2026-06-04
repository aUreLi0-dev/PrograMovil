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

  static const Color _orange = Color(0xFFFF5A1F);
  static const Color _background = Color(0xFFF4F5F7);
  static const Color _text = Color(0xFF1F2933);
  static const Color _mutedText = Color(0xFF6B7280);

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
    return Container(
      width: double.infinity,
      color: _orange,
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
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.chevronLeft, color: Colors.white, size: 18),
                SizedBox(width: 4),
                Text(
                  'Volver',
                  style: TextStyle(
                    color: Colors.white,
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
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            control.nombreCurso,
            style: const TextStyle(
              color: Color(0xFFFFE7DA),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _courseSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE5D4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(LucideIcons.shield, color: _orange),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  control.rol,
                  style: const TextStyle(
                    color: _text,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Seccion ${control.codigoSeccion} - '
                  '${control.alumnosMatriculados} alumnos',
                  style: const TextStyle(color: _mutedText, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: _mutedText,
        fontSize: 12,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _orange, width: 1.5),
      ),
    );
  }

  Widget _announcementForm() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.send, color: _orange, size: 20),
              SizedBox(width: 8),
              Text(
                'Nuevo Anuncio',
                style: TextStyle(
                  color: _text,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _label('TITULO'),
          const SizedBox(height: 8),
          TextField(
            controller: control.titulo,
            decoration: _inputDecoration('Fecha de exposiciones'),
          ),
          const SizedBox(height: 16),
          _label('MENSAJE'),
          const SizedBox(height: 8),
          TextField(
            controller: control.mensaje,
            maxLines: 6,
            decoration: _inputDecoration(
              'Escribe aqui el mensaje para la seccion',
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: control.publicarAnuncioPendiente,
              icon: const Icon(LucideIcons.send, size: 18),
              label: const Text(
                'Publicar Anuncio',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _orange,
                foregroundColor: Colors.white,
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

  Widget _buildBody() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        _courseSummary(),
        const SizedBox(height: 16),
        _announcementForm(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: Column(
        children: [
          _topBar(context),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }
}
