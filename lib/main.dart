import 'package:flutter/material.dart';
import 'package:gym/pages/lista_socios_screen.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'repositories/database_helper.dart';


Future<void> main() async {
  // Inicializa FFI para sqflite si la plataforma es web
  if (kIsWeb) {
    // Inicializa la fábrica de bases de datos FFI
    databaseFactory = databaseFactoryFfiWeb;
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App de Gimnasio',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ListaSociosScreen(), //Pantalla principal
      debugShowCheckedModeBanner: false, // Para que no diga DEBUG
    );
  }
}