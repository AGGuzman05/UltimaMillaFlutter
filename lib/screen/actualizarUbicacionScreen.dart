// ignore_for_file: prefer_const_constructors, library_private_types_in_public_api, use_build_context_synchronously, constant_identifier_names

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:ultimaMillaFlutter/screen/QRScreen.dart';
import 'package:ultimaMillaFlutter/screen/modals/DialogHelper.dart';
import 'package:ultimaMillaFlutter/screen/pendientesScreen.dart';
import 'package:ultimaMillaFlutter/services/shared_functions.dart';
import 'package:ultimaMillaFlutter/util/const/base_url.dart';
import 'package:ultimaMillaFlutter/util/const/constants.dart';

class ActualizarUbicacionScreen extends StatefulWidget {
  const ActualizarUbicacionScreen(
      {super.key, required this.pedido, required this.estado});
  final String pedido;
  final int estado;

  @override
  _ActualizarUbicacionScreenState createState() =>
      _ActualizarUbicacionScreenState();
}

class VIEWS {
  static const int MENU = 1;
  static const int AUTO = 2;
  static const int MAPA = 3;
}

class _ActualizarUbicacionScreenState extends State<ActualizarUbicacionScreen> {
  int viewInteface = VIEWS.MENU; //"MAPA"; "AUTOMATICA"
  bool successfulGotLocation = false;
  Map usuario = {};
  double latCliente = 0;
  double lngCliente = 0;

  @override
  void initState() {
    super.initState();
    handleGotLocation();
    obtenerUsuario().then((user) {
      setState(() {
        usuario = user;
      });
    });
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

  Future<void> sendCustomLocation() async {
    try {
      var pedido = jsonDecode(widget.pedido);

      var dataOp1 = {
        'token': usuario!['token'],
        'id': pedido['idDetallePedido'],
        'lat': latCliente,
        'lng': lngCliente,
      };

      var result1 = await doFetchJSON(
          URL_UM, {'data_op': dataOp1, 'op': 'UPDATE-DETALLEPEDIDOLATLNG'});

      var dataOp2 = {
        'token': usuario!['token'],
        'id': pedido['idPuntoInteres'],
        'lat': latCliente,
        'lng': lngCliente,
        'idCliente': pedido['idCliente'],
      };

      var result2 = await doFetchJSON(
          URL_UM, {'data_op': dataOp2, 'op': 'UPDATE-PUNTOINTERESLATLNG'});

      if (result1['error'] == false && result2['error'] == false) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text('Se ha actualizado la ubicacion del cliente con exito.')));
        if (widget.estado == NO_ENTREGADO_RECHAZADO) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PendientesScreen(),
            ),
          );
        } else {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => QRScreen(
                  pedido: widget.pedido,
                ),
              ));
        }
      } else {
        DialogHelper.showSimpleDialog(
            context, 'Error', 'Ocurrio un error al actualizar las coordenadas');
      }
    } catch (error) {
      print(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("ACTUALIZAR UBICACION"),
          automaticallyImplyLeading: false,
          centerTitle: true,
        ),
        body: viewInteface == VIEWS.MENU
            ? Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'ACTUALMENTE LAS COORDENADAS DEL PUNTO DE INTERES NO ESTAN REGISTRADAS. DESEA ACTUALIZARLAS POR LAS COORDENADAS DE SU UBICACION ACTUAL?',
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            viewInteface = VIEWS.AUTO;
                          });
                        },
                        child: Text('USAR MI UBICACION ACTUAL'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            viewInteface = VIEWS.MAPA;
                          });
                        },
                        child: Text('SELECCIONAR MANUALMENTE'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => QRScreen(
                                  pedido: widget.pedido,
                                ),
                              ));
                        },
                        child: Text('EN OTRO MOMENTO'),
                      ),
                    ],
                  ),
                ),
              )
            : viewInteface == VIEWS.AUTO
                ? Center(
                    child: Container(
                      margin: EdgeInsets.all(25),
                      child: Column(
                        children: [
                          Text(
                            successfulGotLocation
                                ? 'Ubicacion del dispositivo obtenida'
                                : 'Es necesario aceptar el permiso de localizacion',
                            textAlign: TextAlign.center,
                          ),
                          ElevatedButton(
                            onPressed: successfulGotLocation
                                ? sendCustomLocation
                                : null,
                            child: Text('CONTINUAR'),
                          ),
                        ],
                      ),
                    ),
                  )
                : viewInteface == VIEWS.MAPA
                    ? Center(
                        child: Container(
                          padding: EdgeInsets.all(25),
                          child: Column(
                            children: [
                              Text(
                                'Seleccione la posicion del punto de interes',
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(
                                height: 400,
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
                              ),
                              ElevatedButton(
                                onPressed: (latCliente == 0 && lngCliente == 0)
                                    ? null
                                    : sendCustomLocation,
                                child: Text('CONTINUAR'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SizedBox());
  }
}
