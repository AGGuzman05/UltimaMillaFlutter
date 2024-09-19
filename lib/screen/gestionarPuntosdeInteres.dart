// ignore_for_file: prefer_const_constructors, non_constant_identifier_names, prefer_const_literals_to_create_immutables

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:shimmer/shimmer.dart';
import 'package:ultimaMillaFlutter/screen/agregarEditarPuntodeInteres.dart';
import 'package:ultimaMillaFlutter/screen/widgets/customShimmer.dart';
import 'package:ultimaMillaFlutter/screen/widgets/menuDrawer.dart';
import 'package:ultimaMillaFlutter/services/shared_functions.dart';
import 'package:ultimaMillaFlutter/util/const/constants.dart';
import 'package:ultimaMillaFlutter/util/const/parametroConexion.dart';

class GestionarPuntosdeInteres extends StatefulWidget {
  const GestionarPuntosdeInteres({
    required this.cliente,
    super.key,
  });
  final dynamic cliente;

  @override
  State<GestionarPuntosdeInteres> createState() =>
      _GestionarPuntosdeInteresState();
}

class _GestionarPuntosdeInteresState extends State<GestionarPuntosdeInteres> {
  bool loadingData = false;
  List<dynamic> listaPuntosdeInteres = [];
  List<dynamic> listaFiltrada = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    getListaPuntosdeInteres();
  }

  Future<void> getListaPuntosdeInteres() async {
    setState(() {
      loadingData = true;
    });
    var puntosdeInteres = await doFetchJSONv2(
        URL_UM_V2 + ENDPOINTS.OBTENERPUNTOSDEINTERESPORCLIENTE,
        {"idCliente": widget.cliente['id']});
    print(puntosdeInteres);
    setState(() {
      listaPuntosdeInteres = puntosdeInteres['body'];
      listaFiltrada = puntosdeInteres['body'];
      loadingData = false;
    });
  }

  void buscar(String text) {
    try {
      if (text.isNotEmpty) {
        print(text);
        final coincidencias = listaPuntosdeInteres.where((e) {
          return e['codigoPuntoInteres']
                  .toString()
                  .toLowerCase()
                  .contains(text.toLowerCase()) ||
              e['nombrePuntoInteres']
                  .toString()
                  .toLowerCase()
                  .contains(text.toLowerCase());
        }).toList();
        setState(() {
          listaFiltrada = coincidencias;
        });
      } else {
        setState(() {
          listaFiltrada = List.from(listaPuntosdeInteres);
        });
      }
    } catch (error) {
      print(error);
    }
  }

  Widget HeaderSection() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: Color(0xFF21203F),
          padding: EdgeInsets.all(10),
          margin: EdgeInsets.only(top: 8),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(left: 4),
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(7)),
                    border: Border(
                        bottom: BorderSide(color: Color(0xFFCCCCCC), width: 2)),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.only(top: -7, left: 4),
                      hintText: 'Buscar...',
                      border: InputBorder.none,
                    ),
                    onChanged: buscar,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text("PUNTOS DE INTERES"),
        centerTitle: true,
      ),
      body: loadingData
          ? customShimmer()
          : SingleChildScrollView(
              child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                        child: Padding(
                      padding: const EdgeInsets.only(left: 5.0),
                      child: Text(widget.cliente['nombre']),
                    )),
                    ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => AgregarEditarPuntoInteres(
                                    isNewPoint: true,
                                    idCliente: widget.cliente['id'])),
                          );
                        },
                        child: Text("NUEVO P. DE INTERES")),
                  ],
                ),
                HeaderSection(),
                Divider(),
                Column(
                  children: listaFiltrada
                      .map((item) => Card(
                              child: Container(
                            padding: EdgeInsets.all(8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          "CODIGO: ",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12),
                                        ),
                                        ConstrainedBox(
                                          constraints:
                                              BoxConstraints(maxWidth: 170),
                                          child: Text(
                                            item['codigoPuntoInteres']
                                                    .toString()
                                                    .toUpperCase() ??
                                                "",
                                            style: TextStyle(fontSize: 12),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          "NOMBRE: ",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12),
                                        ),
                                        ConstrainedBox(
                                          constraints:
                                              BoxConstraints(maxWidth: 170),
                                          child: Text(
                                            item['nombrePuntoInteres']
                                                    .toString()
                                                    .toUpperCase() ??
                                                "",
                                            style: TextStyle(fontSize: 12),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                AgregarEditarPuntoInteres(
                                                  isNewPoint: false,
                                                  punto: item,
                                                )),
                                      );
                                    },
                                    child: Text("EDITAR"))
                              ],
                            ),
                          )))
                      .toList(),
                ),
              ],
            )),
    );
  }
}
