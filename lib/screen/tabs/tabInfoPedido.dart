// ignore_for_file: deprecated_member_use, prefer_const_constructors, prefer_const_literals_to_create_immutables, library_private_types_in_public_api

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';
import 'package:ultimaMillaFlutter/screen/gestionarInventario.dart';
import 'package:ultimaMillaFlutter/services/shared_functions.dart';
import 'package:ultimaMillaFlutter/util/const/parametroConexion.dart';
import 'package:ultimaMillaFlutter/util/const/constants.dart';
import 'package:url_launcher/url_launcher.dart';

class TabInfoPedido extends StatefulWidget {
  final dynamic pedido;
  const TabInfoPedido({super.key, required this.pedido});

  @override
  _TabInfoPedidoState createState() => _TabInfoPedidoState();
}

class _TabInfoPedidoState extends State<TabInfoPedido> {
  Map<String, dynamic> pedido = {};
  bool openProductsModal = false;
  bool openInfoModal = false;
  bool openStockModal = false;
  List<dynamic> metaData = [];
  Map<String, dynamic>? metaInfo;
  List<String> metaKeys = [];
  List<dynamic> metaValues = [];
  String? horarios;
  Map<String, double?> vehiclePosition = {'lat': null, 'lng': null};
  Map<String, dynamic> usuario = {};
  bool inicioAtencion = false;
  List<dynamic> stock = [];
  late Timer timer;

  @override
  void initState() {
    super.initState();
    setState(() {
      pedido = jsonDecode(widget.pedido);
    });
    getData();
    getUbicacionVehiculo();
    Timer.periodic(Duration(seconds: 15), (Timer timer) {
      getUbicacionVehiculo();
    });
  }

  @override
  void dispose() {
    timer.cancel(); // Cancela el Timer para liberar recursos
    super.dispose();
  }

  Future<void> getData() async {
    try {
      var usuario = await obtenerUsuario();
      var metaData = (pedido.containsKey('meta') && pedido['meta'] is String)
          ? jsonDecode(pedido['meta'])
          : null;

      var horarios =
          (pedido.containsKey('metaPI') && pedido['metaPI'] is String)
              ? jsonDecode(pedido['metaPI'])
              : null;

      if (horarios != null) {
        horarios =
            "${horarios['horaEntregaInicio']} - ${horarios['horaEntregaFin']}";
      }

      List<String> result = [];
      Map<String, dynamic>? info;
      if (metaData != null) {
        info = metaData;
        if (usuario['idEmpresa'] == CERAMICANORTE) {
          var obj = {};
          for (var product in metaData['productos']) {
            obj[product['productoentrega']] =
                (obj[product['productoentrega']] ?? 0) + 1;
          }
          result = obj.entries
              .map((entry) => "${entry.value}x --> ${entry.key}")
              .toList();
        } else if (usuario['idEmpresa'] == MADISA) {
        } else if (usuario['idEmpresa'] == HPMEDICAL) {
          info?.remove('productos');
        } else if (usuario['idEmpresa'] == COFAR) {
        } else {
          for (var product in metaData['productos']) {
            result.add(
                "${product['cantidad']}x --> ${product['productoentrega']}");
          }
          info?.remove('productos');
        }

        setState(() {
          this.metaData = result;
          metaInfo = info;
          metaKeys = info!.keys.toList();
          metaValues = info.values.toList();
          this.horarios = horarios;
          this.usuario = usuario;
        });
      } else {
        setState(() {
          this.horarios = horarios;
          this.usuario = usuario;
        });
      }
      await getInventario();
    } catch (e) {
      print(e);
    }
  }

  Future<void> getInventario() async {
    var usuario = await obtenerUsuario();
    var response = await doFetchJSON(URL_UM, {
      'data_op': {
        'token': usuario['token'],
        'unidad': usuario['idUnidad'],
      },
      'op': 'READ-OBTENERINVENTARIOPORUNIDAD',
    });
    var stock = response['data'].map((e) {
      return {...e, 'cantidadEntregando': 0};
    }).toList();
    setState(() {
      this.stock = stock;
    });
  }

  Future<void> registrarProductosVendidos(Map<String, dynamic> obj) async {
    await doFetchJSON(URL_UM, {
      'data_op': (obj),
      'op': 'CREATE-HISTORICOENTREGAPRODUCTOS',
    });
  }

  Future<void> getUbicacionVehiculo() async {
    var data = await obtenerUsuario();
    var response = await doFetchJSON(URL_GESTION, {
      'data_op': ({
        'placa': data['idUnidad'],
        'token': data['token'],
        'checkConsumoUM': true,
      }),
      'op': 'READ-OBTENEREVENTOACTUALVEHICULO',
    });

    if (!response['error']) {
      setState(() {
        vehiclePosition = {
          'lat': response['data'][0]['LATITUD'],
          'lng': response['data'][0]['LONGITUD'],
        };
      });
    }
  }

