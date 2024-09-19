// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:ultimaMillaFlutter/screen/pendientesScreen.dart';
import 'package:ultimaMillaFlutter/screen/tabs/tabFinalizados.dart';
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
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PendientesScreen(),
                ),
              );
            },
          ),
          centerTitle: true,
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
              date: date,
            ),
            TabFinalizados(date: date)
          ],
        ),
      ),
    );
  }
}
