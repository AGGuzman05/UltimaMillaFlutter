// ignore_for_file: prefer_const_constructors, unnecessary_this, avoid_print, use_build_context_synchronously

import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ultimaMillaFlutter/util/const/base_url.dart';
import 'package:ultimaMillaFlutter/util/const/constants.dart';
import '../services/shared_functions.dart';

class EntregaParcialScreen extends StatefulWidget {
  const EntregaParcialScreen(
      {super.key,
      required this.date,
      required this.pedido,
      required this.comentario,
      required this.idSubestado,
      required this.tiempoDescarga});
  final String date;
  final dynamic pedido;
  final String comentario;
  final int idSubestado;
  final int tiempoDescarga;

  @override
  State<EntregaParcialScreen> createState() => _EntregaParcialScreenState();
}

class _EntregaParcialScreenState extends State<EntregaParcialScreen> {
  bool viewFirma = false;
  bool viewForm = true;
  int currentView = FOTO_VIEW;
  bool showCamera = false;
  String flashOn = 'off';
  bool showProgressDialogCamera = false;
  bool pictureTaken = false;
  String base64 = '';
  bool sign = false;
  String signUri = '';
  int idQuienRecibe = -1;
  bool mostrarInputOtroReceptor = false;
  String valorOtroReceptor = '';
  String nombreReceptor = '';
  bool mostrarInputMonto = false;
  String montoPagadoAConductor = '';
  bool mostrarInputOtroEstadoPago = false;
  String valorOtroEstadoPago = '';
  int idEstadoPago = -1;
  bool showModal = false;
  bool showProgressUploading = false;
  List<dynamic> entregas = [];
  bool omitirFirma = false;
  bool omitirFotografia = false;
  bool omitirQuienrecibe = false;
  bool omitirEstadoPago = false;
  List<dynamic> entregaUnica = [];
  Map usuario = {};
  dynamic pedido;
  late CameraController _cameraController;

  @override
  void initState() {
    super.initState();
    setState(() {
      pedido = widget.pedido;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initValues();
      getCameraPermission();
      getCoincidencias();
    });
  }

  Future<void> getCoincidencias() async {
    String selectedDate = widget.date;
    List<dynamic> entregas = await obtenerRutas();
    entregas = entregas.where((obj) {
      return obj['idPuntoInteres'] == pedido['idPuntoInteres'] &&
          (obj['idConceptoEstadoPedido'] == PENDIENTE_ENTREGA ||
              obj['idConceptoEstadoPedido'] == EN_RUTA ||
              obj['idConceptoEstadoPedido'] == EN_PAUSA) &&
          obj['fechaHoraEntregaFin'].contains(selectedDate);
    }).toList();

    var entregaUnica = entregas.firstWhere((obj) {
      return obj['codigoPedido'] == pedido['codigoPedido'];
    }, orElse: () => null);

    setState(() {
      this.entregas = entregas;
      this.entregaUnica = [entregaUnica];
    });
  }

  Future<void> initValues() async {
    var user = await obtenerUsuario();
    setState(() {
      usuario = user;
      if ([MADISA, MADISALP, MADISACBBA, MADISASC]
          .contains(user['idEmpresa'])) {
        this.currentView = QUIEN_RECIBE_VIEW;
        this.omitirFotografia = true;
        this.omitirFirma = true;
      }
    });
  }

  Future<void> quienRecibeSeleccionado(int value) async {
    print("quienRecibeSeleccionado");
    setState(() {
      this.idQuienRecibe = value;
    });
  }

  Future<void> estadoPagoSeleccionado(int value) async {
    print("estadoPedidoSeleccionado");
    setState(() {
      this.idEstadoPago = value;
    });
  }

  Future<void> openViewFirma() async {
    print("openViewFirma");
    setState(() {
      this.viewFirma = true;
      this.viewForm = false;
    });
  }

  Future<void> openViewForm() async {
    print("openViewForm");
    setState(() {
      this.viewFirma = false;
      this.viewForm = true;
    });
  }

  Future<void> updateComentario() async {
    print("updateComentario");
  }

