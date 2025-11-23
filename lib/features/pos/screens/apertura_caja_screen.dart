import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym/features/pos/services/caja_repository.dart';
import 'package:gym/features/socios/bloc/auth_bloc.dart';
import 'package:intl/intl.dart';

class AperturaCajaScreen extends StatefulWidget {
  const AperturaCajaScreen({super.key});

  @override
  State<AperturaCajaScreen> createState() => _AperturaCajaScreenState();
}

class _AperturaCajaScreenState extends State<AperturaCajaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _montoController = TextEditingController();
  final _notasController = TextEditingController();
  final _repository = CajaRepository();
  bool _isLoading = false;

  @override
  void dispose() {
    _montoController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  Future<void> _abrirCaja() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Obtener usuario autenticado
      final authState = context.read<AuthBloc>().state;
      int? usuarioId;
      
      if (authState is AuthAuthenticatedState) {
        usuarioId = authState.user['id'] as int?;
      } else if (authState is AuthSuccess) {
        usuarioId = authState.usuario['id'] as int?;
      }

      if (usuarioId == null) {
        throw Exception('No se pudo identificar al usuario');
      }

      final monto = double.parse(_montoController.text);
      await _repository.abrirCaja(
        usuarioId,
        monto,
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
            content: Text('Error al abrir caja: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Apertura de Caja'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.point_of_sale,
                        size: 80,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Iniciar Turno',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ingresa el monto inicial en efectivo',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _montoController,
                        decoration: const InputDecoration(
                          labelText: 'Monto Inicial en Efectivo',
                          prefixIcon: Icon(Icons.attach_money),
                          border: OutlineInputBorder(),
                          helperText: 'Efectivo disponible al inicio del turno',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingresa el monto inicial';
                          }
                          final monto = double.tryParse(value);
                          if (monto == null || monto < 0) {
                            return 'Monto inválido';
                          }
                          return null;
                        },
                        autofocus: true,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notasController,
                        decoration: const InputDecoration(
                          labelText: 'Notas (Opcional)',
                          prefixIcon: Icon(Icons.note),
                          border: OutlineInputBorder(),
                          hintText: 'Ej: Turno mañana, Caja principal',
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _abrirCaja,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.check_circle),
                        label: Text(_isLoading ? 'Abriendo...' : 'Abrir Caja'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.of(context).pop(false),
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
          ),
        ),
      ),
    );
  }
}
