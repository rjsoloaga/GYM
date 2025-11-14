import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:gym/features/socios/models/socio.dart';
import 'package:gym/features/auth/models/usuario.dart';

class ComprobanteService {
  /// Genera un comprobante de pago en PDF
  static Future<File?> generarComprobantePago({
    required Socio socio,
    required double monto,
    required DateTime fecha,
    required String metodo,
    Usuario? operador,
  }) async {
    try {
      final pdf = pw.Document();
      
      final dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss');
      final fechaFormato = dateFormat.format(fecha);
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a5,
          margin: pw.EdgeInsets.all(15),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Encabezado
                pw.Text(
                  'GYM MANAGER',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'COMPROBANTE DE PAGO',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Divider(),
                pw.SizedBox(height: 10),
                
                // Información del socio
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'SOCIO:',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      socio.nombreCompleto,
                      style: pw.TextStyle(fontSize: 11),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'ID: ${socio.id}',
                      style: pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      'Teléfono: ${socio.telefono}',
                      style: pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Divider(),
                pw.SizedBox(height: 10),
                
                // Información del pago
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Monto:', style: pw.TextStyle(fontSize: 10)),
                        pw.Text(
                          '\$${monto.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 5),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Método:', style: pw.TextStyle(fontSize: 10)),
                        pw.Text(
                          metodo,
                          style: pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 5),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Fecha:', style: pw.TextStyle(fontSize: 10)),
                        pw.Text(
                          fechaFormato,
                          style: pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                    if (operador != null) ...[
                      pw.SizedBox(height: 5),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Operador:', style: pw.TextStyle(fontSize: 10)),
                          pw.Text(
                            operador.nombreCompleto,
                            style: pw.TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Divider(),
                pw.SizedBox(height: 10),
                
                // Mensaje de cierre
                pw.Text(
                  '✅ PAGO REGISTRADO',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  '¡Gracias por tu pago!',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontSize: 10),
                ),
              ],
            );
          },
        ),
      );

      // Guardar el PDF
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'comprobante_${socio.id}_${fecha.millisecondsSinceEpoch}.pdf';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsBytes(await pdf.save());
      
      debugPrint('✅ Comprobante generado: ${file.path}');
      return file;
      
    } catch (e) {
      debugPrint('❌ Error generando comprobante PDF: $e');
      return null;
    }
  }

  /// Lee un archivo PDF y retorna los bytes
  static Future<List<int>?> leerComprobante(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error leyendo comprobante: $e');
      return null;
    }
  }

  /// Elimina un comprobante del almacenamiento
  static Future<bool> eliminarComprobante(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('✅ Comprobante eliminado: $filePath');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Error eliminando comprobante: $e');
      return false;
    }
  }
}