import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym/features/socios/bloc/auth_bloc.dart';
import 'package:gym/features/auth/services/auth_service.dart'; // Importar el servicio de autenticación

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _dniController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _dniFocusNode = FocusNode();
  final _telefonoFocusNode = FocusNode();
  bool _isLoading = false;
  bool _biometricsAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final isAvailable = await AuthService.isBiometricAvailable();
    if (mounted) {
      setState(() {
        _biometricsAvailable = isAvailable;
      });
    }
  }

  /*
  @override
  void initState() {
    super.initState();
    
    // Precargar solo para desarrollo (opcional, quitar después)
    if (!const bool.fromEnvironment('dart.vm.product')) {
      _dniController.text = 'admin';
      _telefonoController.text = 'admin';
    }
  }
  */

  @override
  void dispose() {
    _dniController.dispose();
    _telefonoController.dispose();
    _dniFocusNode.dispose();
    _telefonoFocusNode.dispose();
    super.dispose();
  }

  void _login() {
    if (_dniController.text.isEmpty || _telefonoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ingrese DNI y teléfono')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    context.read<AuthBloc>().add(
      LoginEvent(
        dni: _dniController.text.trim(),
        telefono: _telefonoController.text.trim(),
      ),
    );
  }

  Future<void> _authenticateWithBiometrics() async {
    final isAuthenticated = await AuthService.authenticateWithBiometrics();

    if (isAuthenticated && mounted) {
      // Si la autenticación biométrica es exitosa, intenta obtener las credenciales guardadas.
      final credentials = await AuthService.getStoredCredentials();
      final dni = credentials['userId'];
      final token = credentials['token']; // Asumimos que el 'token' es el teléfono para este login.

      if (dni != null && token != null) {
        // Rellenar los campos y proceder con el login.
        _dniController.text = dni;
        _telefonoController.text = token;
        _login();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se encontraron credenciales guardadas. Inicie sesión manualmente una vez para guardarlas.')),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Autenticación fallida.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, dynamic>(
      listener: (context, state) {
        setState(() => _isLoading = false);

        // Si falla, mostrar mensaje
        if (state is AuthErrorState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error)),
          );
        }

        // Si el login fue exitoso, guardar credenciales y navegar.
        if (state is AuthSuccess || state is AuthAuthenticatedState) {
          // Guardar las credenciales para el próximo inicio de sesión con huella.
          final dni = _dniController.text.trim();
          final telefono = _telefonoController.text.trim();
          if (dni.isNotEmpty && telefono.isNotEmpty) {
            AuthService.saveCredentials(dni, telefono);
          }

          // Reemplazar la ruta actual por la principal.
          Navigator.of(context).pushReplacementNamed('/main');
        }
      },
      child: Scaffold(
        body: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.fitness_center, size: 80, color: Colors.blue),
              SizedBox(height: 20),
              Text('GYM MANAGER', 
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              SizedBox(height: 40),
              
              // Campo DNI
              TextField(
                controller: _dniController,
                focusNode: _dniFocusNode,
                decoration: InputDecoration(
                  labelText: 'DNI',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                onSubmitted: (_) {
                  // Navegar al campo de teléfono
                  FocusScope.of(context).requestFocus(_telefonoFocusNode);
                },
              ),
              SizedBox(height: 20),
              
              // Campo Teléfono
              TextField(
                controller: _telefonoController,
                focusNode: _telefonoFocusNode,
                decoration: InputDecoration(
                  labelText: 'Teléfono',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _login(),
                obscureText: false, // Cambiar a true si quieres ocultarlo
              ),
              SizedBox(height: 30),
              
              // Botón Login
              SizedBox(
                width: double.infinity,
                height: 50,
                child: _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _login,
                        child: Text('INGRESAR', style: TextStyle(fontSize: 16)),
                      ),
              ),
              SizedBox(height: 20),
              // Botón para autenticación con huella digital
              if (_biometricsAvailable)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.fingerprint),
                    label: Text('Usar Huella Digital'),
                    onPressed: _authenticateWithBiometrics,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}