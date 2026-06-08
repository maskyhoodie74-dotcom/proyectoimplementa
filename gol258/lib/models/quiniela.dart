class Quiniela {
  final int? id;
  final int usuarioId;
  final int partidoId;
  final int golesLocalPred;
  final int golesVisitPred;
  final int puntosObtenidos;
  final DateTime? createdAt;

  Quiniela({
    this.id,
    required this.usuarioId,
    required this.partidoId,
    required this.golesLocalPred,
    required this.golesVisitPred,
    this.puntosObtenidos = 0,
    this.createdAt,
  });

  factory Quiniela.fromJson(Map<String, dynamic> json) {
    return Quiniela(
      id: json['id'],
      usuarioId: json['usuario_id'],
      partidoId: json['partido_id'],
      golesLocalPred: json['goles_local_pred'],
      golesVisitPred: json['goles_visit_pred'],
      puntosObtenidos: json['puntos_obtenidos'] ?? 0,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'usuario_id': usuarioId,
      'partido_id': partidoId,
      'goles_local_pred': golesLocalPred,
      'goles_visit_pred': golesVisitPred,
      'puntos_obtenidos': puntosObtenidos,
    };
  }
}
