class LiguillaTorneo {
  final String id;
  final String nombre;
  final String estado; // activo | finalizado
  final int numEquipos;
  final DateTime? createdAt;

  const LiguillaTorneo({
    required this.id,
    required this.nombre,
    this.estado = 'activo',
    required this.numEquipos,
    this.createdAt,
  });

  factory LiguillaTorneo.fromMap(Map<String, dynamic> map) {
    return LiguillaTorneo(
      id: map['id'].toString(),
      nombre: map['nombre'] ?? 'Torneo',
      estado: map['estado'] ?? 'activo',
      numEquipos: map['num_equipos'] ?? 4,
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at']) : null,
    );
  }
}

class LiguillaEquipoInfo {
  final String id;
  final String torneoId;
  final String equipoId;
  final int seed;
  
  // Datos unidos desde la tabla 'equipos'
  final String? nombreEquipo;
  final String? escudoUrl;
  final String? colorHex;

  const LiguillaEquipoInfo({
    required this.id,
    required this.torneoId,
    required this.equipoId,
    required this.seed,
    this.nombreEquipo,
    this.escudoUrl,
    this.colorHex,
  });

  factory LiguillaEquipoInfo.fromMap(Map<String, dynamic> map) {
    final eq = map['equipos']; // Relación en Supabase
    return LiguillaEquipoInfo(
      id: map['id'].toString(),
      torneoId: map['torneo_id'].toString(),
      equipoId: map['equipo_id'].toString(),
      seed: map['seed'] ?? 0,
      nombreEquipo: eq?['nombre_equipo'],
      escudoUrl: eq?['escudo_url'],
      colorHex: eq?['color_hex'],
    );
  }
}

class LiguillaPartido {
  final String id;
  final String torneoId;
  final String ronda; // final, semis, cuartos, octavos
  final int numeroPartido;
  final String? equipoLocalId;
  final String? equipoVisitanteId;
  
  // Nombres y escudos (Join)
  final String? equipoLocalNombre;
  final String? equipoVisitanteNombre;
  final String? equipoLocalEscudo;
  final String? equipoVisitanteEscudo;
  
  final DateTime? fecha;
  final String hora;
  final String? lugar;
  final int? golesLocal;
  final int? golesVisitante;
  final bool jugado;
  final String estado;

  const LiguillaPartido({
    required this.id,
    required this.torneoId,
    required this.ronda,
    required this.numeroPartido,
    this.equipoLocalId,
    this.equipoVisitanteId,
    this.equipoLocalNombre,
    this.equipoVisitanteNombre,
    this.equipoLocalEscudo,
    this.equipoVisitanteEscudo,
    this.fecha,
    this.hora = '12:00',
    this.lugar,
    this.golesLocal,
    this.golesVisitante,
    this.jugado = false,
    this.estado = 'programado',
  });

  factory LiguillaPartido.fromMap(Map<String, dynamic> map) {
    final local = map['equipo_local'];
    final visitante = map['equipo_visitante'];
    
    return LiguillaPartido(
      id: map['id'].toString(),
      torneoId: map['torneo_id'].toString(),
      ronda: map['ronda'] ?? '',
      numeroPartido: map['numero_partido'] ?? 0,
      equipoLocalId: map['equipo_local_id']?.toString(),
      equipoVisitanteId: map['equipo_visitante_id']?.toString(),
      equipoLocalNombre: local?['nombre_equipo'],
      equipoVisitanteNombre: visitante?['nombre_equipo'],
      equipoLocalEscudo: local?['escudo_url'],
      equipoVisitanteEscudo: visitante?['escudo_url'],
      fecha: map['fecha'] != null ? DateTime.tryParse(map['fecha']) : null,
      hora: map['hora'] ?? '12:00',
      lugar: map['lugar'],
      golesLocal: map['goles_local'],
      golesVisitante: map['goles_visitante'],
      jugado: map['jugado'] ?? false,
      estado: map['estado'] ?? 'programado',
    );
  }

  String get marcador {
    if (!jugado) return 'vs';
    return '${golesLocal ?? 0} - ${golesVisitante ?? 0}';
  }
}
