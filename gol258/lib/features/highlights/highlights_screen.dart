import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/highlight.dart';
import '../auth/auth_provider.dart';
import 'highlights_provider.dart';
import '../shared/image_upload_service.dart';

class HighlightsScreen extends StatefulWidget {
  final int partidoId;
  const HighlightsScreen({super.key, required this.partidoId});

  @override
  State<HighlightsScreen> createState() => _HighlightsScreenState();
}

class _HighlightsScreenState extends State<HighlightsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        context.read<HighlightsProvider>().fetchHighlightsPartido(widget.partidoId));
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<HighlightsProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        title: Text('Galería del Partido',
            style: GoogleFonts.inter(color: AppColors.gold, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: AppColors.gold),
      ),
      floatingActionButton: (auth.isAdmin || auth.jugadorId != null)
          ? FloatingActionButton.extended(
              onPressed: () => _mostrarDialogoAgregar(context),
              backgroundColor: AppColors.maroon,
              icon: const Icon(Icons.add_photo_alternate, color: AppColors.gold),
              label: Text('Agregar Foto', style: GoogleFonts.inter(color: AppColors.gold, fontWeight: FontWeight.bold)),
            )
          : null,
      body: prov.loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : prov.highlights.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.photo_library_outlined, color: AppColors.textSecondary, size: 60),
                      const SizedBox(height: 16),
                      Text('Sin highlights aún', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 16)),
                      if (auth.isAdmin)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text('Agrega fotos con el botón +', style: GoogleFonts.inter(color: AppColors.textTertiary, fontSize: 13)),
                        ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: prov.highlights.length,
                  itemBuilder: (context, index) {
                    final h = prov.highlights[index];
                    return GestureDetector(
                      onTap: () => _verImagen(context, h),
                      child: Hero(
                        tag: 'highlight_${h.id}',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            h.urlMedia,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Container(
                              color: AppColors.bgCard,
                              child: const Icon(Icons.broken_image, color: AppColors.textSecondary),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  void _verImagen(BuildContext context, Highlight h) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(h.descripcion ?? 'Highlight',
              style: GoogleFonts.inter(color: Colors.white)),
        ),
        body: Center(
          child: Hero(
            tag: 'highlight_${h.id}',
            child: InteractiveViewer(
              child: Image.network(h.urlMedia, errorBuilder: (c, e, s) =>
                const Icon(Icons.broken_image, color: Colors.white, size: 80)),
            ),
          ),
        ),
      ),
    ));
  }

  void _mostrarDialogoAgregar(BuildContext context) {
    final urlCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: Text('Agregar Highlight', style: GoogleFonts.inter(color: AppColors.gold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: urlCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'URL de la imagen',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                border: const OutlineInputBorder(),
                enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.divider)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.upload_file, color: AppColors.gold),
                  onPressed: () async {
                    final url = await ImageUploadService.pickAndUploadImage(folder: 'highlights');
                    if (url != null) {
                      urlCtrl.text = url;
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Descripción (opcional)',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                border: const OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.divider)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.maroon),
            onPressed: () async {
              final url = urlCtrl.text.trim();
              if (url.isEmpty) return;
              final h = Highlight(
                partidoId: widget.partidoId,
                urlMedia: url,
                descripcion: descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : null,
              );
              await context.read<HighlightsProvider>().agregarHighlight(h);
              if (dialogCtx.mounted) Navigator.pop(dialogCtx);
            },
            child: Text('Agregar', style: GoogleFonts.inter(color: AppColors.gold)),
          ),
        ],
      ),
    );
  }
}
