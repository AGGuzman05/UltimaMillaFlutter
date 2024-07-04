// ignore_for_file: prefer_const_constructors, library_private_types_in_public_api

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:ultimaMillaFlutter/services/shared_functions.dart';
import 'package:ultimaMillaFlutter/util/const/constants.dart';

class NoEntregadoScreen extends StatefulWidget {
  const NoEntregadoScreen(
      {super.key,
      required this.pedido,
      required this.comentario,
      required this.idSubestado});
  final dynamic pedido;
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
  String base64Image = "";
  bool showModal = false;
  bool showProgressUploading = false;
  String flashMode = 'off';
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
      base64Image = base64Encode(await image.readAsBytes());
      setState(() {
        pictureTaken = true;
        showCamera = false;
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> _finalizar(BuildContext context) async {
    setState(() {
      showModal = false;
      showProgressUploading = true;
    });
    var params = jsonDecode(widget.pedido);
    final dataOp = {
      'token': usuario['token'],
      'idNuevoEstado': NO_ENTREGADO_RECHAZADO,
      'idDetallePedido': params['idDetallePedido'],
      'idActivo': params['idUnidad'],
      'detalleFormulario': [
        {
          'idPedido': params['idPedido'],
          'idDetallePedido': params['idDetallePedido'],
          'idEstadoFinal': NO_ENTREGADO_RECHAZADO,
          'idSubEstadoFinal': widget.idSubestado,
          'idPreguntaConcepto': 'PREGUNTA_FOTOGRAFIA',
          'idRespuestaConcepto': 'FOTOGRAFIA',
          'descripcionOtro': '',
          'esArchivo': 1,
          'tipoArchivo': '.jpg',
          'notaObservacion': widget.comentario,
          'direccionNombreArchivo': '',
          'base64': base64Image,
        },
      ],
    };

    final response = await http.post(
      Uri.parse('https://gestiondeflota.boltrack.net/apiUltimaMilla/datos'),
      body: jsonEncode(
          {'data_op': dataOp, 'op': 'UPDATE-ACTIVIDADGENERALULTIMAMILLA'}),
      headers: {"Content-Type": "application/json"},
    );

    final response2 = await http.post(
      Uri.parse('https://gestiondeflota.boltrack.net/apiUltimaMilla/datos'),
      body: jsonEncode({
        'data_op': {
          'token': usuario['token'],
          'idDetallePedido': params['idDetallePedido'],
          'idPedido': params['idPedido'],
          'idEstadoActual': NO_ENTREGADO_RECHAZADO,
          'idEstadoAnterior': params['idConceptoEstadoPedido'],
        },
        'op': 'CREATE-WFDETALLEPEDIDOULTIMAMILLA',
      }),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200 && response2.statusCode == 200) {
      final data = jsonDecode(response.body);
      final data2 = jsonDecode(response2.body);

      if (!data['error'] && !data2['error']) {
        _enviarCorreo(params);
        setState(() {
          showProgressUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Se ha marcado el pedido como NO ENTREGADO')),
        );
        if (params['latPuntoInteres'] != 0 || params['lngPuntoInteres'] != 0) {
          Navigator.pushNamed(context, '/finalizados');
        } else {
          Navigator.pushNamed(context, '/actualizarLatLng',
              arguments: {...params, 'estado': 'NOENTREGADO'});
        }
      } else {
        setState(() {
          showProgressUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ocurrió un error')),
        );
      }
    } else {
      setState(() {
        showProgressUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ocurrió un error')),
      );
    }
  }

  Future<void> _enviarCorreo(Map params) async {
    final response = await http.post(
      Uri.parse('https://gestiondeflota.boltrack.net/apiUltimaMilla/datos'),
      body: jsonEncode({
        'data_op': {
          'email': params['meta']['correosNotificacion'],
          'codigoPedido': params['codigoPedido'],
          'estadoPedido': 'NO ENTREGADO',
          'nombreCliente': params['nombrePuntoInteres'],
        },
        'op': 'ENVIAR-EMAILSTATUS',
      }),
      headers: {"Content-Type": "application/json"},
    );
    if (response.statusCode != 200) {
      print('Error enviando correo');
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
                    "No se puede marcar como NO ENTREGADO desde un ordenador de escritorio"),
              ),
            )
          : showProgressUploading
              ? Center(child: CircularProgressIndicator())
              : Column(
                  children: [
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
                          base64Decode(base64Image),
                          height: 350,
                        ),
                      ),
                    if (showCamera)
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _takePicture,
                              child: Text('Tomar Foto'),
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
                        child: Text('Volver a Tomar Foto'),
                      ),
                    if (!showCamera && pictureTaken)
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            showModal = true;
                          });
                        },
                        child: Text('Finalizar'),
                      ),
                  ],
                ),
      bottomSheet: showModal ? _buildModal(context) : SizedBox.shrink(),
    );
  }

  Widget _buildModal(BuildContext context) {
    return AlertDialog(
      title: Text('Desea marcar el pedido como NO_ENTREGADO?'),
      actions: [
        TextButton(
          onPressed: () {
            if (base64Image.isNotEmpty) {
              _finalizar(context);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('La foto es obligatoria')),
              );
              setState(() {
                showModal = false;
              });
            }
          },
          child: Text('Aceptar'),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              showModal = false;
            });
          },
          child: Text('Cancelar'),
        ),
      ],
    );
  }
}
