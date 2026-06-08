import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../auth/auth_provider.dart';
import '../partidos/partidos_provider.dart';
import '../../models/partido.dart';
import '../../models/quiniela.dart';
import 'quinielas_provider.dart';
import 'ranking_screen.dart';

class QuinielasScreen extends StatefulWidget {
  const QuinielasScreen({super.key});

  @override
  State<QuinielasScreen> createState() => _QuinielasScreenState();
}

class _QuinielasScreenState extends State<QuinielasScreen> {
  final Map<int, TextEditingController> _localControllers = {};
  final Map<int, TextEditingController> _visitanteControllers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadQuinielas();
    });
  }

  Future<void> _loadQuinielas() async {
    final auth = context.read<AuthProvider>();
    if (auth.usuarioId != null) {
      final uId = int.tryParse(auth.usuarioId!);
      if (uId != null) {
        await context.read<QuinielasProvider>().fetchQuinielas(uId);
        _populateControllers();
      }
    }
  }

  void _populateControllers() {
    final quinielas = context.read<QuinielasProvider>().quinielas;
    for (var q in quinielas) {
      if (!_localControllers.containsKey(q.partidoId)) {
        _localControllers[q.partidoId] = TextEditingController(text: q.golesLocalPred.toString());
        _visitanteControllers[q.partidoId] = TextEditingController(text: q.golesVisitPred.toString());
      }
    }
    setState(() {});
  }

  @override
  void dispose() {
    for (var c in _localControllers.values) {
      c.dispose();
    }
    for (var c in _visitanteControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _guardarPrediccion(Partido partido) async {
    final auth = context.read<AuthProvider>();
    if (auth.usuarioId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Debes iniciar sesión para participar')));
      return;
    }
    final uId = int.tryParse(auth.usuarioId!);
    if (uId == null) return;

    final locText = _localControllers[partido.id]?.text ?? '';
    final visText = _visitanteControllers[partido.id]?.text ?? '';

    if (locText.isEmpty || visText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresa ambos goles para pronosticar')));
      return;
    }

    final locGol = int.tryParse(locText) ?? 0;
    final visGol = int.tryParse(visText) ?? 0;

    final quiniela = Quiniela(
      usuarioId: uId,
      partidoId: int.tryParse(partido.id.toString()) ?? 0,
      golesLocalPred: locGol,
      golesVisitPred: visGol,
    );

    final success = await context.read<QuinielasProvider>().guardarQuiniela(quiniela);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Pronóstico guardado!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final partidosProv = context.watch<PartidosProvider>();
    final partidos = partidosProv.proximosPartidos;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quinielas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events),
            tooltip: 'Ranking de Fans',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RankingScreen()),
            ),
          ),
        ],
      ),
      body: partidos.isEmpty
          ? const Center(child: Text('No hay partidos próximos para pronosticar'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: partidos.length,
              itemBuilder: (context, index) {
                final partido = partidos[index];
                final pId = int.tryParse(partido.id.toString()) ?? 0;
                
                if (!_localControllers.containsKey(pId)) {
                  _localControllers[pId] = TextEditingController();
                  _visitanteControllers[pId] = TextEditingController();
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(DateFormat('dd MMM yyyy - HH:mm').format(partido.fecha), style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  if (partido.equipoLocalEscudo != null)
                                    Image.network(partido.equipoLocalEscudo!, height: 40, width: 40, errorBuilder: (c, e, s) => const Icon(Icons.shield, size: 40)),
                                  const SizedBox(height: 8),
                                  Text(partido.equipoLocalNombre ?? 'Local', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: 60,
                                    child: TextField(
                                      controller: _localControllers[pId],
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      decoration: const InputDecoration(border: OutlineInputBorder()),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Text('VS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            Expanded(
                              child: Column(
                                children: [
                                  if (partido.equipoVisitanteEscudo != null)
                                    Image.network(partido.equipoVisitanteEscudo!, height: 40, width: 40, errorBuilder: (c, e, s) => const Icon(Icons.shield, size: 40)),
                                  const SizedBox(height: 8),
                                  Text(partido.equipoVisitanteNombre ?? 'Visitante', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: 60,
                                    child: TextField(
                                      controller: _visitanteControllers[pId],
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      decoration: const InputDecoration(border: OutlineInputBorder()),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _guardarPrediccion(partido),
                          child: const Text('Guardar Pronóstico'),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
