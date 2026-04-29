class Jugador {
  final String id;
  final String nombre;       // nombre_jugador en DB
  final String equipoId;
  final String? equipoNombre;
  final int numero;
  final String? posicion;
  final int goles;
  final int asistencias;
  final int partidos;
  final String? fotoUrl;
  final DateTime? createdAt;

  const Jugador({
    required this.id,
    required this.nombre,
    required this.equipoId,
    this.equipoNombre,
    this.numero = 0,
    this.posicion,
    this.goles = 0,
    this.asistencias = 0,
    this.partidos = 0,
    this.fotoUrl,
    this.createdAt,
  });

  factory Jugador.fromMap(Map<String, dynamic> map) {
    return Jugador(
      id: map['id'].toString(),
      nombre: map['nombre_jugador'] ?? map['nombre'] ?? '',
      equipoId: map['equipo_id']?.toString() ?? '',
      equipoNombre: map['equipos']?['nombre_equipo'] ?? map['equipos']?['nombre'],
      numero: map['numero'] ?? 0,
      posicion: map['posicion'],
      goles: map['goles'] ?? 0,
      asistencias: map['asistencias'] ?? 0,
      partidos: map['partidos'] ?? 0,
      fotoUrl: map['foto_url'],
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre_jugador': nombre,
      'equipo_id': equipoId,
      'numero': numero,
      'posicion': posicion,
      'goles': goles,
      'asistencias': asistencias,
      'partidos': partidos,
      'foto_url': fotoUrl,
    };
  }
}
