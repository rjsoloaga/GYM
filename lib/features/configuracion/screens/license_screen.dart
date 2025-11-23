import 'package:flutter/material.dart';
import 'package:gym/services/license_service.dart';

class LicenseScreen extends StatefulWidget {
  const LicenseScreen({super.key});

  @override
  State<LicenseScreen> createState() => _LicenseScreenState();
}

class _LicenseScreenState extends State<LicenseScreen> {
  final LicenseService _licenseService = LicenseService();
  final TextEditingController _licenseKeyController = TextEditingController();
  LicenseStatus? _currentStatus;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLicenseStatus();
  }

  Future<void> _loadLicenseStatus() async {
    setState(() => _isLoading = true);
    try {
      final status = await _licenseService.checkLicense();
      setState(() {
        _currentStatus = status;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando licencia: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _activateLicense() async {
    final key = _licenseKeyController.text.trim();
    if (key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa una clave de licencia'), backgroundColor: Colors.orange),
      );
      return;
    }

    // Determinar tipo según formato de clave (ejemplo simple)
    String type = 'basic';
    if (key.startsWith('PREMIUM-')) {
      type = 'premium';
    }

    final success = await _licenseService.activateLicense(key, type);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Licencia activada correctamente'), backgroundColor: Colors.green),
      );
      _licenseKeyController.clear();
      await _loadLicenseStatus();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Clave de licencia inválida'), backgroundColor: Colors.red),
      );
    }
  }

  Color _getStatusColor() {
    if (_currentStatus == null) return Colors.grey;
    if (_currentStatus!.isExpired) return Colors.red;
    if (_currentStatus!.isTrial) {
      if (_currentStatus!.daysRemaining < 7) return Colors.orange;
      return Colors.blue;
    }
    return Colors.green;
  }

  IconData _getStatusIcon() {
    if (_currentStatus == null) return Icons.help_outline;
    if (_currentStatus!.isExpired) return Icons.block;
    if (_currentStatus!.isTrial) return Icons.access_time;
    if (_currentStatus!.isPremium) return Icons.workspace_premium;
    return Icons.check_circle;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Licencia y Suscripción'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Estado actual
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(
                            _getStatusIcon(),
                            size: 64,
                            color: _getStatusColor(),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _currentStatus?.type.toUpperCase() ?? 'DESCONOCIDO',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _currentStatus?.message ?? 'Cargando...',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16),
                          ),
                          if (_currentStatus != null && _currentStatus!.isTrial && _currentStatus!.daysRemaining > 0) ...[
                            const SizedBox(height: 16),
                            LinearProgressIndicator(
                              value: _currentStatus!.daysRemaining / LicenseService.trialDays,
                              backgroundColor: Colors.grey.shade300,
                              valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor()),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Planes disponibles
                  const Text(
                    'Planes Disponibles',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  _buildPlanCard(
                    title: 'Plan Básico',
                    price: '\$29.99/mes',
                    features: [
                      'Gestión de socios ilimitados',
                      'Control de asistencia',
                      'Reportes básicos',
                      'Soporte por email',
                    ],
                    color: Colors.blue,
                  ),

                  const SizedBox(height: 16),

                  _buildPlanCard(
                    title: 'Plan Premium',
                    price: '\$49.99/mes',
                    features: [
                      'Todo lo del Plan Básico',
                      'Notificaciones automáticas (Email + Telegram)',
                      'Gestión de rutinas y ejercicios',
                      'Reportes avanzados y auditoría',
                      'Copias de seguridad automáticas',
                      'Soporte prioritario',
                    ],
                    color: Colors.purple,
                    recommended: true,
                  ),

                  const SizedBox(height: 30),

                  // Activar licencia
                  const Text(
                    'Activar Licencia',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _licenseKeyController,
                    decoration: const InputDecoration(
                      labelText: 'Clave de Licencia',
                      hintText: 'XXXX-XXXX-XXXX-XXXX',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.vpn_key),
                    ),
                  ),
                  const SizedBox(height: 16),

                  ElevatedButton.icon(
                    onPressed: _activateLicense,
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Activar Licencia'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Información de contacto
                  Card(
                    color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '¿Necesitas ayuda?',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          const Text('Contacta con nuestro equipo de ventas:'),
                          const SizedBox(height: 4),
                          const Text('📧 javiersoloaga5@gmail.com'),
                          const Text('📞 +54 9  362 4856916'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    required List<String> features,
    required Color color,
    bool recommended = false,
  }) {
    return Card(
      elevation: recommended ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: recommended ? BorderSide(color: color, width: 2) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                if (recommended)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'RECOMENDADO',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              price,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...features.map((feature) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: color, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(feature)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _licenseKeyController.dispose();
    super.dispose();
  }
}