  void anteriorMadisa(int currentView) {
    if (currentView == QUIEN_RECIBE_VIEW) {
      Navigator.of(context).pop();
    } else if (currentView == ESTADO_PAGO_VIEW) {
      setState(() {
        this.currentView = QUIEN_RECIBE_VIEW;
      });
    }
  }

  Future<void> anterior() async {
    print("anterior");
    int empresa = this.usuario['idEmpresa'];
    if ([MADISA, MADISALP, MADISACBBA, MADISASC].contains(empresa)) {
      anteriorMadisa(currentView);
    } else {
      if (currentView == FOTO_VIEW) {
        Navigator.of(context).pop();
      } else if (currentView == QUIEN_RECIBE_VIEW) {
        setState(() {
          this.currentView = FOTO_VIEW;
        });
      } else if (currentView == FIRMA_VIEW) {
        setState(() {
          this.currentView = QUIEN_RECIBE_VIEW;
        });
      } else if (currentView == ESTADO_PAGO_VIEW) {
        setState(() {
          this.currentView = FIRMA_VIEW;
        });
      }
    }
  }

  void siguienteMadisa(int currentView) {
    if (currentView == QUIEN_RECIBE_VIEW) {
      setState(() {
        this.currentView = ESTADO_PAGO_VIEW;
      });
    } else if (currentView == ESTADO_PAGO_VIEW) {
      finalizar(true);
    }
  }

  Future<void> siguiente() async {
    print("siguiente");
    int empresa = this.usuario['idEmpresa'];
    if ([MADISA, MADISALP, MADISACBBA, MADISASC].contains(empresa)) {
      siguienteMadisa(currentView);
    } else {
      if (currentView == FOTO_VIEW) {
        if (empresa == VETERQUIMICA) {
          setState(() {
            this.omitirFirma = true;
            this.omitirQuienrecibe = true;
            this.omitirEstadoPago = true;
          });
          finalizar(true);
        } else {
          setState(() {
            this.currentView = QUIEN_RECIBE_VIEW;
          });
        }
      } else if (currentView == QUIEN_RECIBE_VIEW) {
        setState(() {
          this.currentView = FIRMA_VIEW;
        });
      } else if (currentView == FIRMA_VIEW) {
        setState(() {
          this.currentView = ESTADO_PAGO_VIEW;
        });
      }
    }
  }

