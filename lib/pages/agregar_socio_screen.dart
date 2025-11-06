import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:gym/blocs/socios_bloc.dart';
import 'package:gym/models/socio.dart';

class AgregarSocioScreen extends StatefulWidget {
  final Socio? socioParaEditar;

  const AgregarSocioScreen({super.key, this.socioParaEditar});

  @override
  State<AgregarSocioScreen> createState() => _AgregarSocioScreenState();
}

class _AgregarSocioScreenState extends State<AgregarSocioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _dniController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _correoController = TextEditingController();
  final _precioController = TextEditingController();

  DateTime? _fechaInicio;
  DateTime? _fechaVencimiento;
  String _tipoPlan = 'Mensual';

  final List<String> _tiposPlan = ['Mensual', 'Trimestral', 'Semestral', 'Anual'];

  @override
  void initState() {
    super.initState();
    if (widget.socioParaEditar != null) {
      _cargarDatosExistente();
    } else {
      _fechaInicio = DateTime.now();
      _fechaVencimiento = DateTime.now().add(const Duration(days: 30));
    }
  }

  void _cargarDatosExistente() {
    final socio = widget.socioParaEditar!;
    _nombreController.text = socio.nombreCompleto;
    _dniController.text = socio.dni;
    _telefonoController.text = socio.telefono;
    _correoController.text = socio.correo;
    _precioController.text = socio.precioMensual.toString();
    _fechaInicio = socio.fechaInicio;
    _fechaVencimiento = socio.fechaVencimiento;
    _tipoPlan = socio.tipoPlan;
  }

  Future<void> _selectFechaInicio(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaInicio ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('es', 'ES'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF2196F3),
              onPrimary: Colors.white,
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _fechaInicio = picked;
        // Ajustar fecha de vencimiento según el tipo de plan
        _actualizarFechaVencimiento();
      });
    }
  }

  Future<void> _selectFechaVencimiento(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaVencimiento ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: _fechaInicio ?? DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF2196F3),
              onPrimary: Colors.white,
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
      locale: const Locale('es', 'ES'),
    );
    if (picked != null) {
      setState(() {
        _fechaVencimiento = picked;
      });
    }
  }

  void _actualizarFechaVencimiento() {
    if (_fechaInicio == null) return;

    int dias = 30; // Por defecto mensual
    switch (_tipoPlan) {
      case 'Mensual':
        dias = 30;
        break;
      case 'Trimestral':
        dias = 90;
        break;
      case 'Semestral':
        dias = 180;
        break;
      case 'Anual':
        dias = 365;
        break;
    }

    setState(() {
      _fechaVencimiento = _fechaInicio!.add(Duration(days: dias));
    });
  }

  void _guardarSocio() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_fechaInicio == null || _fechaVencimiento == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona las fechas'),
          backgroundColor: Color(0xFFCF6679),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final socio = Socio(
      id: widget.socioParaEditar?.id,
      nombreCompleto: _nombreController.text.trim(),
      dni: _dniController.text.trim(),
      telefono: _telefonoController.text.trim(),
      correo: _correoController.text.trim(),
      fechaInicio: _fechaInicio!,
      fechaVencimiento: _fechaVencimiento!,
      precioMensual: double.tryParse(_precioController.text) ?? 0.0,
      tipoPlan: _tipoPlan,
    );

    if (widget.socioParaEditar == null) {
      context.read<SociosBloc>().add(AgregarSocioEvent(socio));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Socio agregado correctamente'),
          backgroundColor: Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      context.read<SociosBloc>().add(ActualizarSocioEvent(socio));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Socio actualizado correctamente'),
          backgroundColor: Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    Navigator.pop(context);
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _dniController.dispose();
    _telefonoController.dispose();
    _correoController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.socioParaEditar == null ? 'Agregar Nuevo Socio' : 'Editar Socio'),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0D1B2A), Color(0xFF1B263B)],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF121212),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Tarjeta del formulario
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF3A3A3A),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Nombre Completo
                      TextFormField(
                        controller: _nombreController,
                        decoration: InputDecoration(
                          labelText: 'Nombre Completo *',
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: const Color(0xFF2C2C2C),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El nombre es obligatorio';
                          }
                          if (value.trim().length < 3) {
                            return 'El nombre debe tener al menos 3 caracteres';
                          }
                          return null;
                        },
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 20),

                      // DNI
                      TextFormField(
                        controller: _dniController,
                        decoration: InputDecoration(
                          labelText: 'DNI *',
                          prefixIcon: const Icon(Icons.badge),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: const Color(0xFF2C2C2C),
                          enabled: widget.socioParaEditar == null,
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El DNI es obligatorio';
                          }
                          if (value.trim().length < 7) {
                            return 'El DNI debe tener al menos 7 dígitos';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Teléfono
                      TextFormField(
                        controller: _telefonoController,
                        decoration: InputDecoration(
                          labelText: 'Teléfono',
                          prefixIcon: const Icon(Icons.phone),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: const Color(0xFF2C2C2C),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value != null && value.isNotEmpty && value.length < 8) {
                            return 'El teléfono debe tener al menos 8 dígitos';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Correo Electrónico
                      TextFormField(
                        controller: _correoController,
                        decoration: InputDecoration(
                          labelText: 'Correo Electrónico',
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: const Color(0xFF2C2C2C),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            // Validación básica de formato de correo
                            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                            if (!emailRegex.hasMatch(value)) {
                              return 'Ingresa un correo válido';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Tipo de Plan
                      DropdownButtonFormField<String>(
                        value: _tipoPlan,
                        decoration: InputDecoration(
                          labelText: 'Tipo de Plan *',
                          prefixIcon: const Icon(Icons.calendar_today),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: const Color(0xFF2C2C2C),
                        ),
                        items: _tiposPlan.map((String plan) {
                          return DropdownMenuItem<String>(
                            value: plan,
                            child: Text(plan),
                          );
                        }).toList(),
                        onChanged: (String? nuevoPlan) {
                          if (nuevoPlan != null) {
                            setState(() {
                              _tipoPlan = nuevoPlan;
                              _actualizarFechaVencimiento();
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 20),

                      // Precio Mensual
                      TextFormField(
                        controller: _precioController,
                        decoration: InputDecoration(
                          labelText: 'Precio Mensual *',
                          prefixIcon: const Icon(Icons.attach_money),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: const Color(0xFF2C2C2C),
                        ),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El precio es obligatorio';
                          }
                          final precio = double.tryParse(value);
                          if (precio == null || precio <= 0) {
                            return 'Ingresa un precio válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Fecha de Inicio
                      InkWell(
                        onTap: () => _selectFechaInicio(context),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C2C2C),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF3A3A3A)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_month, color: Colors.grey),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Fecha de Inicio *',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _fechaInicio != null
                                          ? DateFormat('dd/MM/yyyy').format(_fechaInicio!)
                                          : 'Seleccionar fecha',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Fecha de Vencimiento
                      InkWell(
                        onTap: () => _selectFechaVencimiento(context),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C2C2C),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF3A3A3A)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.event, color: Colors.grey),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Fecha de Vencimiento *',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _fechaVencimiento != null
                                          ? DateFormat('dd/MM/yyyy').format(_fechaVencimiento!)
                                          : 'Seleccionar fecha',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Botón Guardar
                                  ElevatedButton(
                    onPressed: _guardarSocio,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                  child: const Text(
                    'Guardar Socio',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}