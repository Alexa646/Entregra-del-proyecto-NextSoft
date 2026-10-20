class Incidencia {
  String id;
  String titulo;
  String descripcion;
  String cliente;
  String categoria;
  String estado;
  String prioridad; // Feat 001
  String fecha;

  // Lista de prioridades válidas aprobadas
  static const List<String> prioridadesValidas = ['Baja', 'Media', 'Alta'];

  Incidencia({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.cliente,
    required this.categoria,
    required this.estado,
    required this.prioridad,
    required this.fecha,
  });

factory Incidencia.desdeJson(Map<String, dynamic> m) {
    String p = m['prioridad']?.toString() ?? '';
    if (!prioridadesValidas.contains(p)) {
      p = 'Media'; // Valor predeterminado para registros antiguos o inválidos
    }

    return Incidencia(
      id: m['id']?.toString() ?? '',
      titulo: m['titulo']?.toString() ?? '',
      descripcion: m['descripcion']?.toString() ?? '',
      cliente: m['cliente']?.toString() ?? '',
      categoria: m['categoria']?.toString() ?? 'Software',
      estado: m['estado']?.toString() ?? 'Pendiente',
      prioridad: p, // <-- Campo agregado
      fecha: m['fecha']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'cliente': cliente,
      'categoria': categoria,
      'estado': estado,
      'prioridad': prioridad,
      'fecha': fecha,
    };
  }
}
