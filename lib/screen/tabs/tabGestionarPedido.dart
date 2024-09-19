// ignore_for_file: prefer_const_constructors, avoid_print, prefer_const_literals_to_create_immutables, sort_child_properties_last, library_private_types_in_public_api

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:ultimaMillaFlutter/screen/entregaParcialScreen.dart';
import 'package:ultimaMillaFlutter/screen/entregaTotalScreen.dart';
import 'package:ultimaMillaFlutter/screen/noEntregadoScreen.dart';
import 'package:ultimaMillaFlutter/services/shared_functions.dart';
import 'package:ultimaMillaFlutter/util/const/parametroConexion.dart';
import 'package:ultimaMillaFlutter/util/const/constants.dart';

class TabGestionar extends StatefulWidget {
  final dynamic pedido;
  final String date;

  const TabGestionar({super.key, required this.pedido, required this.date});

  @override
  _TabGestionarState createState() => _TabGestionarState();
}

class _TabGestionarState extends State<TabGestionar> {
  int idEstadoRuta = -1;
  int idSubEstadoRuta = -1;
  Color colorEstadoRuta = Colors.lightBlueAccent;
  Color colorSubEstadoRuta = Colors.blue;
  bool modalEstadoRuta = false;
  bool modalSubEstadoRuta = false;
  String estadoRuta = "En Ruta";
  String subEstadoRuta = "SELECCIONAR SUB ESTADO";
  String labelFormulario = "Formulario no disponible";
  bool mostrarComentario = false;
  bool mostrarSeleccion = false;
  int caracteres = 0;
  String comentarioText = "";
  List estadoPrincipal = [
    {'value': EN_RUTA, 'label': 'EN RUTA'},
    {'value': ENTREGA_TOTAL, 'label': 'ENTREGA TOTAL'},
    {'value': ENTREGA_PARCIAL, 'label': 'ENTREGA PARCIAL'},
    {'value': NO_ENTREGADO_RECHAZADO, 'label': 'NO ENTREGADO'},
    {'value': EN_PAUSA, 'label': 'EN PAUSA'}
  ];
  List subEstadosEntregado = [
    {'value': SubEntregado.ENTREGA_EXITOSA, 'label': 'ENTREGA EXITOSA'}
  ];
  List subEstadosNoEntregado = [
    {'value': SubNoEntregado.TIENDA_CERRADA, 'label': 'TIENDA CERRADA'},
    {'value': SubNoEntregado.SIN_EFECTIVO, 'label': 'SIN EFECTIVO'},
    {'value': SubNoEntregado.NO_HIZO_PEDIDO, 'label': 'NO HIZO PEDIDO'},
    {'value': SubNoEntregado.PRODUCTO_FALTANTE, 'label': 'PRODUCTO FALTANTE'},
    {'value': SubNoEntregado.FALTO_TIEMPO, 'label': 'FALTO TIEMPO'},
    {'value': SubNoEntregado.ENCARGADO_AUSENTE, 'label': 'ENCARGADO AUSENTE'},
    {'value': SubNoEntregado.PRODUCTO_DANIADO, 'label': 'PRODUCTO DAÑADO'},
    {
      'value': SubNoEntregado.DIRECCION_NO_UBICADA,
      'label': 'DIRECCION NO UBICADA'
    },
    {'value': SubNoEntregado.OTRO, 'label': 'OTRO'}
  ];
  List subEstadosEntregaParcial = [
    {'value': SubEntregaParcial.FALTA_PRODUCTO, 'label': 'FALTA PRODUCTO'},
    {'value': SubEntregaParcial.ERROR_PEDIDO, 'label': 'ERROR DE PEDIDO'},
    {'value': SubEntregaParcial.PRODUCTO_DANIADO, 'label': 'PRODUCTO DAÑADO'},
    {'value': SubEntregaParcial.FALTA_EFECTIVO, 'label': 'FALTA EFECTIVO'},
    {
      'value': SubEntregaParcial.PRODUCTO_FALTANTE,
      'label': 'PRODUCTO FALTANTE'
    },
    {'value': SubEntregaParcial.QUIEBRE_STOCK, 'label': 'QUIEBRE STOCK'},
    {'value': SubEntregaParcial.OTRO, 'label': 'OTRO'}
  ];
  List subEstadosEnPausa = [
    {'value': SubEnPausa.EN_PAUSA, 'label': 'EN PAUSA'}
  ];
  List subEstadoAMostrar = [];
  bool showModalItem = false;
  bool requerido = false;
  Map<String, dynamic> item = {
    'value': '',
    'label': '',
    'quantitytodeliver': '',
    'quantitydeliver': ''
  };
  Map<String, dynamic> puntoEntrega = {};
  double latActual = 0;
  double lngActual = 0;
  double? distance = 0;
  int tiempoDescarga = 0;
  bool showConfirmarEnPausa = false;
  Timer? interval;

