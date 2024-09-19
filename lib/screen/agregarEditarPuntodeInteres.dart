// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, avoid_print

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ultimaMillaFlutter/screen/gestionarClientesScreen.dart';
import 'package:ultimaMillaFlutter/screen/modals/ConfirmDialog.dart';
import 'package:ultimaMillaFlutter/services/shared_functions.dart';
import 'package:ultimaMillaFlutter/util/const/parametroConexion.dart';
import 'package:ultimaMillaFlutter/util/const/wrappedFields.dart';

class AgregarEditarPuntoInteres extends StatefulWidget {
  const AgregarEditarPuntoInteres({
    this.punto,
    this.idCliente,
    required this.isNewPoint,
    super.key,
  });
  final dynamic punto;
  final dynamic idCliente;
  final bool isNewPoint;

  @override
  State<AgregarEditarPuntoInteres> createState() =>
      _AgregarEditarPuntoInteresState();
}

class _AgregarEditarPuntoInteresState extends State<AgregarEditarPuntoInteres> {
  late GoogleMapController controller;
  bool enableButtonPress = true;
  bool enableEdition = false;
  double latitude = 0;
  double longitude = 0;

  TextEditingController controllerNombre = TextEditingController();
  TextEditingController controllerCodigo = TextEditingController();
  TextEditingController controllerTelefono = TextEditingController();
  TextEditingController controllerEmail = TextEditingController();
  TextEditingController controllerDireccion = TextEditingController();
  TextEditingController controllerNota = TextEditingController();
  TextEditingController controllerNit = TextEditingController();
  TextEditingController controllerLatitud = TextEditingController();
  TextEditingController controllerLongitud = TextEditingController();

  List wrappedFieldsList = [];

  @override
  void initState() {
    super.initState();
    print(widget.punto);
    if (widget.isNewPoint) {
      setState(() {
        enableEdition = true;
      });
    }
    fillInputValues();
    setWrappedItems();
  }

  @override
  void dispose() {
    controllerNombre.dispose();
    controllerCodigo.dispose();
    controllerTelefono.dispose();
    controllerEmail.dispose();
    controllerDireccion.dispose();
    controllerNota.dispose();
    controllerLatitud.dispose();
    controllerLongitud.dispose();
    super.dispose();
  }

  void fillInputValues() {
    if (!widget.isNewPoint) {
      setState(() {
        controllerNombre.text = widget.punto['nombrePuntoInteres'] ?? "";
        controllerCodigo.text = widget.punto['codigoPuntoInteres'] ?? "";
        controllerTelefono.text = widget.punto['telefonoPuntoInteres'] ?? "";
        controllerEmail.text = widget.punto['emailPuntoInteres'] ?? "";
        controllerDireccion.text =
            widget.punto['referenciaDireccionPuntoInteres'] ?? "";
        controllerNota.text = widget.punto['notaPuntoInteres'] ?? "";
        controllerLatitud.text = widget.punto['lat'] ?? "";
        controllerLongitud.text = widget.punto['lng'] ?? "";
        latitude = double.tryParse(widget.punto['lat'])!;
        longitude = double.tryParse(widget.punto['lng'])!;
      });
    }
  }

  void setWrappedItems() {
    setState(() {
      wrappedFieldsList = wrappedFields(
          "POI",
          controllerNombre,
          controllerCodigo,
          controllerTelefono,
          controllerEmail,
          controllerDireccion,
          controllerNota,
          controllerNit,
          controllerLatitud,
          controllerLongitud);
    });
  }

  bool validarCamposObligatorios() {
    return controllerCodigo.text.isNotEmpty &&
        controllerNombre.text.isNotEmpty &&
        latitude != 0 &&
        longitude != 0;
  }

