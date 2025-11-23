import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym/features/pos/services/caja_repository.dart';
import 'package:gym/features/pos/models/caja_sesion.dart';
import 'package:gym/features/pos/screens/apertura_caja_screen.dart';
import 'package:gym/features/pos/screens/punto_venta_screen.dart';
import 'package:gym/features/socios/bloc/auth_bloc.dart';

/// Wrapper que verifica la caja antes de mostrar el POS
class PuntoVentaWrapper extends StatefulWidget {
  const PuntoVentaWrapper({super.key});

  @override
  State<PuntoVentaWrapper> createState() => _PuntoVentaWrapperState();
}

class _PuntoVentaWrapperState extends State<PuntoVentaWrapper> {
  late Future<CajaSesion?> _cajaFuture;
  bool _cancelled = false;

  @override
  void initState() {
    super.initState();
    _cajaFuture = _verificarCaja();
  }

  Future<CajaSesion?> _verificarCaja() async {
    final cajaRepository = CajaRepository();
    
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

    return await cajaRepository.obtenerCajaAbierta(usuarioId);
  }

  Future<void> _manejarAperturaCaja() async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const AperturaCajaScreen(),
        fullscreenDialog: true,
      ),
    );

    if (!mounted) return;

    if (resultado == true) {
      // Caja abierta, recargar
      setState(() {
        _cancelled = false;
        _cajaFuture = _verificarCaja();
      });
    } else {
      // Usuario canceló
      setState(() {
        _cancelled = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si el usuario canceló, mostrar pantalla de cancelación
    if (_cancelled) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Punto de Venta'),
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cancel_outlined, size: 80, color: Colors.orange),
              const SizedBox(height: 24),
              const Text(
                'Operación cancelada',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Debes abrir una caja para usar el punto de venta',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  // Reintentar
                  setState(() {
                    _cancelled = false;
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return FutureBuilder<CajaSesion?>(
      future: _cajaFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
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

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Volver'),
                  ),
                ],
              ),
            ),
          );
        }

        final caja = snapshot.data;

        if (caja == null) {
          // No hay caja, llamar al método que maneja la apertura
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _manejarAperturaCaja();
          });
          
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Hay caja, mostrar POS
        return PuntoVentaScreen(cajaInicial: caja);
      },
    );
  }
}
