// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';

class NoEntregadoScreen extends StatefulWidget {
  const NoEntregadoScreen({
    super.key,
    this.pedido,
    required this.comentario,
    required this.idSubestado,
  });
  final dynamic pedido;
  final String comentario;
  final int idSubestado;

  @override
  State<NoEntregadoScreen> createState() => _NoEntregadoScreenState();
}

class _NoEntregadoScreenState extends State<NoEntregadoScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('NO ENTREGADO')),
      body: Text("No entregado"),
    );
  }
}
