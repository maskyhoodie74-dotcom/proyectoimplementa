class Partido {
  final String id;
  final String equipoLocalId;
  final String equipoVisitanteId;
  final String? equipoLocalNombre;
  final String? equipoVisitanteNombre;
  final String? equipoLocalEscudo;
  final String? equipoVisitanteEscudo;
  final DateTime fecha;
  final String hora;
  final String? lugar;
  final String? categoria;
  final int? golesLocal;
  final int? golesVisitante;
  final bool jugado;
  final String estado; // programado, en_juego, finalizado
  final DateTime? createdAt;

  const Partido({
    required this.id,
    required this.equipoLocalId,
    required this.equipoVisitanteId,
    this.equipoLocalNombre,
    this.equipoVisitanteNombre,
    this.equipoLocalEscudo,
    this.equipoVisitanteEscudo,
    required this.fecha,
    this.hora = '12:00',
    this.lugar,
    this.categoria,
    this.golesLocal,
    this.golesVisitante,
    this.jugado = false,
    this.estado = 'programado',
    this.createdAt,
  });

  factory Partido.fromMap(Map<String, dynamic> map) {
    final local = map['equipo_local'];
    final visitante = map['equipo_visitante'];
    return Partido(
      id: map['id'].toString(),
      equipoLocalId: map['equipo_local_id']?.toString() ?? '',
      equipoVisitanteId: map['equipo_visitante_id']?.toString() ?? '',
      // supports nombre_equipo (ER schema) and nombre (legacy)
      equipoLocalNombre: local?['nombre_equipo'] ?? local?['nombre'],
      equipoVisitanteNombre: visitante?['nombre_equipo'] ?? visitante?['nombre'],
      equipoLocalEscudo: local?['escudo_url'],
      equipoVisitanteEscudo: visitante?['escudo_url'],
      fecha: DateTime.tryParse(map['fecha'] ?? '') ?? DateTime.now(),
      hora: map['hora'] ?? '12:00',
      lugar: map['lugar'],
      categoria: map['categoria'],
      golesLocal: map['goles_local'],
      golesVisitante: map['goles_visitante'],
      jugado: map['jugado'] ?? false,
      estado: map['estado'] ?? 'programado',
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'equipo_local_id': equipoLocalId,
      'equipo_visitante_id': equipoVisitanteId,
      'fecha': fecha.toIso8601String().split('T')[0],
      'hora': hora,
      'lugar': lugar,
      'categoria': categoria,
      'goles_local': golesLocal,
      'goles_visitante': golesVisitante,
      'jugado': jugado,
      'estado': estado,
    };
  }

  String get marcador {
    if (!jugado) return 'vs';
    return '${golesLocal ?? 0} - ${golesVisitante ?? 0}';
  }
}