  Future<bool> checkInternetConnection() async {
    var location = Location();
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return false;
      }
    }
    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return false;
      }
    }
    return true;
  }

  Future<void> iniciarAtencion() async {
    try {
      await verificarAtencionIniciada();
      if (inicioAtencion) {
        showAlert(context, 'La atencion ya fue iniciada anteriormente');
      } else {
        var usuario = this.usuario;
        var fechaInicio = DateTime.now().toIso8601String();

        var result = await doFetchJSON(URL_UM, {
          'data_op': ({
            'token': usuario['token'],
            'idPedido': pedido['idPedido'],
            'idDetallePedido': pedido['idDetallePedido'],
            'fechaHoraInicio': fechaInicio,
            'unidad': usuario['idUnidad'],
            'nombreChofer': usuario['nombre'],
          }),
          'op': 'CREATE-TIEMPOATENCIONCLIENTE',
        });
        if (result['error'] == false) {
          showAlert(
              context, 'Desde ahora se esta controlando el tiempo de atencion');
        }
      }
    } catch (e) {
      print(e);
    }
  }

  goToInventario() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GestionInventarioScreen(
          pedido: (widget.pedido),
        ),
      ),
    );
  }

  Future<void> verificarAtencionIniciada() async {
    var usuario = this.usuario;
    var response = await doFetchJSON(URL_UM, {
      'data_op': ({
        'token': usuario['token'],
        'idDetallePedido': pedido['idDetallePedido'],
      }),
      'op': 'READ-OBTENERESTADOACTUALTIEMPOATENCIONCLIENTE',
    });
    setState(() {
      inicioAtencion = response['data'].length > 0;
    });
  }

  void openMap() async {
    var origin = vehiclePosition;
    var destination = {
      'latitude': pedido['latPuntoInteres'],
      'longitude': pedido['lngPuntoInteres'],
    };
    var googleMapsUrl =
        'https://www.google.com/maps/dir/?api=1&origin=${origin['lat']},${origin['lng']}&destination=${destination['latitude']},${destination['longitude']}&travelmode=driving';
    if (await canLaunch(googleMapsUrl)) {
      await launch(googleMapsUrl);
    } else {
      throw 'Could not open the map.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.all(7),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      buildActionButton("Iniciar \n atencion",
                          Color(0xff046d8b), iniciarAtencion),
                      buildActionButton("Gestionar \n inventario",
                          Color(0xfffa6532), goToInventario),
                    ],
                  ),
                  SizedBox(
                    height: 7,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () {}, //viewProducts,
                        child: Row(
                          children: [
                            Image.asset(
                              'assets/images/list.png',
                              width: 25,
                              height: 25,
                            ),
                            Text(
                              'Detalle',
                              style: TextStyle(
                                // Estilo equivalente a Styles.rowRight
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 7,
                      ),
                      //metaInfo != null
                      true
                          ? GestureDetector(
                              onTap: () {}, //viewInfo,
                              child: Row(
                                children: [
                                  Image.asset(
                                    'assets/images/info.png',
                                    width: 25,
                                    height: 25,
                                  ),
                                  Text(
                                    'Info.',
                                    style: TextStyle(
                                      // Estilo equivalente a Styles.rowRight
                                      fontSize: 16,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Container(),
                    ],
                  ),
                  buildInfoSection(
                    "Nombre de Pedido",
                    [
                      Text(pedido['nombrePedido'] ?? ""),
                      Text("Grupo pedido: ${pedido['nombreGrupoPedido']}"),
                      Text("Cod. Pedido: ${pedido['codigoPedido']}"),
                    ],
                  ),
                  buildInfoSection(
                    "Destinatario",
                    [
                      Text(pedido['nombreCliente'] ?? ""),
                      Text("Punto de Interes: ${pedido['nombrePuntoInteres']}"),
                      Text("Telefono: ${pedido['telefonoPuntoInteres']}"),
                    ],
                  ),
                  buildInfoSection(
                    "Direccion Entrega",
                    [
                      Text(pedido['direccionLiteral'] ?? ""),
                      Text(
                          "Ref dir. ${pedido['referenciaDireccionPuntoInteres']}"),
                    ],
                  ),
                  SizedBox(height: 400),
                ],
              ),
            ),
            buildProductModal(),
            buildInfoModal(),
            buildStockModal(),
          ],
        ),
        bottomNavigationBar: BottomAppBar(
          color: Colors.green,
          child: GestureDetector(
            onTap: openMap,
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pin_drop, color: Colors.white),
                Text(
                  "Ver en Google Maps",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ));
  }

  Widget buildActionButton(String text, Color color, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(
          text,
          style: TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget buildInfoSection(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Card(
        elevation: 7,
        child: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              Divider(color: Colors.grey),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget buildProductModal() {
    if (!openProductsModal) return Container();
    return GestureDetector(
      onTap: () => setState(() => openProductsModal = false),
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            width: 300,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Productos",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                // Lista de productos
                Text("Producto 1"),
                Text("Producto 2"),
                Text("Producto 3"),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => setState(() => openProductsModal = false),
                  child: Text("Cerrar"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildInfoModal() {
    if (!openInfoModal) return Container();
    return GestureDetector(
      onTap: () => setState(() => openInfoModal = false),
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            width: 300,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Información Adicional",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                // Información adicional
                Text("Información 1"),
                Text("Información 2"),
                Text("Información 3"),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => setState(() => openInfoModal = false),
                  child: Text("Cerrar"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildStockModal() {
    if (!openStockModal) return Container();
    return GestureDetector(
      onTap: () => setState(() => openStockModal = false),
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            width: 300,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Gestionar Inventario",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                // Detalles de inventario
                Text("Stock 1"),
                Text("Stock 2"),
                Text("Stock 3"),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => setState(() => openStockModal = false),
                  child: Text("Cerrar"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void showAlert(BuildContext context, message) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('OK'),
        ),
      ],
    ),
  );
}