  @override
  void initState() {
    super.initState();
    getEstadoPedido();
    mostrarSeleccionDeEstados();
    getUbicacionVehiculo();
    interval = Timer.periodic(Duration(seconds: 10), (timer) async {
      await getUbicacionVehiculo();
      /*
      try {
        distance = computeDistance([
        //  widget.pedido['latPuntoInteres'],
        //  widget.pedido['lngPuntoInteres']
        //], [
        //  latActual,
        //  lngActual
        //]);
      } catch (error) {
        print(error);
      }
      */
      if (distance! < 0.03) {
        tiempoDescarga += 10;
      }
      setState(() {
        distance = distance;
        tiempoDescarga = tiempoDescarga;
      });
    });
  }

  @override
  void dispose() {
    interval?.cancel();
    super.dispose();
  }

  Future<void> mostrarSeleccionDeEstados() async {
    try {
      List rutas = await obtenerRutas();
      var coincidencia = rutas.firstWhere(
          (obj) =>
              obj['idDetalleAsignacionPedido'] ==
              jsonDecode(widget.pedido)['idDetalleAsignacionPedido'],
          orElse: () => null);
      if (coincidencia != null) {
        if (coincidencia['idConceptoEstadoPedido'] == EN_RUTA) {
          setState(() {
            mostrarSeleccion = true;
            getEstadoRutaSeleccionada({'value': EN_RUTA, 'label': 'EN RUTA'});
          });
        } else if (coincidencia['idConceptoEstadoPedido'] == EN_PAUSA) {
          setState(() {
            mostrarSeleccion = true;
            getEstadoRutaSeleccionada({'value': EN_PAUSA, 'label': 'EN PAUSA'});
          });
        } else {
          setState(() {
            mostrarSeleccion = false;
          });
        }
      }
    } catch (e) {
      print(e);
    }
  }

  Future<List<dynamic>> obtenerRutas() async {
    try {
      var usuario = await obtenerUsuario();
      var dataOp = {
        'token': usuario['token'],
      };
      var data = await doFetchJSON(URL_UM, {
        'data_op': dataOp,
        'op': 'READ-OBTENERASIGNACIONPEDIDOSULTIMAMILLA',
      });
      if (data['error'] == false) {
        return data['data'];
      } else {
        return [];
      }
    } catch (err) {
      print('obtenerRutas err');
      print(err);
      return [];
    }
  }

