import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym/features/socios/bloc/auth_bloc.dart';

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

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, dynamic>(
      listener: (context, state) {
        setState(() => _isLoading = false);
        
        if (state is AuthErrorState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error)),
          );
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
            ],
          ),
        ),
      ),
    );
  }
}