import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym/features/socios/screens/lista_socios_screen.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:gym/core/database/database_helper.dart';
import 'package:gym/features/socios/bloc/socios_bloc.dart';


Future<void> main() async {
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SociosBloc(DatabaseHelper.instance)..add(CargarSociosEvent()),
      child: MaterialApp(
        title: 'App de Gimnasio',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: ListaSociosScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}