  Future<void> finalizar(bool unique) async {
    try {
      setState(() {
        showModal = false;
        showProgressUploading = true;
      });

      var usuario = await obtenerUsuario();
      var params = pedido;
      var entregasList = unique ? entregaUnica : entregas;
      List<Map<String, dynamic>> results = [];

      String fechaFin = DateTime.now()
          .toIso8601String()
          .replaceAll('T', ' ')
          .substring(0, 19);
      print(fechaFin);
      String nombreConcat =
          "${idQuienRecibe == OTRO_RECIBE ? '(OTRO) ' : ''}${valorOtroReceptor.isNotEmpty ? '($valorOtroReceptor) ' : ''}$nombreReceptor";
      String otroRecibeConcat =
          "${idQuienRecibe == OTRO_RECIBE ? '(OTRO) ' : ''}${valorOtroReceptor.isNotEmpty ? '($valorOtroReceptor) ' : ''}";
      String otroPagoConcat =
          "${idEstadoPago == OTRO_PAGO ? '(OTRO) ' : ''}${valorOtroEstadoPago.isNotEmpty ? '($valorOtroEstadoPago) ' : ''}";

      for (var entrega in entregasList) {
        Map<String, dynamic> dataOp = {
          'token': usuario['token'],
          'idNuevoEstado': ENTREGA_PARCIAL,
          'idDetallePedido': entrega['idDetallePedido'],
          'idActivo': usuario['idUnidad'],
          'detalleFormulario': [
            {
              'idPedido': entrega['idPedido'],
              'idDetallePedido': entrega['idDetallePedido'],
              'idEstadoFinal': ENTREGA_PARCIAL,
              'idSubEstadoFinal': params['idSubEstado'],
              'idPreguntaConcepto': PREGUNTA_FOTOGRAFIA,
              'idRespuestaConcepto': FOTOGRAFIA,
              'descripcionOtro': '',
              'nombreReceptor': '',
              'esArchivo': omitirFotografia ? 0 : 1,
              'tipoArchivo': '.jpg',
              'notaObservacion': params['comentario'],
              'direccionNombreArchivo': '',
              'base64': omitirFotografia ? '' : base64,
              'tiempoDescarga': params['tiempoDescarga'],
              'montoPagadoAConductor': '',
              'otroEstadoPago': '',
            },
            {
              'idPedido': entrega['idPedido'],
              'idDetallePedido': entrega['idDetallePedido'],
              'idEstadoFinal': ENTREGA_PARCIAL,
              'idSubEstadoFinal': params['idSubEstado'],
              'idPreguntaConcepto': PREGUNTA_QUIEN_RECIBE,
              'idRespuestaConcepto':
                  omitirQuienrecibe ? OTRO_RECIBE : idQuienRecibe,
              'descripcionOtro': omitirQuienrecibe ? '' : otroRecibeConcat,
              'nombreReceptor': omitirQuienrecibe ? '' : nombreConcat,
              'esArchivo': 0,
              'tipoArchivo': '',
              'notaObservacion': params['comentario'],
              'direccionNombreArchivo': '',
              'tiempoDescarga': params['tiempoDescarga'],
              'montoPagadoAConductor': '',
              'otroEstadoPago': '',
            },
            {
              'idPedido': entrega['idPedido'],
              'idDetallePedido': entrega['idDetallePedido'],
              'idEstadoFinal': ENTREGA_PARCIAL,
              'idSubEstadoFinal': params['idSubEstado'],
              'idPreguntaConcepto': PREGUNTA_FIRMA,
              'idRespuestaConcepto': FIRMA,
              'descripcionOtro': '',
              'nombreReceptor': '',
              'esArchivo': omitirFirma ? 0 : 1,
              'tipoArchivo': '.png',
              'notaObservacion': params['comentario'],
              'direccionNombreArchivo': '',
              'base64': omitirFirma ? '' : signUri,
              'tiempoDescarga': params['tiempoDescarga'],
              'montoPagadoAConductor': '',
              'otroEstadoPago': '',
            },
            {
              'idPedido': entrega['idPedido'],
              'idDetallePedido': entrega['idDetallePedido'],
              'idEstadoFinal': ENTREGA_PARCIAL,
              'idSubEstadoFinal': params['idSubEstado'],
              'idPreguntaConcepto': PREGUNTA_ESTADO_PAGO,
              'idRespuestaConcepto':
                  omitirEstadoPago ? OTRO_PAGO : idEstadoPago,
              'descripcionOtro': '',
              'nombreReceptor': '',
              'esArchivo': 0,
              'tipoArchivo': '',
              'notaObservacion': params['comentario'],
              'direccionNombreArchivo': '',
              'tiempoDescarga': params['tiempoDescarga'],
              'montoPagadoAConductor':
                  omitirEstadoPago ? '' : montoPagadoAConductor,
              'otroEstadoPago': omitirEstadoPago ? '' : otroPagoConcat,
            },
          ],
        };

        Map<String, dynamic> data_opWF = {
          'token': usuario['token'],
          'idDetallePedido': entrega['idDetallePedido'],
          'idPedido': entrega['idPedido'],
          'idEstadoActual': ENTREGA_PARCIAL,
          'idEstadoAnterior': entrega['idConceptoEstadoPedido'],
        };

        Map<String, dynamic> data_opTE = {
          'token': usuario['token'],
          'fechaHoraFin': fechaFin,
          'idDetallePedido': entrega['idDetallePedido'],
        };

        var res;
        var resWF;
        try {
          res = await doFetchJSON(
              'https://gestiondeflota.boltrack.net/apiUltimaMilla/datos',
              {'data_op': dataOp, 'op': 'UPDATE-ACTIVIDADGENERALULTIMAMILLA'});

          resWF = await doFetchJSON(
              'https://gestiondeflota.boltrack.net/apiUltimaMilla/datos', {
            'data_op': data_opWF,
            'op': 'CREATE-WFDETALLEPEDIDOULTIMAMILLA'
          });

          await doFetchJSON(
              'https://gestiondeflota.boltrack.net/apiUltimaMilla/datos',
              {'data_op': data_opTE, 'op': 'UPDATE-TIEMPOENTREGAMOVIL'});

          await doFetchJSON(
              'https://gestiondeflota.boltrack.net/apiUltimaMilla/datos',
              {'data_op': data_opTE, 'op': 'UPDATE-TIEMPOATENCIONCLIENTE'});

          results.add({
            'data': res,
            'obj': dataOp,
            'dataWF': resWF,
            'objWF': data_opWF,
            'objTE': data_opTE,
            'info': params,
          });
          //enviarCorreo();
        } catch (error) {
          print(error);
          results.add({
            'data': res,
            'obj': dataOp,
            'dataWF': resWF,
            'objWF': data_opWF,
            'objTE': data_opTE,
            'info': params,
          });
        }
      }

      List<Map<String, dynamic>> noCompletados = [];
      if (results.every((e) {
        if (e['data']?['error'] == true || e['data'] == null) {
          noCompletados.add(e);
        }
        return e['data']?['error'] == false && e['dataWF']?['error'] == false;
      })) {
        if (entregasList.length > 1) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  'Se marcaron todos los pedidos correspondientes al punto de interes como ENTREGA PARCIAL')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Se ha marcado el pedido como ENTREGA PARCIAL')));
        }

        if (params['latPuntoInteres'] != 0 || params['lngPuntoInteres'] != 0) {
          Navigator.pushNamed(context, 'QR', arguments: params);
        } else {
          Navigator.pushNamed(context, 'ACTUALIZAR LATLNG', arguments: params);
        }
      } else {
        print(noCompletados);
        SharedPreferences prefs = await SharedPreferences.getInstance();
        List<String> stored = prefs.getStringList('pedidosNoTerminados') ?? [];
        stored.add(jsonEncode(noCompletados));
        await prefs.setStringList('pedidosNoTerminados', stored);
        print(stored);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Ocurrió un error. El pedido se guardó para que se pueda finalizar después')));
        //Navigator.pushNamed(context, 'ENRUTA');
      }

