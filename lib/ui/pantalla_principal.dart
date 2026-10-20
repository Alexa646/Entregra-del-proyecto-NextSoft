import 'package:flutter/material.dart';
import '../model/incidencia.dart';
import '../services/gestor_incidencias.dart';
import 'pantalla_detalle.dart';
import 'pantalla_nueva.dart';

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  final GestorIncidencias g = GestorIncidencias();
  bool cargando = true;
  String? error;

  // =========================================================================
  // CAMBIO FEAT-002: Nuevas variables de estado para controlar los filtros
  // =========================================================================
  String busqueda = '';
  String filtroEstado = 'Todos';
  String filtroPrioridad = 'Todas';
  // Controlador para el campo de búsqueda para poder limpiar el texto mediante código
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    cargar();
  }

  @override
  void dispose() {
    // CAMBIO FEAT-002: Liberar el controlador de búsqueda al destruir la pantalla
    _searchController.dispose();
    super.dispose();
  }

  Future<void> cargar() async {
    setState(() {
      cargando = true;
      error = null;
    });
    try {
      await g.iniciar();
    } catch (e) {
      error = 'No se pudieron cargar las incidencias: $e';
    }
    if (mounted) setState(() => cargando = false);
  }

  Color colorEstado(String estado) {
    if (estado == 'Resuelta') return const Color(0xFF147D64);
    if (estado == 'En proceso') return const Color(0xFFB56B13);
    return const Color(0xFFAC4052);
  }

  // =========================================================================
  // CAMBIO FEAT-001 / FEAT-002: Helper visual para el color de prioridad
  // =========================================================================
  Color colorPrioridad(String prioridad) {
    if (prioridad == 'Alta') return Colors.red.shade700;
    if (prioridad == 'Media') return Colors.orange.shade800;
    return Colors.blue.shade700;
  }

  Widget resumen(String etiqueta, String valor, IconData icono) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icono, size: 19, color: const Color(0xFF174C83)),
              const SizedBox(height: 4),
              Text(valor, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Text(etiqueta, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> abrirDetalle(Incidencia item) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => PantallaDetalle(gestor: g, id: item.id)),
    );
    if (mounted) setState(() {});
  }

  Future<void> abrirFormulario() async {
    final guardado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => PantallaNueva(gestor: g)),
    );
    if (guardado == true && mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incidencia registrada')),
      );
    }
  }

  // =========================================================================
  // CAMBIO FEAT-002: Método para reiniciar todos los filtros y el buscador
  // =========================================================================
  void limpiarFiltros() {
    setState(() {
      busqueda = '';
      filtroEstado = 'Todos';
      filtroPrioridad = 'Todas';
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    // =========================================================================
    // CAMBIO FEAT-002: Se invoca el método 'filtrar' pasando texto, estado y prioridad
    // =========================================================================
    final items = g.filtrar(busqueda, filtroEstado, filtroPrioridad);

    // Identifica si hay alguna condición activa diferente a la predeterminada
    final bool hayFiltrosActivos = busqueda.isNotEmpty || filtroEstado != 'Todos' || filtroPrioridad != 'Todas';

    return Scaffold(
      appBar: AppBar(
        title: const Text('NexaSoft | Incidencias'),
        actions: [
          IconButton(
            tooltip: 'Restablecer datos de demostración',
            onPressed: () async {
              final aceptar = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Restablecer demostración'),
                  content: const Text('Se descartarán los cambios locales y se cargarán las incidencias iniciales.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                    FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Restablecer')),
                  ],
                ),
              );
              if (aceptar != true) return;
              try {
                await g.reiniciarDemo();
                limpiarFiltros(); // Limpiar la vista al restablecer la demo
                if (mounted) setState(() {});
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al reiniciar: $e')));
                }
              }
            },
            icon: const Icon(Icons.restart_alt),
          ),
        ],
      ),
      floatingActionButton: cargando || error != null
          ? null
          : FloatingActionButton.extended(
              onPressed: abrirFormulario,
              label: const Text('Nueva incidencia'),
              icon: const Icon(Icons.add),
            ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(onPressed: cargar, child: const Text('Reintentar')),
                  ]),
                ))
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 860),
                    child: Column(
                      children: [
                        // Tarjetas de Resumen
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
                          child: Row(children: [
                            resumen('Pendientes', '${g.contar('Pendiente')}', Icons.pending_actions),
                            resumen('En proceso', '${g.contar('En proceso')}', Icons.build_outlined),
                            resumen('Resueltas', '${g.contar('Resuelta')}', Icons.check_circle_outline),
                          ]),
                        ),

                        // Campo de Búsqueda de texto
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 5),
                          child: TextField(
                            // CAMBIO FEAT-002: Asignación de controlador para sincronizar limpiado
                            controller: _searchController,
                            decoration: const InputDecoration(
                              labelText: 'Buscar incidencias',
                              hintText: 'Ejemplo: WiFi, correo, pantalla',
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (texto) => setState(() => busqueda = texto),
                          ),
                        ),

                        // =========================================================================
                        // CAMBIO FEAT-002: Nuevos menús desplegables para filtrar por Estado y Prioridad
                        // =========================================================================
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 6),
                          child: Row(
                            children: [
                              // Selector de Estado
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: filtroEstado,
                                  decoration: const InputDecoration(
                                    labelText: 'Estado',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  ),
                                  items: ['Todos', 'Pendiente', 'En proceso', 'Resuelta']
                                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                      .toList(),
                                  onChanged: (v) => setState(() => filtroEstado = v ?? 'Todos'),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Selector de Prioridad
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: filtroPrioridad,
                                  decoration: const InputDecoration(
                                    labelText: 'Prioridad',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  ),
                                  items: ['Todas', 'Baja', 'Media', 'Alta']
                                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                                      .toList(),
                                  onChanged: (v) => setState(() => filtroPrioridad = v ?? 'Todas'),
                                ),
                              ),

                              // Botón explícito para restablecer filtros y consulta
                              if (hayFiltrosActivos) ...[
                                const SizedBox(width: 8),
                                IconButton(
                                  tooltip: 'Limpiar filtros y búsqueda',
                                  onPressed: limpiarFiltros,
                                  icon: const Icon(Icons.clear_all, color: Colors.redAccent),
                                ),
                              ]
                            ],
                          ),
                        ),

                        // Contador de resultados filtrados
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text('${items.length} registros encontrados', style: const TextStyle(color: Colors.black54)),
                          ),
                        ),

                        // =========================================================================
                        // CAMBIO FEAT-002: Estado sin resultados interactivo y amigable
                        // =========================================================================
                        Expanded(
                          child: items.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.search_off, size: 48, color: Colors.black38),
                                        const SizedBox(height: 12),
                                        const Text(
                                          'No se encontraron incidencias con los filtros seleccionados.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontSize: 16, color: Colors.black54),
                                        ),
                                        const SizedBox(height: 16),
                                        OutlinedButton.icon(
                                          onPressed: limpiarFiltros,
                                          icon: const Icon(Icons.refresh),
                                          label: const Text('Limpiar búsqueda y filtros'),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.only(left: 12, right: 12, bottom: 100),
                                  itemCount: items.length,
                                  itemBuilder: (context, i) {
                                    final item = items[i];
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        title: Text(item.titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
                                        subtitle: Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('${item.id}  ·  ${item.cliente}'),
                                              const SizedBox(height: 6),
                                              // =========================================================
                                              // CAMBIO FEAT-001 / FEAT-002: Muestra de estado y prioridad
                                              // =========================================================
                                              Row(
                                                children: [
                                                  Text(
                                                    item.estado,
                                                    style: TextStyle(color: colorEstado(item.estado), fontWeight: FontWeight.bold),
                                                  ),
                                                  const Text('  ·  Prioridad: '),
                                                  Text(
                                                    item.prioridad,
                                                    style: TextStyle(color: colorPrioridad(item.prioridad), fontWeight: FontWeight.bold),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        trailing: const Icon(Icons.chevron_right),
                                        onTap: () => abrirDetalle(item),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}