  void openModalEstado() {
    setState(() {
      modalEstadoRuta = true;
    });
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'SELECCIONAR ESTADO',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Divider(color: Colors.blue),
                  SingleChildScrollView(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: estadoPrincipal.length,
                      itemBuilder: (context, index) {
                        final item = estadoPrincipal[index];
                        return ListTile(
                          title: Text(item['label']!),
                          onTap: () => {
                            getEstadoRutaSeleccionada(item),
                            Navigator.pop(context)
                          },
                        );
                      },
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('CERRAR'),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      setState(() {
        modalEstadoRuta = false;
      });
    });
  }

  void openModalSubEstado() {
    setState(() {
      modalSubEstadoRuta = true;
    });
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'SELECCIONAR ESTADO',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Divider(color: Colors.blue),
                  SingleChildScrollView(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: subEstadoAMostrar.length,
                      itemBuilder: (context, index) {
                        final item = subEstadoAMostrar[index];
                        return ListTile(
                            title: Text(item['label']!),
                            onTap: () => {
                                  subEstadoRutaSeleccionada(item),
                                  Navigator.pop(context)
                                });
                      },
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('CERRAR'),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      setState(() {
        modalSubEstadoRuta = false;
      });
    });
  }

  void closeModalRuta() {
    setState(() {
      modalEstadoRuta = false;
    });
  }

  Future<void> getEstadoRutaSeleccionada(Map<String, dynamic> value) async {
    int idEstadoRuta = value['value'];
    String estadoRuta = value['label'] != "PENTIENTE ENTREGA"
        ? value['label']
        : "SELECCIONAR_ESTADO";
    Color colorEstadoRuta = Colors.lightBlueAccent;
    Color colorSubEstadoRuta = Colors.blue;
    String labelFormulario = "Formulario no disponible";
    bool mostrarComentario = false;
    List subEstadoAMostrar = [];
    bool requerido = false;
    String subEstadoRuta = "SELECCIONAR_SUB_ESTADO";
    int idSubEstadoRuta = -1;

    if (idEstadoRuta == PENDIENTE_ENTREGA) {
      colorEstadoRuta = Colors.lightBlueAccent;
      colorSubEstadoRuta = Colors.blue;
      labelFormulario = "Formulario no disponible";
    } else if (idEstadoRuta == ENTREGA_TOTAL) {
      colorEstadoRuta = Colors.lightGreen;
      colorSubEstadoRuta = Colors.green;
      labelFormulario = "Formulario disponible";
      mostrarComentario = true;
      subEstadoAMostrar = subEstadosEntregado;
      subEstadoRuta = "ENTREGA EXITOSA";
    } else if (idEstadoRuta == NO_ENTREGADO_RECHAZADO) {
      colorEstadoRuta = Colors.redAccent;
      colorSubEstadoRuta = Colors.red;
      labelFormulario = "Formulario disponible";
      mostrarComentario = true;
      subEstadoAMostrar = subEstadosNoEntregado;
      requerido = true;
    } else if (idEstadoRuta == ENTREGA_PARCIAL) {
      colorEstadoRuta = Colors.orangeAccent;
      colorSubEstadoRuta = Colors.orange;
      labelFormulario = "Formulario disponible";
      mostrarComentario = true;
      subEstadoAMostrar = subEstadosEntregaParcial;
      requerido = true;
    } else if (idEstadoRuta == EN_PAUSA) {
      colorEstadoRuta = Colors.purpleAccent;
      colorSubEstadoRuta = Colors.purple;
      labelFormulario = "";
      mostrarComentario = true;
      subEstadoAMostrar = subEstadosEnPausa;
    }

    setState(() {
      this.idEstadoRuta = idEstadoRuta;
      this.estadoRuta = estadoRuta;
      this.modalEstadoRuta = false;
      this.colorEstadoRuta = colorEstadoRuta;
      this.colorSubEstadoRuta = colorSubEstadoRuta;
      this.labelFormulario = labelFormulario;
      this.mostrarComentario = mostrarComentario;
      this.subEstadoAMostrar = subEstadoAMostrar;
      this.requerido = requerido;
      this.subEstadoRuta = subEstadoRuta;
      this.idSubEstadoRuta = idSubEstadoRuta;
    });
  }

  void closeModalSubEstadoRuta() {
    setState(() {
      modalSubEstadoRuta = false;
    });
  }

  void subEstadoRutaSeleccionada(Map<String, dynamic> value) {
    int idSubEstadoRuta = value['value'];
    String subEstadoRuta = value['label'];
    setState(() {
      this.idSubEstadoRuta = idSubEstadoRuta;
      this.subEstadoRuta = subEstadoRuta;
      this.modalSubEstadoRuta = false;
    });
  }

  Future<void> marcarComoEnRuta() async {
    try {
      var usuario = await obtenerUsuario();
      var dataOp = jsonDecode(widget.pedido);
      dataOp['token'] = usuario['token'];
      dataOp['idEstadoAnterior'] = PENDIENTE_ENTREGA;
      dataOp['idEstadoActual'] = EN_RUTA;

      //var correos = jsonDecode(dataOp['meta'])['correosNotificacion'];
      var fechaInicio = DateTime.now()
          .toIso8601String()
          .replaceFirst("T", " ")
          .substring(0, 19);

      var cambioEstado = await doFetchJSON(URL_UM, {
        'data_op': dataOp,
        'op': 'UPDATE-ACTIVIDADULTIMAMILLA',
      });

      await doFetchJSON(URL_UM, {
        'data_op': {
          'token': usuario['token'],
          'idPedido': jsonDecode(widget.pedido)['idPedido'],
          'idDetallePedido': jsonDecode(widget.pedido)['idDetallePedido'],
          'fechaHoraInicio': fechaInicio,
          'fechaHoraFin': null,
          'placa': usuario['idUnidad']
        },
        'op': 'CREATE-TIEMPOENTREGAMOVIL'
      });

      //await doFetchJSON(BASE_URL, {
      //  'data_op': {
      //    'email': correos,
      //    'codigoPedido': dataOp['codigoPedido'],
      //    'estadoPedido': 'EN RUTA',
      //    'nombreCliente': dataOp['nombrePuntoInteres']
      //  },
      //  'op': 'ENVIAR-EMAILSTATUS'
      //});
      if (cambioEstado['error'] == false) {
        mostrarSeleccionDeEstados();
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Error'),
            content: Text('Ocurrió un error'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (err, stackTrace) {
      print("marcarComoEnRuta err");
      print(err);
      print(stackTrace);
    }
  }

  void updateQuantityDeliver(Map<String, dynamic> value) {
    setState(() {
      item = value;
      showModalItem = true;
    });
  }

  void closeModalItem() {
    setState(() {
      showModalItem = false;
    });
  }

  void addQuantityToItem(Map<String, dynamic> value) {
    setState(() {
      if (item['quantitydeliver'] < item['quantitytodeliver']) {
        item['quantitydeliver']++;
      }
    });
  }

  void restQuantityToItem(Map<String, dynamic> value) {
    setState(() {
      if (item['quantitydeliver'] > 0) {
        item['quantitydeliver']--;
      }
    });
  }

  void onChangeComentario(String value) {
    setState(() {
      comentarioText = value;
      caracteres = value.length;
    });
  }

  void getEstadoPedido() {
    var obj = {
      "value": jsonDecode(widget.pedido)['idConceptoEstadoPedido'],
      "label": jsonDecode(widget.pedido)['estadoPedido'],
    };
    getEstadoRutaSeleccionada(obj);
  }

  Future<void> getUbicacionVehiculo() async {
    var usuario = await obtenerUsuario();
    var dataOp = {
      'placa': usuario['idUnidad'],
      'token': usuario['token'],
      'checkConsumoUM': true,
    };

    try {
      var evento = await doFetchJSON(URL_UM, {
        'data_op': dataOp,
        'op': 'READ-OBTENEREVENTOACTUALVEHICULO',
      });

      if (evento['error'] == false) {
        setState(() {
          latActual = evento['data'][0]['LATITUD'];
          lngActual = evento['data'][0]['LONGITUD'];
        });
      }
    } catch (error) {
      print(error);
    }
  }

  void navigateToCompletarFormulario() async {
    var pedido = jsonDecode(widget.pedido);
    if (idEstadoRuta == ENTREGA_TOTAL) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EntregaTotalScreen(
            pedido: pedido,
            comentario: comentarioText,
            idSubestado: SubEntregado.ENTREGA_EXITOSA,
            tiempoDescarga: tiempoDescarga,
            date: widget.date,
          ),
        ),
      );
    } else if (idEstadoRuta == EN_PAUSA) {
      if (pedido['idConceptoEstadoPedido'] == EN_PAUSA) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              content: Text("El pedido ya esta marcado como EN PAUSA"),
              actions: [
                TextButton(
                  child: Text("OK"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      } else {
        setState(() {
          showConfirmarEnPausa = true;
        });
      }
    } else if (idEstadoRuta == NO_ENTREGADO_RECHAZADO) {
      if (idSubEstadoRuta != -1) {
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NoEntregadoScreen(
                pedido: pedido,
                comentario: comentarioText,
                idSubestado: idSubEstadoRuta,
                date: widget.date,
              ),
            ));
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              content: Text("Debe seleccionar Sub Estado"),
              actions: [
                TextButton(
                  child: Text("OK"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    } else if (idEstadoRuta == ENTREGA_PARCIAL) {
      if (idSubEstadoRuta != -1) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EntregaParcialScreen(
              pedido: pedido,
              comentario: comentarioText,
              idSubestado: idSubEstadoRuta,
              tiempoDescarga: tiempoDescarga,
              date: widget.date,
            ),
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              content: Text("Debe seleccionar Sub Estado"),
              actions: [
                TextButton(
                  child: Text("OK"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Text(
                'Debe seleccionar "ENTREGA TOTAL", "ENTREGA PARCIAL", "EN PAUSA" o "NO ENTREGADO" para continuar'),
            actions: [
              TextButton(
                child: Text("OK"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

/*
double computeDistance(List<double> prevCoords, List<double> coords) {
    final double prevLatInRad = toRad(prevCoords[0]);
    final double prevLongInRad = toRad(prevCoords[1]);
    final double latInRad = toRad(coords[0]);
    final double longInRad = toRad(coords[1]);

    return 6377.830272 * math.acos(
      math.sin(prevLatInRad) * math.sin(latInRad) +
      math.cos(prevLatInRad) * math.cos(latInRad) *
      math.cos(longInRad - prevLongInRad)
    );
  }
  */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Destinario",
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            Container(
                              constraints: BoxConstraints(
                                maxWidth: 150,
                              ),
                              child: Text(
                                  jsonDecode(widget.pedido)[
                                          'nombrePuntoInteres'] ??
                                      "",
                                  style: TextStyle(fontSize: 16)),
                            ),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: () {
                            if (idEstadoRuta == PENDIENTE_ENTREGA) {
                              marcarComoEnRuta();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          "Ruta ya iniciada anteriormente")));
                            }
                          },
                          child: Row(
                            children: [
                              Icon(Icons.route),
                              Text("Iniciar Ruta"),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  mostrarSeleccion
                      ? Column(
                          children: [
                            GestureDetector(
                              onTap: openModalEstado,
                              child: Container(
                                color: colorEstadoRuta,
                                margin: EdgeInsets.symmetric(horizontal: 20),
                                padding: EdgeInsets.symmetric(vertical: 15),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                        margin: EdgeInsets.only(left: 12),
                                        child: Text(estadoRuta,
                                            style: TextStyle(fontSize: 16))),
                                    Icon(Icons.arrow_drop_down),
                                  ],
                                ),
                              ),
                            ),
                            if (idEstadoRuta > 1 && requerido)
                              GestureDetector(
                                onTap: openModalSubEstado,
                                child: Container(
                                  color: colorSubEstadoRuta,
                                  margin: EdgeInsets.symmetric(horizontal: 20),
                                  padding: EdgeInsets.symmetric(vertical: 15),
                                  child: Container(
                                    margin: EdgeInsets.only(left: 12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(subEstadoRuta,
                                                style: TextStyle(fontSize: 16)),
                                            Icon(Icons.arrow_drop_down),
                                          ],
                                        ),
                                        SizedBox(height: 10),
                                        Text("Requerido",
                                            style: TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            Container(
                              margin: EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(labelFormulario,
                                          style: TextStyle(fontSize: 14)),
                                      SizedBox(),
                                    ],
                                  ),
                                  SizedBox(height: 10),
                                  if (mostrarComentario)
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        TextField(
                                          decoration: InputDecoration(
                                            hintText: "Comentario",
                                            border: UnderlineInputBorder(),
                                          ),
                                          maxLines: null,
                                          onChanged: (comentario) {
                                            setState(() {
                                              comentarioText = comentario;
                                              caracteres = comentario.length;
                                            });
                                          },
                                          maxLength: 1024,
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Container(),
                ],
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: ElevatedButton(
              onPressed: navigateToCompletarFormulario,
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  SizedBox(
                    width: 5,
                  ),
                  Text(
                    "CONFIRMAR GESTION",
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
