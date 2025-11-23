import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym/features/pos/services/caja_repository.dart';
import 'package:gym/features/pos/screens/apertura_caja_screen.dart';
import 'package:gym/features/pos/screens/punto_venta_screen.dart';
import 'package:gym/features/socios/bloc/auth_bloc.dart';

/// Pantalla intermedia que verifica si hay caja abierta
/// y redirige a apertura o al POS según corresponda
class CajaVerificacionScreen extends StatefulWidget {
  const CajaVerificacionScreen({super.key});

  @override
  State<CajaVerificacionScreen> createState() => _CajaVerificacionScreenState();
}

class _CajaVerificacionScreenState extends State<CajaVerificacionScreen> {
  final _cajaRepository = CajaRepository();
  bool _verificando = true;

  @override
  void initState() {
    super.initState();
    _verificarYRedirigir();
  }

  Future<void> _verificarYRedirigir() async {
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

      // Verificar si hay caja abierta
      final cajaAbierta = await _cajaRepository.obtenerCajaAbierta(usuarioId);
      
      if (!mounted) return;

      if (cajaAbierta == null) {
        // No hay caja, mostrar apertura
        final resultado = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AperturaCajaScreen(),
            fullscreenDialog: true,
          ),
        );

        if (!mounted) return;

        if (resultado == true) {
          // Usuario abrió la caja, verificar de nuevo
          await _verificarYRedirigir();
        } else {
          // Usuario canceló, cerrar esta pantalla
          Navigator.of(context).pop();
        }
      } else {
        // Hay caja abierta, reemplazar esta pantalla con el POS
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => PuntoVentaScreen(cajaInicial: cajaAbierta),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error verificando caja: $e'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Verificando caja...'),
          ],
        ),
      ),
    );
  }
}
