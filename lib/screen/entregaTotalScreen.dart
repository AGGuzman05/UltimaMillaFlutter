// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';

class EntregaTotalScreen extends StatefulWidget {
  const EntregaTotalScreen(
      {super.key,
      this.pedido,
      required this.comentario,
      required this.idSubestado,
      required this.tiempoDescarga});
  final dynamic pedido;
  final String comentario;
  final int idSubestado;
  final int tiempoDescarga;

  @override
  State<EntregaTotalScreen> createState() => _EntregaTotalScreenState();
}

class _EntregaTotalScreenState extends State<EntregaTotalScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('ENTREGA TOTAL')),
      body: Center(
        child: Text("Entrega total"),
      ),
    );
  }
}
