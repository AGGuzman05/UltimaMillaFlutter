// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ultimaMillaFlutter/services/shared_functions.dart';
import 'package:ultimaMillaFlutter/util/const/parametroConexion.dart';

class GestionInventarioScreen extends StatefulWidget {
  const GestionInventarioScreen({super.key, required this.pedido});

  final dynamic pedido;

  @override
  _GestionInventarioScreenState createState() =>
      _GestionInventarioScreenState();
}

class _GestionInventarioScreenState extends State<GestionInventarioScreen> {
  List ventas = [];
  List stock = [];
  bool interfazRealizarVenta = true;
  bool deshabilitarBoton = false;

  @override
  void initState() {
    super.initState();
    _getVentasEfectuadas();
    _getInventario();
  }

  Future<void> _getVentasEfectuadas() async {
    try {
      Map<String, dynamic> usuario = await obtenerUsuario();
      // Suponiendo que params están obtenidos de alguna manera en Flutter
      var pedido = jsonDecode(widget.pedido);
      Map<String, dynamic> obj = {
        'token': usuario['token'],
        'idDetallePedido': pedido['idDetallePedido'],
        'idPuntoInteres': pedido['idPuntoInteres'],
      };
      final response = await doFetchJSON(URL_UM,
          {'data_op': obj, 'op': 'READ-OBTENERHISTORICOENTREGAPRODUCTOS'});
      print(response);
      if (response['error'] == false) {
        setState(() {
          ventas = response['data'];
        });
      } else {
        throw Exception('Error al obtener ventas efectuadas');
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _getInventario() async {
    Map<String, dynamic> usuario = await obtenerUsuario();
    final response = await doFetchJSON(URL_UM, {
      'data_op': {
        'token': usuario['token'],
        'unidad': usuario['idUnidad'],
      },
      'op': 'READ-OBTENERINVENTARIOPORUNIDAD',
    });
    if (response['error'] == false) {
      setState(() {
        stock = response['data']
            .map((e) => {...e, 'cantidadEntregando': 0})
            .toList();
      });
    } else {
      throw Exception('Error al obtener inventario');
    }
  }

  Future<void> _registrarProductosVendidos(Map<String, dynamic> obj) async {
    setState(() {
      deshabilitarBoton = true;
    });
    final response = await doFetchJSON(
        URL_UM, {'data_op': obj, 'op': 'CREATE-HISTORICOENTREGAPRODUCTOS'});
    print(response);
    if (response['error'] == true) {
      throw Exception('Error al registrar productos vendidos');
    }
    setState(() {
      deshabilitarBoton = false;
    });
  }

  Future<void> _actualizarInventario() async {
    try {
      for (var item in stock) {
        if (item['cantidadEntregando'] > 0) {
          var pedido = jsonDecode(widget.pedido);
          var meta = jsonDecode(pedido['meta']);

          Map<String, dynamic> usuario = await obtenerUsuario();
          Map<String, dynamic> obj = {
            'idDetallePedido': pedido['idDetallePedido'],
            'idPuntoInteres': pedido['idPuntoInteres'],
            'idProducto': item['idProducto'],
            'cantidad': item['cantidadEntregando'],
            'unidad': usuario['idUnidad'],
            'nombreConductor': meta['nombreConductor'] ?? '',
            'token': usuario['token']
          };
          await _registrarProductosVendidos(obj);
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Se actualizó el inventario'),
        ),
      );
      await _getInventario();
      await _getVentasEfectuadas();
      setState(() {
        interfazRealizarVenta = false;
      });
    } catch (error, stackTrace) {
      print(error);
      print(stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('GESTION DE VENTAS E INVENTARIO'),
          bottom: TabBar(tabs: [
            Tab(
              text: "REALIZAR VENTA DE PRODUCTOS",
            ),
            Tab(
              text: "VER VENTAS REALIZADAS",
            )
          ]),
        ),
        body: TabBarView(
          children: [
            Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: stock.length,
                    itemBuilder: (context, index) {
                      final item = stock[index];
                      return ListTile(
                        title: Text(item['nombre']),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 30,
                              height: 20,
                              child: TextField(
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.yellow[100],
                                  contentPadding: EdgeInsets.zero,
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (text) {
                                  if (double.tryParse(text) != null) {
                                    final cantidad = double.parse(text);
                                    if (cantidad <= item['cantidad']) {
                                      setState(() {
                                        stock[index]['cantidadEntregando'] =
                                            cantidad;
                                      });
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'La cantidad no puede ser mayor al inventario en stock'),
                                        ),
                                      );
                                    }
                                  }
                                },
                                //controller: TextEditingController(
                                //  text: item['cantidadEntregando'].toString(),
                                //),
                              ),
                            ),
                            Text('/${item['cantidad']}'),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                ElevatedButton(
                  onPressed: deshabilitarBoton ? null : _actualizarInventario,
                  child: Text('CONFIRMAR'),
                )
              ],
            ),
            Expanded(
              child: ListView.builder(
                itemCount: ventas.length,
                itemBuilder: (context, index) {
                  final e = ventas[index];
                  return Card(
                    margin: EdgeInsets.all(10),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('NOMBRE: ${e['nombre']}',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('CODIGO: ${e['codigo']}',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('CANTIDAD: ${e['cantidad']}',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