  Future<void> guardarEditarPuntoInteres() async {
    try {
      if (validarCamposObligatorios()) {
        var result = await doFetchJSONv2(
            URL_UM_V2 + ENDPOINTS.COMPROBAREXISTECODIGOPUNTOINTERES,
            {"codigo": controllerCodigo.text});
        bool existe = result?['body']?['cantidad'] > 1;
        if (!existe) {
          var user = await obtenerUsuario();

          if (widget.isNewPoint) {
            var nuevo = await doFetchJSONv2(
                URL_UM_V2 + ENDPOINTS.CREARNUEVOPUNTOINTERES, {
              "idCliente": widget.idCliente,
              "nombre": controllerNombre.text,
              "codigo": controllerCodigo.text,
              "telefono": controllerTelefono.text,
              "email": controllerEmail.text,
              "referenciaDireccion": controllerDireccion.text,
              "nota": controllerNota.text,
              "lat": controllerLatitud.text,
              "lng": controllerLongitud.text,
              "coordenadasPoligono": null,
              "idGeocerca": 0,
              "meta": null,
              "idVendedor": 0,
              "idRegion": 0,
              "idZona": 0,
              "createdFrom": 102,
            });
            if (nuevo['code'] == "SUCCESS") {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text("El PUNTO DE INTERES se creo exitosamente.")));
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => GestionarClientes()),
              );
            }
          } else {
            var edit = await doFetchJSON(URL_UM, {
              'data_op': {
                "token": user['token'],
                "nombre": controllerNombre.text ?? "",
                "telefono": controllerTelefono.text ?? "",
                "email": controllerEmail.text ?? "",
                "referenciaDireccion": controllerDireccion.text ?? "",
                "nota": controllerNota.text ?? "",
                "lat": controllerLatitud.text,
                "lng": controllerLongitud.text,
                "codigo": controllerCodigo.text ?? "",
                "id": widget.punto['idPuntoInteres']
              },
              'op': 'UPDATE-PUNTOINTERESINDIVIDUALDESDEMOVIL'
            });
            if (edit['error'] == false) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text("El PUNTO DE INTERES se EDITO exitosamente.")));
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => GestionarClientes()),
              );
            }
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("El CODIGO ya existe. Pruebe con otro codigo.")));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                "Asegurese de llenar los campos CODIGO y NOMBRE. Tambien debe poner el marcador en un punto valido.")));
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> showModalCancelar() async {
    setState(() {
      enableEdition = false;
    });
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return ConfirmDialog(
              title: "Alerta",
              content:
                  "Confirma que desea DESCARTAR la CREACION/EDICION del punto de interes y volver atras?",
              confirmButtonText: "Si",
              cancelButtonText: "No",
              onConfirm: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              onCancel: () {
                Navigator.of(context).pop();
              });
        });
  }

  Future<void> showModalConfirmarGuardado() async {
    setState(() {
      enableEdition = false;
    });
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return ConfirmDialog(
              title: "Alerta",
              content:
                  "Confirma que desea CREAR el nuevo punto de interes? Verifique toda la informacion que ha ingresado",
              confirmButtonText: "Si",
              cancelButtonText: "No",
              onConfirm: () {
                Navigator.of(context).pop();
                guardarEditarPuntoInteres();
              },
              onCancel: () {
                Navigator.of(context).pop();
              });
        });
  }

  Future<void> showModalConfirmarEdicion() async {
    setState(() {
      enableEdition = false;
    });
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return ConfirmDialog(
              title: "Alerta",
              content:
                  "Confirma que desea EDITAR el punto de interes? Verifique toda la informacion que ha ingresado",
              confirmButtonText: "Si",
              cancelButtonText: "No",
              onConfirm: () {
                Navigator.of(context).pop();
                guardarEditarPuntoInteres();
              },
              onCancel: () {
                Navigator.of(context).pop();
              });
        });
  }

  void _onMapCreated(GoogleMapController _controller) {
    controller = _controller;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isNewPoint
              ? "NUEVO PUNTO DE INTERES"
              : "EDITAR PUNTO DE INTERES"),
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (!widget.isNewPoint)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "CLIENTE: ${widget.punto?['nombreCliente'].toString().toUpperCase()}" ??
                                      "",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18),
                                ),
                                Text(
                                  "PUNTO:${widget.punto?['nombrePuntoInteres'].toString().toUpperCase()}" ??
                                      "",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18),
                                ),
                              ],
                            ),
                            FloatingActionButton(
                              onPressed: enableButtonPress
                                  ? () {
                                      setState(() {
                                        enableEdition = !enableEdition;
                                        enableButtonPress = false;
                                      });

                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                              content: Text(enableEdition
                                                  ? "Modo edicion ACTIVADO"
                                                  : "Modo edicion DESACTIVAOD"),
                                              duration: Duration(seconds: 1)));
                                      Timer(Duration(seconds: 3), () {
                                        setState(() {
                                          enableButtonPress = true;
                                        });
                                      });
                                    }
                                  : null,
                              child: Icon(Icons.edit),
                            )
                          ],
                        ),
                      ),
                    Wrap(children: [
                      ...wrappedFieldsList
                          .map((item) => Container(
                                padding: EdgeInsets.all(8),
                                width: MediaQuery.of(context).size.width *
                                    item['large'],
                                child: GestureDetector(
                                  onTap: () => {
                                    if (enableEdition == false &&
                                        item['editable'] == true)
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                              content: Text(
                                                  "Primero debe habilitar el modo EDICION.")))
                                  },
                                  child: TextField(
                                    readOnly: !enableEdition ||
                                        item['editable'] == false,
                                    keyboardType: item['large'] == 1
                                        ? TextInputType.multiline
                                        : TextInputType.text,
                                    decoration: !enableEdition ||
                                            item['editable'] == false
                                        ? InputDecoration(
                                            labelText: item['label'],
                                            hintText: item['label'],
                                            border: OutlineInputBorder(),
                                            filled: true,
                                            fillColor: Colors.grey[
                                                200], // Cambia el color de fondo
                                            enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: Colors.grey,
                                                width: 1.0,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: Colors.blue,
                                                width: 2.0,
                                              ),
                                            ),
                                          )
                                        : InputDecoration(
                                            labelText: item['label'],
                                            hintText: item['label'],
                                          ),
                                    controller: item['controller'],
                                    onChanged: (value) {
                                      setState(() {
                                        item['value'] = value;
                                      });
                                    },
                                  ),
                                ),
                              ))
                          .toList(),
                      if (latitude != 0 && longitude != 0)
                        Container(
                          padding: EdgeInsets.only(top: 20),
                          child: InkWell(
                              onTap: () {
                                Clipboard.setData(ClipboardData(
                                    text:
                                        "${controllerLatitud.text}, ${controllerLongitud.text}"));
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text(
                                        "Se copio las coordenadas al portapapeles")));
                              },
                              child: Icon(
                                Icons.paste,
                                color: Colors.grey.shade800,
                                size: 28,
                              )),
                        )
                    ]),
                    SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: 400,
                      child: GoogleMap(
                        gestureRecognizers: <Factory<
                            OneSequenceGestureRecognizer>>{
                          Factory<OneSequenceGestureRecognizer>(
                            () => EagerGestureRecognizer(),
                          ),
                        },
                        onMapCreated: _onMapCreated,
                        onTap: (LatLng value) {
                          if (enableEdition) {
                            setState(() {
                              latitude = value.latitude;
                              longitude = value.longitude;
                              controllerLatitud.text =
                                  value.latitude.toString();
                              controllerLongitud.text =
                                  value.longitude.toString();
                            });
                          }
                          //else {
                          //  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          //      content: Text(
                          //          "Primero debe habilitar el modo de edicion")));
                          //}
                        },
                        initialCameraPosition: CameraPosition(
                          target: LatLng(latitude, longitude),
                          zoom: 12,
                        ),
                        myLocationButtonEnabled: true,
                        myLocationEnabled: true,
                        zoomControlsEnabled: true,
                        scrollGesturesEnabled: true,
                        markers: {
                          Marker(
                            markerId: MarkerId('selected-location'),
                            position: LatLng(latitude, longitude),
                            draggable: enableEdition,
                          ),
                        },
                      ),
                    )
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                      onPressed: () async {
                        await showModalCancelar().then((value) => {
                              Timer(Duration(seconds: 2), () {
                                setState(() {
                                  enableEdition = true;
                                });
                              })
                            });
                      },
                      child: Text("Cancelar")),
                  if (widget.isNewPoint)
                    ElevatedButton(
                        onPressed: () async {
                          await showModalConfirmarGuardado().then((value) => {
                                Timer(Duration(seconds: 2), () {
                                  setState(() {
                                    enableEdition = true;
                                  });
                                })
                              });
                        },
                        child: Text("Guardar"))
                  else
                    ElevatedButton(
                        onPressed: () async {
                          await showModalConfirmarEdicion().then((value) => {
                                Timer(Duration(seconds: 2), () {
                                  setState(() {
                                    enableEdition = true;
                                  });
                                })
                              });
                        },
                        child: Text("Editar"))
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
