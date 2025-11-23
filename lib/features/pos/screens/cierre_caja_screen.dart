import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gym/features/pos/models/caja_sesion.dart';
import 'package:gym/features/pos/services/caja_repository.dart';
import 'package:intl/intl.dart';

class CierreCajaScreen extends StatefulWidget {
  final CajaSesion caja;

  const CierreCajaScreen({super.key, required this.caja});

  @override
  State<CierreCajaScreen> createState() => _CierreCajaScreenState();
}

class _CierreCajaScreenState extends State<CierreCajaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _montoRealController = TextEditingController();
  final _notasController = TextEditingController();
  final _repository = CajaRepository();
  
  bool _isLoading = true;
  double _ventasEfectivo = 0.0;
  double _montoEsperado = 0.0;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      final ventas = await _repository.obtenerVentasEfectivoCaja(widget.caja.id!);
      setState(() {
        _ventasEfectivo = ventas;
        _montoEsperado = widget.caja.montoInicial + ventas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _montoRealController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  Future<void> _cerrarCaja() async {
    if (!_formKey.currentState!.validate()) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Cierre de Caja'),
        content: const Text(
          '¿Estás seguro de cerrar la caja? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Confirmar Cierre'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _isLoading = true);

    try {
      final montoReal = double.parse(_montoRealController.text);
      await _repository.cerrarCaja(
        cajaId: widget.caja.id!,
        montoFinalReal: montoReal,
        montoEsperado: _montoEsperado,
        notas: _notasController.text.trim().isEmpty ? null : _notasController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context, true); // Retorna true para indicar éxito
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cerrar caja: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  double get _diferencia {
    final montoReal = double.tryParse(_montoRealController.text) ?? 0.0;
    return montoReal - _montoEsperado;
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cierre de Caja'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Resumen de la sesión
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.access_time, color: Colors.blue[700]),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Resumen del Turno',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              _buildInfoRow('Apertura:', dateFormat.format(widget.caja.fechaApertura)),
                              _buildInfoRow('Monto Inicial:', currencyFormat.format(widget.caja.montoInicial)),
                              _buildInfoRow('Ventas en Efectivo:', currencyFormat.format(_ventasEfectivo), color: Colors.green),
                              const Divider(height: 24),
                              _buildInfoRow(
                                'Efectivo Esperado:',
                                currencyFormat.format(_montoEsperado),
                                isTotal: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Formulario de cierre
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Conteo de Efectivo',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _montoRealController,
                                  decoration: const InputDecoration(
                                    labelText: 'Efectivo Real en Caja',
                                    prefixIcon: Icon(Icons.attach_money),
                                    border: OutlineInputBorder(),
                                    helperText: 'Cuenta el efectivo físico en la caja',
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                                  ],
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Ingresa el monto real';
                                    }
                                    final monto = double.tryParse(value);
                                    if (monto == null || monto < 0) {
                                      return 'Monto inválido';
                                    }
                                    return null;
                                  },
                                  onChanged: (_) => setState(() {}), // Para actualizar la diferencia
                                  autofocus: true,
                                ),
                                const SizedBox(height: 16),
                                
                                // Mostrar diferencia si hay monto ingresado
                                if (_montoRealController.text.isNotEmpty) ...[
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: _diferencia == 0
                                          ? Colors.green.shade50
                                          : (_diferencia > 0 ? Colors.blue.shade50 : Colors.orange.shade50),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: _diferencia == 0
                                            ? Colors.green
                                            : (_diferencia > 0 ? Colors.blue : Colors.orange),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Diferencia:',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          currencyFormat.format(_diferencia),
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: _diferencia == 0
                                                ? Colors.green
                                                : (_diferencia > 0 ? Colors.blue : Colors.orange),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _diferencia == 0
                                        ? '✓ Cuadra perfecto'
                                        : _diferencia > 0
                                            ? '↑ Sobrante'
                                            : '↓ Faltante',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                TextFormField(
                                  controller: _notasController,
                                  decoration: const InputDecoration(
                                    labelText: 'Notas de Cierre (Opcional)',
                                    prefixIcon: Icon(Icons.note),
                                    border: OutlineInputBorder(),
                                    hintText: 'Observaciones, incidencias, etc.',
                                  ),
                                  maxLines: 3,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Botones
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _cerrarCaja,
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Cerrar Caja'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.green,
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _isLoading ? null : () => Navigator.pop(context),
                        icon: const Icon(Icons.cancel),
                        label: const Text('Cancelar'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
