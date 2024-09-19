// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:ultimaMillaFlutter/services/shared_functions.dart';
import 'package:ultimaMillaFlutter/util/const/parametroConexion.dart';

class NuevaVentaScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 1,
      child: Scaffold(
        appBar: AppBar(
          title: Text('NUEVO'),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          bottom: TabBar(
            tabs: [
              Tab(text: "VENTA EVENTUAL"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            NuevaVenta(),
          ],
        ),
      ),
    );
  }
}

class NuevoCliente extends StatefulWidget {
  const NuevoCliente({super.key});

  @override
  State<NuevoCliente> createState() => _NuevoClienteState();
}

class _NuevoClienteState extends State<NuevoCliente> {
  double latCliente = 0;
  double lngCliente = 0;
  bool successfulGotLocation = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    handleGotLocation();
  }

  Future<void> handleGotLocation() async {
    Location location = Location();
    bool serviceEnabled;
    PermissionStatus permissionGranted;
    LocationData locationData;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    locationData = await location.getLocation();
    setState(() {
      successfulGotLocation = true;
      latCliente = locationData.latitude!;
      lngCliente = locationData.longitude!;
    });
  }

  void sendCustomLocation() {}

  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Container(
              padding: EdgeInsets.all(25),
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: "Nombre del cliente",
                      border: UnderlineInputBorder(),
                    ),
                    maxLines: null,
                    onChanged: (comentario) {},
                    maxLength: 1024,
                  ),
                  Text(
                    'Seleccione la posicion del punto de interes',
                    textAlign: TextAlign.center,
                  ),
                  if (successfulGotLocation)
                    SizedBox(
                      height: 300,
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(latCliente, lngCliente),
                          zoom: 15,
                        ),
                        myLocationEnabled: true,
                        markers: {
                          Marker(
                            markerId: MarkerId('selected-location'),
                            position: LatLng(latCliente, lngCliente),
                          ),
                        },
                        onTap: (LatLng pos) {
                          setState(() {
                            latCliente = pos.latitude;
                            lngCliente = pos.longitude;
                          });
                        },
                      ),
                    )
                  else
                    Center(
                      child: Text("Debe activar los permisos de localizacion"),
                    ),
                ],
              ),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: (latCliente == 0 && lngCliente == 0)
              ? () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Debe seleccionar ubicacion y poner un nombre')),
                  );
                }
              : sendCustomLocation,
          child: Text('CONTINUAR'),
        ),
      ],
    );
  }
}

class NuevaVenta extends StatefulWidget {
  const NuevaVenta({super.key});

  @override
  _NuevaVentaState createState() => _NuevaVentaState();
}

class _NuevaVentaState extends State<NuevaVenta> {
  List<dynamic> ventas = [];
  List<dynamic> stock = [];
  String nota = "";

  @override
  void initState() {
    super.initState();
    getInventario();
  }

  Future<void> getVentasEfectuadas(BuildContext context) async {
    var usuario = await obtenerUsuario();
    final params =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;

    var obj = {
      'token': usuario['token'],
      'idDetallePedido': params['idDetallePedido'],
      'idPuntoInteres': params['idPuntoInteres']
    };

    var data = await doFetchJSON(URL_UM,
        {'data_op': obj, 'op': 'READ-OBTENERHISTORICOENTREGAPRODUCTOS'});

    setState(() {
      ventas = data['data'];
    });
  }

  Future<void> getInventario() async {
    try {
      var usuario = await obtenerUsuario();

      var stock = await doFetchJSON(URL_UM, {
        'data_op': {
          'token': usuario['token'],
          'unidad': usuario['idUnidad'],
        },
        'op': 'READ-OBTENERINVENTARIOPORUNIDAD'
      });

      var mappedStock = stock['data']?.map((e) {
        return {...e, 'cantidadEntregando': 0};
      }).toList();

      setState(() {
        this.stock = mappedStock;
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> registrarProductosVendidos(Map<String, dynamic> obj) async {
    var vendidos = await doFetchJSON(
        URL_UM, {'data_op': obj, 'op': 'CREATE-HISTORICOENTREGAPRODUCTOS'});
    print(vendidos);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(10),
            child: Column(
              children: [
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: stock.length,
                  itemBuilder: (context, index) {
                    var item = stock[index];
                    return Container(
                      margin: EdgeInsets.all(4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(item['nombre']),
                          Row(
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
                                    var value = int.tryParse(text) ?? 0;
                                    if (value <= item['cantidad']) {
                                      setState(() {
                                        item['cantidadEntregando'] = value;
                                      });
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content:
                                                Text("Cantidad no válida")),
                                      );
                                    }
                                  },
                                ),
                              ),
                              Text('/${item['cantidad']}'),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
                TextField(
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Nota...',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (text) {
                    setState(() {
                      nota = text;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            var usuario = await obtenerUsuario();
            for (var item in stock) {
              if (item['cantidadEntregando'] > 0) {
                var obj = {
                  'idDetallePedido': -1,
                  'idPuntoInteres': -1,
                  'idProducto': item['idProducto'],
                  'cantidad': item['cantidadEntregando'],
                  'unidad': usuario['idUnidad'], // Example unit
                  'nombreConductor': "",
                  'nota': nota,
                  'token': usuario['token'],
                };
                registrarProductosVendidos(obj);
              }
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Venta registrada correctamente")),
            );
            getInventario();
            Navigator.of(context).pop();
          },
          child: Text('CONFIRMAR VENTA'),
        ),
      ],
    );
  }
}
