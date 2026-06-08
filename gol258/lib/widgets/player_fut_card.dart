import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/jugador.dart';

class PlayerFutCard extends StatefulWidget {
  final Jugador jugador;

  const PlayerFutCard({super.key, required this.jugador});

  @override
  State<PlayerFutCard> createState() => _PlayerFutCardState();
}

class _PlayerFutCardState extends State<PlayerFutCard> {
  final GlobalKey _cardKey = GlobalKey();

  Future<void> _compartirCarta() async {
    try {
      RenderRepaintBoundary boundary = _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/carta_${widget.jugador.nombre}.png';
      final file = File(imagePath);
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles([XFile(imagePath)], text: '¡Mira la carta de ${widget.jugador.nombre} en GOL 258!');
    } catch (e) {
      debugPrint('Error al compartir la carta: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RepaintBoundary(
          key: _cardKey,
          child: Container(
            width: 250,
            height: 350,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFD4AF37), Color(0xFFFFFACD), Color(0xFFD4AF37)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ],
            ),
            child: Stack(
              children: [
                // Número y Posición
                Positioned(
                  top: 20,
                  left: 20,
                  child: Column(
                    children: [
                      Text(
                        (widget.jugador.goles * 3 + widget.jugador.partidos).toString(), // Overall falso
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      Text(
                        (widget.jugador.posicion != null && widget.jugador.posicion!.length >= 3)
                            ? widget.jugador.posicion!.substring(0, 3).toUpperCase()
                            : (widget.jugador.posicion?.toUpperCase() ?? 'JUG'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                // Foto del Jugador
                Positioned(
                  top: 40,
                  right: 20,
                  left: 60,
                  child: Center(
                    child: widget.jugador.fotoUrl != null && widget.jugador.fotoUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: Image.network(widget.jugador.fotoUrl!, height: 120, width: 120, fit: BoxFit.cover),
                          )
                        : const Icon(Icons.person, size: 120, color: Colors.black54),
                  ),
                ),
                // Nombre
                Positioned(
                  top: 170,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      widget.jugador.nombre.toUpperCase(),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const Positioned(
                  top: 195,
                  left: 20,
                  right: 20,
                  child: Divider(color: Colors.black26, thickness: 1),
                ),
                // Stats
                Positioned(
                  bottom: 30,
                  left: 20,
                  right: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStat('GOL', widget.jugador.goles.toString()),
                      _buildStat('ASI', widget.jugador.asistencias.toString()),
                      _buildStat('PAR', widget.jugador.partidos.toString()),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _compartirCarta,
          icon: const Icon(Icons.share),
          label: const Text('Compartir Carta'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[700]),
        )
      ],
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
      ],
    );
  }
}
