// ignore_for_file: prefer_const_constructors, library_private_types_in_public_api, use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:ultimaMillaFlutter/screen/actualizarUbicacionScreen.dart';
import 'package:ultimaMillaFlutter/screen/pendientesScreen.dart';
import 'package:ultimaMillaFlutter/services/shared_functions.dart';
import 'package:ultimaMillaFlutter/util/const/parametroConexion.dart';
import 'package:ultimaMillaFlutter/util/const/constants.dart';

class NoEntregadoScreen extends StatefulWidget {
  const NoEntregadoScreen(
      {super.key,
      required this.pedido,
      required this.date,
      required this.comentario,
      required this.idSubestado});
  final dynamic pedido;
  final String date;
  final String comentario;
  final int idSubestado;

  @override
  _NoEntregadoScreenState createState() => _NoEntregadoScreenState();
}

class _NoEntregadoScreenState extends State<NoEntregadoScreen> {
  CameraController? controller;
  late Future<void> _initializeControllerFuture;
  bool showCamera = false;
  bool pictureTaken = false;
  String base64 = "";
  bool showProgressUploading = false;
  String flashMode = 'off';
  List<dynamic> entregaUnica = [];
  List<dynamic> entregas = [];
  Map usuario = {};

  @override
  void initState() {
    super.initState();
    obtenerUsuario().then((user) {
      setState(() {
        usuario = user;
      });
    });
    if (!kIsWeb) _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      final firstCamera = cameras.first;
      controller = CameraController(
        firstCamera,
        ResolutionPreset.medium,
      );
      _initializeControllerFuture = controller!.initialize();
      if (!mounted) return;
      setState(() {
        showCamera = true;
      });
    }
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;
      final image = await controller!.takePicture();
      base64 = base64Encode(await image.readAsBytes());
      setState(() {
        pictureTaken = true;
        showCamera = false;
      });
    } catch (e) {
      print(e);
    }
  }

  void mostrarAlertaFormularios() {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("La foto es obligatoria")));
  }

  showModalFinalizar() {
    var nombrePuntoInteres = widget.pedido["nombrePuntoInteres"];
    var fechaSelected = widget.date;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: EdgeInsets.all(0),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: Icon(Icons.close, color: Colors.black),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      ),
                      /*
                      entregas.length > 1
                          ? Container(
                              padding: EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                'Hay ${entregas.length} entregas correspondientes a "$nombrePuntoInteres" para la fecha $fechaSelected',
                                style: TextStyle(
                                  fontSize: 12,
                                ),
                              ),
                            )
                          : Container(),
                      SizedBox(height: 10),
                      */
                      Text(
                        'Marcar como NO ENTREGADO?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 20),
                      /*
                      entregas.length > 1
                          ? GestureDetector(
                              onTap: () => {
                                if (base64.isNotEmpty)
                                  {
                                    Navigator.of(context).pop(),
                                    _finalizar(context)
                                  }
                                else
                                  mostrarAlertaFormularios()
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                alignment: Alignment.center,
                                margin: EdgeInsets.symmetric(vertical: 15),
                                child: Text(
                                  'Todos los pedidos de este cliente',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            )
                          : Container(),
                          */
                      GestureDetector(
                        onTap: () => {
                          if (base64.isNotEmpty)
                            {Navigator.of(context).pop(), _finalizar()}
                          else
                            mostrarAlertaFormularios()
                        },
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.center,
                          margin: EdgeInsets.symmetric(vertical: 15),
                          child: Text(
                            'Solo este pedido',
                            //'Solo el pedido ${entregaUnica[0]['codigoPedido']}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _finalizar() async {
    try {
      setState(() {
        showProgressUploading = true;
      });
      var pedido = widget.pedido;

      final dataOp = {
        'token': usuario['token'],
        'idNuevoEstado': NO_ENTREGADO_RECHAZADO,
        'idDetallePedido': pedido['idDetallePedido'],
        'idActivo': usuario['idUnidad'],
        'detalleFormulario': [
          {
            'idPedido': pedido['idPedido'],
            'idDetallePedido': pedido['idDetallePedido'],
            'idEstadoFinal': NO_ENTREGADO_RECHAZADO,
            'idSubEstadoFinal': widget.idSubestado,
            'idPreguntaConcepto': PREGUNTA_FOTOGRAFIA,
            'idRespuestaConcepto': FOTOGRAFIA,
            'descripcionOtro': '',
            'esArchivo': 1,
            'tipoArchivo': '.jpg',
            'notaObservacion': widget.comentario,
            'direccionNombreArchivo': '',
            'base64': base64,
          },
        ],
      };

      final response = await doFetchJSON(URL_UM,
          {'data_op': dataOp, 'op': 'UPDATE-ACTIVIDADGENERALULTIMAMILLA'});

      final response2 = await doFetchJSON(
        URL_UM,
        {
          'data_op': {
            'token': usuario['token'],
            'idDetallePedido': pedido['idDetallePedido'],
            'idPedido': pedido['idPedido'],
            'idEstadoActual': NO_ENTREGADO_RECHAZADO,
            'idEstadoAnterior': pedido['idConceptoEstadoPedido'],
          },
          'op': 'CREATE-WFDETALLEPEDIDOULTIMAMILLA',
        },
      );

      if (response['error'] == false && response2['error'] == false) {
        _enviarCorreo(pedido);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Se ha marcado el pedido como NO ENTREGADO')),
        );
        if (pedido['latPuntoInteres'].toString() != "0" ||
            pedido['lngPuntoInteres'].toString() != "0") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PendientesScreen()),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ActualizarUbicacionScreen(
                pedido: jsonEncode(widget.pedido),
                estado: NO_ENTREGADO_RECHAZADO,
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ocurrió un error')),
        );
      }
      setState(() {
        showProgressUploading = false;
      });
    } catch (error, stackTrace) {
      print(error);
      print(stackTrace);
    }
  }

  Future<void> _enviarCorreo(dynamic pedido) async {
    try {
      var correos = jsonDecode(pedido['meta'])?['correosNotificacion'];
      if (correos != null) {
        final response = await doFetchJSON(
          URL_UM,
          {
            'data_op': {
              'email': jsonDecode(pedido['meta'])?['correosNotificacion'],
              'codigoPedido': pedido['codigoPedido'],
              'estadoPedido': 'NO ENTREGADO',
              'nombreCliente': pedido['nombrePuntoInteres'],
            },
            'op': 'ENVIAR-EMAILSTATUS',
          },
        );
        if (response['error'] == true) {
          print('Error enviando correo');
        }
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("NO ENTREGADO"),
        automaticallyImplyLeading: true,
        centerTitle: true,
      ),
      body: kIsWeb
          ? SizedBox(
              child: Center(
                child: Text(
                  "No se puede marcar como NO ENTREGADO desde un ordenador de escritorio",
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : showProgressUploading
              ? Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    children: [
                      Text(
                        "FOTO RAZON PORQUE NO SE REALIZO EL PEDIDO",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      if (showCamera)
                        FutureBuilder<void>(
                          future: _initializeControllerFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.done) {
                              return CameraPreview(controller!);
                            } else {
                              return Center(child: CircularProgressIndicator());
                            }
                          },
                        ),
                      if (!showCamera && pictureTaken)
                        Center(
                          child: Image.memory(
                            base64Decode(base64),
                            //rheight: 350,
                          ),
                        ),
                      if (showCamera)
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _takePicture,
                                child: Text('TOMAR FOTO'),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                flashMode == 'on'
                                    ? Icons.flash_on
                                    : Icons.flash_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  flashMode = flashMode == 'on' ? 'off' : 'on';
                                });
                                controller?.setFlashMode(
                                  flashMode == 'on'
                                      ? FlashMode.torch
                                      : FlashMode.off,
                                );
                              },
                            ),
                          ],
                        ),
                      if (pictureTaken)
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              showCamera = true;
                              pictureTaken = false;
                            });
                          },
                          child: Text('VOLVER A TOMAR FOTO'),
                        ),
                      if (!showCamera && pictureTaken)
                        ElevatedButton(
                          onPressed: () {
                            showModalFinalizar();
                          },
                          child: Text('FINALIZAR'),
                        ),
                    ],
                  ),
                ),
    );
  }
}
