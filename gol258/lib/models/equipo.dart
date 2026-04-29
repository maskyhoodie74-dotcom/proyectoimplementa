class Equipo {
  final String id;
  final String nombre;       // nombre_equipo en DB
  final String? categoria;
  final String? entrenador;
  final String? escudoUrl;
  final String colorHex;
  final DateTime? createdAt;

  const Equipo({
    required this.id,
    required this.nombre,
    this.categoria,
    this.entrenador,
    this.escudoUrl,
    this.colorHex = '#6B1B2B',
    this.createdAt,
  });

  factory Equipo.fromMap(Map<String, dynamic> map) {
    return Equipo(
      id: map['id'].toString(),
      // supports both nombre_equipo (ER schema) and nombre (legacy)
      nombre: map['nombre_equipo'] ?? map['nombre'] ?? '',
      categoria: map['categoria'],
      entrenador: map['entrenador'],
      escudoUrl: map['escudo_url'],
      colorHex: map['color_hex'] ?? '#6B1B2B',
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre_equipo': nombre,
      'categoria': categoria,
      'entrenador': entrenador,
      'escudo_url': escudoUrl,
      'color_hex': colorHex,
    };
  }

  Equipo copyWith({String? nombre, String? categoria, String? entrenador, String? escudoUrl, String? colorHex}) {
    return Equipo(
      id: id,
      nombre: nombre ?? this.nombre,
      categoria: categoria ?? this.categoria,
      entrenador: entrenador ?? this.entrenador,
      escudoUrl: escudoUrl ?? this.escudoUrl,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt,
    );
  }
}
