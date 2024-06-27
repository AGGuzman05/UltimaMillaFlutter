// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:ultimaMillaFlutter/screen/tabs/tabPendientes.dart';

class RutasScreen extends StatelessWidget {
  final String date;

  RutasScreen({required this.date}) : super(key: Key(date));

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('ASIGNACIONES POR FECHA'),
          bottom: TabBar(
            tabs: [
              Tab(text: "PENDIENTES"),
              Tab(text: "FINALIZADOS"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            TabPendientes(
              pedido: date,
              date: date,
            ),
            Center(child: Text("Pedidos finalizados")),
          ],
        ),
      ),
    );
  }
}
