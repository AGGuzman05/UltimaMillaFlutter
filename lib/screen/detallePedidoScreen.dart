// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:ultimaMillaFlutter/screen/tabs/tabGestionarPedido.dart';

class DetalleScreen extends StatelessWidget {
  final dynamic pedido;
  final String date;

  DetalleScreen({required this.pedido, required this.date})
      : super(key: Key(pedido));

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('DETALLE ASIGNACION'),
          centerTitle: true,
          bottom: TabBar(
            tabs: [
              Tab(text: "GESTION"),
              Tab(text: "INFORMACION"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            TabGestionar(pedido: pedido, date: date),
            Center(child: Text("Informacion del pedido")),
          ],
        ),
      ),
    );
  }
}