      setState(() {
        showProgressUploading = false;
      });
    } catch (err) {
      print(err);
      setState(() {
        showProgressUploading = false;
      });
    }
  }

  Future<void> enviarCorreo(Map<String, dynamic> params) async {
    final correos = jsonDecode(params['meta'])['correosNotificacion'];
    await doFetchJSON(URL_UM, {
      'data_op': {
        'email': correos,
        'codigoPedido': params['codigoPedido'],
        'estadoPedido': 'ENTREGA PARCIAL',
        'nombreCliente': params['nombrePuntoInteres'],
      },
      'op': 'ENVIAR-EMAILSTATUS',
    });
  }

  Future<List<dynamic>> obtenerRutas() async {
    final response = await doFetchJSON(
        URL_UM,
        ({
          'data_op': {'token': usuario['token']},
          'op': 'READ-OBTENERASIGNACIONPEDIDOSULTIMAMILLA',
        }));

    if (response['error'] == false) {
      return response['data'];
    } else {
      return [];
    }
  }

  Future<void> liberarDeAsignacion(int idAsignacionPedido) async {
    final prefs = await SharedPreferences.getInstance();
    String? stored = prefs.getString('liberarDeAsignacion');
    List<dynamic> arr = stored != null ? jsonDecode(stored) : [];

    bool exists =
        arr.any((obj) => obj['idAsignacionPedido'] == idAsignacionPedido);
    if (!exists) {
      arr.add({'idAsignacionPedido': idAsignacionPedido});
      await prefs.setString('liberarDeAsignacion', jsonEncode(arr));
    }
  }

  Future<void> getCameraPermission() async {
    var status = await Permission.camera.request();
    if (status.isGranted) {
      setState(() {
        showCamera = true;
      });
    } else {
      print("Debe activar los permisos de cámara");
    }
  }

  Future<void> takePicture() async {
    try {
      setState(() {
        showProgressDialogCamera = true;
      });

      if (_cameraController != null && _cameraController!.value.isInitialized) {
        final XFile picture = await _cameraController!.takePicture();
        final data64 = await picture.readAsBytes();
        final base64String = base64Encode(data64);

        setState(() {
          base64 = "data:image/jpg;base64,$base64String";
          pictureTaken = true;
          showCamera = false;
          showProgressDialogCamera = false;
        });
      }
    } catch (err) {
      print(err);
    }
  }

  void handleSignature(String signature) {
    setState(() {
      viewFirma = false;
      viewForm = true;
      sign = true;
      signUri = signature;
    });
  }

  void mostrarAlertaFormularios() {
    setState(() {
      showModal = false;
    });
    print(
        "Debe rellenar los formularios o seleccionar la opción 'OMITIR' para cada uno");
  }

  double _getProgressWidth(int view) {
    switch (view) {
      case FOTO_VIEW:
        return 0.25;
      case QUIEN_RECIBE_VIEW:
        return 0.50;
      case FIRMA_VIEW:
        return 0.75;
      case ESTADO_PAGO_VIEW:
      default:
        return 1.0;
    }
  }

  Widget _buildProgressBar() {
    return LinearProgressIndicator(
      value: 0.25, // Cambiar el valor de acuerdo al progreso actual
      backgroundColor: Colors.grey[300],
      valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
    );
  }

  // Widget para mostrar la cámara y los botones relacionados
  Widget _buildCameraWidget() {
    return showCamera
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CameraPreview(_cameraController),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: takePicture,
                      child: Text("TOMAR FOTO"),
                    ),
                  ),
                  SizedBox(width: 10),
                  //IconButton(
                  //  onPressed: changeFlash,
                  //  icon: Icon(
                  //    flashOn ? Icons.flash_on : Icons.flash_off,
                  //    size: 30,
                  //  ),
                  //),
                ],
              ),
              SizedBox(height: 10),
              //_buildProgressDialog(),
            ],
          )
        : SizedBox.shrink();
  }

  // Widget para mostrar la vista previa de la foto tomada
  Widget _buildPhotoPreview() {
    return pictureTaken
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.memory(
                // Mostrar la imagen base64 (debes implementar esta lógica según tu uso)
                base64Decode(base64),
                fit: BoxFit.cover,
              ),
              SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  setState(() {
                    showCamera = true;
                    pictureTaken = false;
                  });
                },
                child: Text("VOLVER A TOMAR FOTO"),
              ),
            ],
          )
        : SizedBox.shrink();
  }

  // Widget para mostrar el checkbox de omitir fotografía
  Widget _buildOmitirFotoCheckbox() {
    return CheckboxListTile(
      title: Text("OMITIR FOTO"),
      value: omitirFotografia,
      onChanged: (value) {
        setState(() {
          omitirFotografia = value!;
        });
      },
    );
  }

  // Widget para mostrar los botones de navegación inferior (ANTERIOR y SIGUIENTE)
  Widget _buildNavigationButtons() {
    return Padding(
      padding: EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(
            onPressed: anterior,
            child: Text("ANTERIOR"),
          ),
          ElevatedButton(
            onPressed: siguiente,
            child: Text("SIGUIENTE"),
          ),
        ],
      ),
    );
  }

  Widget viewFotografiaScreen() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildProgressBar(),
          Padding(
            padding: EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "FOTO GUIA/COMPROBANTE",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                _buildCameraWidget(),
                SizedBox(height: 10),
                _buildPhotoPreview(),
                SizedBox(height: 10),
                _buildOmitirFotoCheckbox(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
          child: currentView == FOTO_VIEW ? viewFotografiaScreen() : null),
      bottomNavigationBar: _buildNavigationButtons(),
    );
  }
}
