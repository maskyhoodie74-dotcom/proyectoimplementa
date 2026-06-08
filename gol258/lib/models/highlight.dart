class Highlight {
  final int? id;
  final int? partidoId;
  final int? equipoId;
  final String urlMedia;
  final String tipo; // 'foto' o 'video'
  final String? descripcion;
  final DateTime? createdAt;

  Highlight({
    this.id,
    this.partidoId,
    this.equipoId,
    required this.urlMedia,
    this.tipo = 'foto',
    this.descripcion,
    this.createdAt,
  });

  factory Highlight.fromJson(Map<String, dynamic> json) {
    return Highlight(
      id: json['id'],
      partidoId: json['partido_id'],
      equipoId: json['equipo_id'],
      urlMedia: json['url_media'],
      tipo: json['tipo'] ?? 'foto',
      descripcion: json['descripcion'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (partidoId != null) 'partido_id': partidoId,
      if (equipoId != null) 'equipo_id': equipoId,
      'url_media': urlMedia,
      'tipo': tipo,
      if (descripcion != null) 'descripcion': descripcion,
    };
  }
}
