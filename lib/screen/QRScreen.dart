// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:ultimaMillaFlutter/screen/pendientesScreen.dart';
import 'package:ultimaMillaFlutter/services/shared_functions.dart';

class QRScreen extends StatefulWidget {
  const QRScreen({super.key, required this.pedido});
  final String pedido;
  @override
  State<QRScreen> createState() => _QRScreenState();
}

class _QRScreenState extends State<QRScreen> {
  Map<String, dynamic>? pedido;
  dynamic usuario = {};

  @override
  void initState() {
    super.initState();
    getUsuario();
  }

  getUsuario() async {
    var user = await obtenerUsuario();
    setState(() {
      usuario = user;
    });
  }

  @override
  Widget build(BuildContext context) {
    var codigoPedido = (jsonDecode(widget.pedido)['codigoPedido']);

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text("QR CALIFICACION"),
          automaticallyImplyLeading: false,
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.all(50),
                child: Column(
                  children: [
                    if (usuario != null && usuario?['idUnidad'] != null)
                      Column(
                        children: [
                          Center(
                              child: SizedBox(
                            width: 250,
                            child: QrImageView(
                                data:
                                    'https://gestiondeflota.boltrack.net/assets/rastreo.html?${usuario?['idUnidad']}/${usuario?['idEmpresa']}/$codigoPedido'),
                          )),
                          Text(
                            'ESTE CODIGO PUEDE SER ESCANEADO POR EL CLIENTE PARA HACER LA CALIFICACION RESPECTIVA',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      )
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(10.0),
          child: ElevatedButton(
            onPressed: () {
              //Si es posible que vaya a tab finalizados
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PendientesScreen(),
                ),
              );
            },
            child: Text('Continuar'),
          ),
        ),
      ),
    );
  }
}
