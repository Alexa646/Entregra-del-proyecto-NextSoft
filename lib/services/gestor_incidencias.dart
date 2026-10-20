import '../data/almacen_local.dart';
import '../model/incidencia.dart';

class GestorIncidencias {
  final AlmacenLocal datos = AlmacenLocal();
  List<Incidencia> incidencias = [];
  int cantidadPendientes = 0;

  Future<void> iniciar() async {
    incidencias = await datos.leer();
    cantidadPendientes =
        incidencias.where((x) => x.estado == 'Pendiente').length;
  }

// --- CORRECCIÓN BUG-002: Búsqueda de incidencias por título y descripción ---
List<Incidencia> buscar(String texto) {
    // 1. Limpiamos los espacios sobrantes al inicio y al final, y pasamos a minúsculas
    final consulta = texto.trim().toLowerCase();
    
    // 2. Si no hay texto, devolvemos la lista completa sin descartar nada
    if (consulta.isEmpty) return incidencias;
    
    // 3. Filtramos buscando coincidencias tanto en el título como en la descripción (ignorando mayúsculas)
    return incidencias.where((x) {
      final tituloLower = x.titulo.toLowerCase();
      final descripcionLower = x.descripcion.toLowerCase();
      
      return tituloLower.contains(consulta) || descripcionLower.contains(consulta);
    }).toList();
  }

// Sustituye o complementa tu método buscar actual por este método de filtrado avanzado:
  List<Incidencia> filtrar(String texto, String estado, String prioridad) {
    final consulta = texto.trim().toLowerCase();

    return incidencias.where((x) {
      // 1. Filtro de texto (Título o Descripción)
      final coincideTexto = consulta.isEmpty ||
          x.titulo.toLowerCase().contains(consulta) ||
          x.descripcion.toLowerCase().contains(consulta);

      // 2. Filtro de Estado ("Todos" o el estado exacto)
      final coincideEstado = (estado == 'Todos') || (x.estado == estado);

      // 3. Filtro de Prioridad ("Todas" o la prioridad exacta)
      final coincidePrioridad = (prioridad == 'Todas') || (x.prioridad == prioridad);

      return coincideTexto && coincideEstado && coincidePrioridad;
    }).toList();
  }

  Incidencia? porId(String id) {
    for (var x in incidencias) {
      if (x.id == id) return x;
    }
    return null;
  }

// --- CORRECCIÓN BUG-003: Conteo dinámico y exacto por estado ---
  int contar(String estado) {
    // Cuenta directamente sobre la lista total, asegurando que los totales 
    // nunca dependan de la búsqueda, filtros visuales o estados intermedios.
    return incidencias.where((x) => x.estado == estado).length;
  }

  // --- CORRECCIÓN BUG-001 ---
  Future<void> cambiarEstado(String id, String estado) async {
    for (var i = 0; i < incidencias.length; i++) {
      if (incidencias[i].id == id) {
        incidencias[i].estado = estado;
        break;
      }
    }
    // Actualizamos el contador de pendientes dinámicamente
    cantidadPendientes =
        incidencias.where((x) => x.estado == 'Pendiente').length;
        
    // Guardamos la lista completa actualizada en SharedPreferences
    await datos.guardar(incidencias);
  }

  Future<void> cambiarPrioridad(String id, String prioridad) async {
    if (!Incidencia.prioridadesValidas.contains(prioridad)) return;
    for (var i = 0; i < incidencias.length; i++) {
      if (incidencias[i].id == id) {
        incidencias[i].prioridad = prioridad;
        break;
      }
    }
    // Guarda los cambios permanentemente en el almacenamiento local
    await datos.guardar(incidencias);
  }
  
  Future<void> crear(String titulo, String descripcion, String cliente,
      String categoria,String prioridad) async {
    final nuevo = Incidencia(
      id: 'INC-${DateTime.now().microsecondsSinceEpoch}',
      titulo: titulo,
      descripcion: descripcion,
      cliente: cliente,
      categoria: categoria,
      estado: 'Pendiente',
      prioridad: Incidencia.prioridadesValidas.contains(prioridad) ? prioridad : 'Media',
      fecha: DateTime.now().toIso8601String().split('T').first,
    );
    incidencias.insert(0, nuevo);
    cantidadPendientes++;
    await datos.guardar(incidencias);
  }

  Future<void> reiniciarDemo() async {
    await datos.restaurarDatosDeEjemplo();
    await iniciar();
  }
}