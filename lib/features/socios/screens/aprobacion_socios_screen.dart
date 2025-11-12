import 'package:flutter/material.dart';
import 'package:gym/features/notificaciones/services/chatid_registro_service.dart';
import 'package:gym/features/socios/models/socio.dart';

class AprobacionSociosScreen extends StatefulWidget {
  @override
  _AprobacionSociosScreenState createState() => _AprobacionSociosScreenState();
}

class _AprobacionSociosScreenState extends State<AprobacionSociosScreen> {
  List<Socio> _sociosPendientes = [];
  bool _cargando = true;
  Map<String, dynamic> _estadisticas = {};

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    
    final socios = await ChatIdRegistroService.obtenerSociosPendientes();
    final stats = await ChatIdRegistroService.obtenerEstadisticasAprobacion();
    
    setState(() {
      _sociosPendientes = socios;
      _estadisticas = stats;
      _cargando = false;
    });
  }

  void _aprobarSocio(Socio socio) async {
    final exitoso = await ChatIdRegistroService.aprobarSocio(socio);
    
    if (exitoso) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Socio aprobado exitosamente')),
      );
      _cargarDatos();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error al aprobar socio')),
      );
    }
  }

  void _rechazarSocio(Socio socio) {
    showDialog(
      context: context,
      builder: (context) => DialogRechazoSocio(
        socio: socio,
        onRechazado: _cargarDatos,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Aprobación de Socios'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _cargarDatos,
          ),
        ],
      ),
      body: _cargando
          ? Center(child: CircularProgressIndicator())
          : _sociosPendientes.isEmpty
              ? _buildSinPendientes()
              : _buildListaPendientes(),
    );
  }

  Widget _buildSinPendientes() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, size: 80, color: Colors.green),
          SizedBox(height: 20),
          Text('No hay socios pendientes', style: TextStyle(fontSize: 18)),
          SizedBox(height: 10),
          Text('Todos los registros están aprobados', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildListaPendientes() {
    return Column(
      children: [
        // Estadísticas
        Card(
          margin: EdgeInsets.all(16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildEstadistica('Pendientes', _estadisticas['pendientes'] ?? 0, Colors.orange),
                _buildEstadistica('Total', _estadisticas['total'] ?? 0, Colors.blue),
              ],
            ),
          ),
        ),
        
        // Lista de socios pendientes
        Expanded(
          child: ListView.builder(
            itemCount: _sociosPendientes.length,
            itemBuilder: (context, index) {
              final socio = _sociosPendientes[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(Icons.person),
                  ),
                  title: Text(socio.nombreCompleto),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tel: ${socio.telefono}'),
                      Text('Registro: ${socio.fechaRegistroTelegram != null ? 
                        '${socio.fechaRegistroTelegram!.day}/${socio.fechaRegistroTelegram!.month}/${socio.fechaRegistroTelegram!.year}' : 
                        'N/A'}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.check, color: Colors.green),
                        onPressed: () => _aprobarSocio(socio),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.red),
                        onPressed: () => _rechazarSocio(socio),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEstadistica(String titulo, int valor, Color color) {
    return Column(
      children: [
        Text(titulo, style: TextStyle(color: Colors.grey)),
        SizedBox(height: 5),
        Text('$valor', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

class DialogRechazoSocio extends StatefulWidget {
  final Socio socio;
  final VoidCallback onRechazado;

  const DialogRechazoSocio({required this.socio, required this.onRechazado});

  @override
  _DialogRechazoSocioState createState() => _DialogRechazoSocioState();
}

class _DialogRechazoSocioState extends State<DialogRechazoSocio> {
  final _motivoController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Rechazar Socio'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('¿Rechazar a ${widget.socio.nombreCompleto}?'),
          SizedBox(height: 10),
          TextField(
            controller: _motivoController,
            decoration: InputDecoration(
              labelText: 'Motivo (opcional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () async {
            final exitoso = await ChatIdRegistroService.rechazarSocio(
              widget.socio,
              motivo: _motivoController.text.isEmpty ? null : _motivoController.text,
            );
            
            if (exitoso) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('❌ Socio rechazado')),
              );
              widget.onRechazado();
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: Text('Rechazar'),
        ),
      ],
    );
  }
}