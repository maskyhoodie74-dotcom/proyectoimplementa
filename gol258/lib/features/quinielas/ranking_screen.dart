import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'quinielas_provider.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  List<Map<String, dynamic>> _ranking = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRanking();
  }

  Future<void> _loadRanking() async {
    final provider = context.read<QuinielasProvider>();
    final ranking = await provider.obtenerRanking();
    if (mounted) {
      setState(() {
        _ranking = ranking;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ranking de Fans'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _ranking.isEmpty
              ? const Center(child: Text('Aún no hay puntos registrados.'))
              : ListView.builder(
                  itemCount: _ranking.length,
                  itemBuilder: (context, index) {
                    final fan = _ranking[index];
                    final isTop3 = index < 3;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isTop3 ? Colors.amber[700] : Colors.grey[700],
                        child: Text('${index + 1}', style: const TextStyle(color: Colors.white)),
                      ),
                      title: Text(fan['nombre'] ?? 'Desconocido', style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: Text('${fan['puntos']} pts', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    );
                  },
                ),
    );
  }
}
