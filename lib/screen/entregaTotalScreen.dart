// ignore_for_file: prefer_const_constructors, unnecessary_this, avoid_print, use_build_context_synchronously, prefer_interpolation_to_compose_strings, prefer_const_literals_to_create_immutables, non_constant_identifier_names

import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signature/signature.dart';
import 'package:ultimaMillaFlutter/screen/QRScreen.dart';
import 'package:ultimaMillaFlutter/screen/actualizarUbicacionScreen.dart';
import 'package:ultimaMillaFlutter/screen/modals/DialogHelper.dart';
import 'package:ultimaMillaFlutter/screen/pendientesScreen.dart';
import 'package:ultimaMillaFlutter/util/const/parametroConexion.dart';
import 'package:ultimaMillaFlutter/util/const/constants.dart';
import '../services/shared_functions.dart';
import 'package:image_picker/image_picker.dart';

class EntregaTotalScreen extends StatefulWidget {
  const EntregaTotalScreen(
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
  State<EntregaTotalScreen> createState() => _EntregaTotalScreenState();
}

class _EntregaTotalScreenState extends State<EntregaTotalScreen> {
  bool viewFirma = false;
  bool viewForm = true;
  int currentView = FOTO_VIEW;
  bool showCamera = false;
  String flashOn = 'off';
  bool showProgressDialogCamera = false;
  bool pictureTaken = false;
  String base64 = '';
  bool sign = false;
  String firma = '';
  dynamic bytesFirma;
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

  List RADIO_QUIEN_RECIBE = [
    {"label": "CLIENTE", "value": CLIENTE},
    {"label": "FAMILIAR", "value": FAMILIAR},
    {"label": "CONSERJE", "value": CONSERJE},
    {"label": "OTRO", "value": OTRO_RECIBE},
  ];

  List RADIO_ESTADO_PAGO = [
    {"label": "PAGADO A TIENDA", "value": PAGADO_A_TIENDA},
    {"label": "PAGADO A CONDUCTOR", "value": PAGADO_A_CONDUCTOR},
    {"label": "PENDIENTE PAGO", "value": PENDIENTE_PAGO},
    {"label": "CREDITO", "value": CREDITO},
    {"label": "TRANSFERENCIA", "value": TRANSFERENCIA},
    {"label": "OTRO", "value": OTRO_PAGO},
  ];

  SignatureController controllerFirma = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  @override
  void initState() {
    super.initState();
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
      print("ELEM");
      print(obj['idConceptoEstadoPedido']);
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
    usuario = await obtenerUsuario();
    setState(() {
      this.pedido = widget.pedido;
      this.usuario = usuario;
      if (usuario['idEmpresa'] == MADISA ||
          usuario['idEmpresa'] == MADISALP ||
          usuario['idEmpresa'] == MADISACBBA ||
          usuario['idEmpresa'] == MADISASC) {
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

  void anteriorMadisa(int currentView) {
    if (currentView == QUIEN_RECIBE_VIEW) {
      Navigator.of(context).pop();
    } else if (currentView == ESTADO_PAGO_VIEW) {
      setState(() {
        this.currentView = QUIEN_RECIBE_VIEW;
      });
    }
  }

  Future<void> anteriorOnClick() async {
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

  Future<void> siguienteOnClick() async {
    print("siguiente");
    int empresa = usuario['idEmpresa'];
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
    print("FINALIZAR");
    try {
      setState(() {
        showModal = false;
        showProgressUploading = true;
      });

      var usuario = await obtenerUsuario();
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
          'idNuevoEstado': ENTREGA_TOTAL,
          'idDetallePedido': entrega['idDetallePedido'],
          'idActivo': usuario['idUnidad'],
          'detalleFormulario': [
            {
              'idPedido': entrega['idPedido'],
              'idDetallePedido': entrega['idDetallePedido'],
              'idEstadoFinal': ENTREGA_TOTAL,
              'idSubEstadoFinal': widget.idSubestado,
              'idPreguntaConcepto': PREGUNTA_FOTOGRAFIA,
              'idRespuestaConcepto': FOTOGRAFIA,
              'descripcionOtro': '',
              'nombreReceptor': '',
              'esArchivo': omitirFotografia ? 0 : 1,
              'tipoArchivo': '.jpg',
              'notaObservacion': widget.comentario,
              'direccionNombreArchivo': '',
              'base64': omitirFotografia ? '' : base64,
              'tiempoDescarga': widget.tiempoDescarga,
              'montoPagadoAConductor': '',
              'otroEstadoPago': '',
            },
            {
              'idPedido': entrega['idPedido'],
              'idDetallePedido': entrega['idDetallePedido'],
              'idEstadoFinal': ENTREGA_TOTAL,
              'idSubEstadoFinal': widget.idSubestado,
              'idPreguntaConcepto': PREGUNTA_QUIEN_RECIBE,
              'idRespuestaConcepto':
                  omitirQuienrecibe ? OTRO_RECIBE : idQuienRecibe,
              'descripcionOtro': omitirQuienrecibe ? '' : otroRecibeConcat,
              'nombreReceptor': omitirQuienrecibe ? '' : nombreConcat,
              'esArchivo': 0,
              'tipoArchivo': '',
              'notaObservacion': widget.comentario,
              'direccionNombreArchivo': '',
              'tiempoDescarga': widget.tiempoDescarga,
              'montoPagadoAConductor': '',
              'otroEstadoPago': '',
            },
            {
              'idPedido': entrega['idPedido'],
              'idDetallePedido': entrega['idDetallePedido'],
              'idEstadoFinal': ENTREGA_TOTAL,
              'idSubEstadoFinal': widget.idSubestado,
              'idPreguntaConcepto': PREGUNTA_FIRMA,
              'idRespuestaConcepto': FIRMA,
              'descripcionOtro': '',
              'nombreReceptor': '',
              'esArchivo': omitirFirma ? 0 : 1,
              'tipoArchivo': '.png',
              'notaObservacion': widget.comentario,
              'direccionNombreArchivo': '',
              'base64': omitirFirma ? '' : firma,
              'tiempoDescarga': widget.tiempoDescarga,
              'montoPagadoAConductor': '',
              'otroEstadoPago': '',
            },
            {
              'idPedido': entrega['idPedido'],
              'idDetallePedido': entrega['idDetallePedido'],
              'idEstadoFinal': ENTREGA_TOTAL,
              'idSubEstadoFinal': widget.idSubestado,
              'idPreguntaConcepto': PREGUNTA_ESTADO_PAGO,
              'idRespuestaConcepto':
                  omitirEstadoPago ? OTRO_PAGO : idEstadoPago,
              'descripcionOtro': '',
              'nombreReceptor': '',
              'esArchivo': 0,
              'tipoArchivo': '',
              'notaObservacion': widget.comentario,
              'direccionNombreArchivo': '',
              'tiempoDescarga': widget.tiempoDescarga,
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
          'idEstadoActual': ENTREGA_TOTAL,
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
            'info': pedido,
          });
          enviarCorreo(pedido);
        } catch (error) {
          print(error);
          results.add({
            'data': res,
            'obj': dataOp,
            'dataWF': resWF,
            'objWF': data_opWF,
            'objTE': data_opTE,
            'info': pedido,
          });
        }
      }

      List<Map<String, dynamic>> noCompletados = [];
      print("RESSULTS");
      print(results);
      if (results.every((e) {
        if (e['data']?['error'] == true || e['data'] == null) {
          noCompletados.add(e);
        }
        return e['data']?['error'] == false && e['dataWF']?['error'] == false;
      })) {
        if (entregasList.length > 1) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  'Se marcaron todos los pedidos correspondientes al punto de interes como ENTREGA TOTAL')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Se ha marcado el pedido como ENTREGA TOTAL')));
        }

        if (pedido['latPuntoInteres'].toString() != "0" ||
            pedido['lngPuntoInteres'].toString() != "0") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QRScreen(
                pedido: jsonEncode(widget.pedido),
              ),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ActualizarUbicacionScreen(
                pedido: jsonEncode(widget.pedido),
                estado: ENTREGA_TOTAL,
              ),
            ),
          );
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
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PendientesScreen(),
          ),
        );
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
        'estadoPedido': 'ENTREGA TOTAL',
        'nombreCliente': params['nombrePuntoInteres'],
      },
      'op': 'ENVIAR-EMAILSTATUS',
    });
  }

  Future<List<dynamic>> obtenerRutas() async {
    var usuario = await obtenerUsuario();
    final response = await doFetchJSON(URL_UM, {
      'data_op': {'token': usuario['token']},
      'op': 'READ-OBTENERASIGNACIONPEDIDOSULTIMAMILLA',
    });

    print(response);

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

  Future<void> pickOrTakePhoto() async {
    try {
      XFile? pickedFile;
      dynamic status;

      if (!kIsWeb) status = await Permission.photos.request();
      if (status != null || kIsWeb) {
        final ImagePicker picker = ImagePicker();
        pickedFile = await picker.pickImage(source: ImageSource.camera);
      } else {
        DialogHelper.showSimpleDialog(
            context, "Alerta", "Necesita habilitar los permisos");
        return;
      }

      if (pickedFile != null) {
        Uint8List imageBytes;
        imageBytes = await pickedFile.readAsBytes();
        List<int> byteList = imageBytes.toList();
        String base64Image = base64Encode(byteList);
        setState(() {
          base64 = base64Image;
        });
      } else {
        print("No se seleccionó ninguna imagen o ocurrió un error.");
      }
    } catch (err, stackTrace) {
      print('Error al seleccionar la imagen: $err');
      print(stackTrace);
    }
  }

  void mostrarAlertaFormularios() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            "Debe rellenar los formularios o seleccionar la opción OMITIR para cada uno")));
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
      value: _getProgressWidth(
          currentView), // Cambiar el valor de acuerdo al progreso actual
      backgroundColor: Colors.grey[300],
      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
    );
  }

  Widget _buildPhotoPreview() {
    return base64 != ""
        ? Center(
            child: Center(
              child: Image.memory(
                base64Decode(base64),
                fit: BoxFit.cover,
              ),
            ),
          )
        : SizedBox.shrink();
  }

  showModalFinalizar() {
    var nombrePuntoInteres = widget.pedido["nombrePuntoInteres"];
    var fechaSelected = widget.date;
    print(entregaUnica);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: EdgeInsets.all(0),
          content: SizedBox(
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
                              setState(() {
                                showModal = false;
                              });
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      ),
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
                      Text(
                        'Marcar como ENTREGADO?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 20),
                      entregas.length > 1
                          ? GestureDetector(
                              onTap: () => {
                                if ((base64.isNotEmpty ||
                                        omitirFotografia == true) &&
                                    (firma.isNotEmpty || omitirFirma == true) &&
                                    (idEstadoPago != -1 ||
                                        omitirEstadoPago == true) &&
                                    (idQuienRecibe != -1 ||
                                        omitirQuienrecibe == true))
                                  {
                                    Navigator.of(context).pop(),
                                    finalizar(false)
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
                      GestureDetector(
                        onTap: () => {
                          if ((base64.isNotEmpty || omitirFotografia == true) &&
                              (firma.isNotEmpty || omitirFirma == true) &&
                              (idEstadoPago != -1 ||
                                  omitirEstadoPago == true) &&
                              (idQuienRecibe != -1 ||
                                  omitirQuienrecibe == true))
                            {Navigator.of(context).pop(), finalizar(true)}
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
                            'Solo el pedido ${entregaUnica[0]['codigoPedido']}',
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

  Widget _buildNavigationButtons() {
    return Padding(
      padding: EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(
            onPressed: anteriorOnClick,
            child: Text("ANTERIOR"),
          ),
          currentView != ESTADO_PAGO_VIEW
              ? ElevatedButton(
                  onPressed: siguienteOnClick,
                  child: Text("SIGUIENTE"),
                )
              : ElevatedButton(
                  onPressed: showModalFinalizar, child: Text("FINALIZAR")),
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
                _buildPhotoPreview(),
                SizedBox(height: 10),
                if (kIsWeb)
                  Center(
                    child: Text(
                        "No se puede tomar foto desde un ordenador de escritorio."),
                  )
                else
                  ElevatedButton(
                    onPressed: pickOrTakePhoto,
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("TOMAR FOTO"),
                        SizedBox(width: 4),
                        Icon(Icons.camera),
                      ],
                    ),
                  ),
                SizedBox(height: 10),
                CheckboxListTile(
                  title: Text("OMITIR FOTO"),
                  value: omitirFotografia,
                  onChanged: (value) {
                    setState(() {
                      omitirFotografia = value!;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget viewReceptorScreen() {
    return SingleChildScrollView(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildProgressBar(),
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'QUIEN RECIBE?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Column(
                children: RADIO_QUIEN_RECIBE.asMap().entries.map((entry) {
                  int idx = entry.key;
                  dynamic model = entry.value;
                  return RadioListTile(
                    value: model["value"],
                    groupValue: idQuienRecibe,
                    title: Text(model["label"]),
                    onChanged: (value) {
                      setState(() {
                        idQuienRecibe = value;
                        if (value == OTRO_RECIBE) {
                          mostrarInputOtroReceptor = true;
                        } else {
                          mostrarInputOtroReceptor = false;
                          valorOtroReceptor = '';
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              mostrarInputOtroReceptor
                  ? TextField(
                      onChanged: (text) {
                        setState(() {
                          valorOtroReceptor = text;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Cargo o relacion de quien recibio el pedido',
                      ),
                    )
                  : Container(),
              TextField(
                onChanged: (text) {
                  setState(() {
                    nombreReceptor = text;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Nombre y Apellido de quien recibio el pedido',
                ),
              ),
              CheckboxListTile(
                title: Text('OMITIR DATOS RECEPTOR'),
                value: omitirQuienrecibe,
                onChanged: (bool? value) {
                  print(value);
                  setState(() {
                    omitirQuienrecibe = value!;
                  });
                },
              ),
            ],
          ),
        )
      ],
    ));
  }

  Widget viewFirmaScreen(
    SignatureController controllerFirma,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgressBar(),
          firma == ""
              ? Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "FIRMA",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      ElevatedButton(
                          onPressed: () async {
                            dynamic image = await controllerFirma.toPngBytes();
                            setState(() {
                              firma = "data:image/png;base64," +
                                  base64Encode(image);
                              bytesFirma = image;
                            });
                          },
                          style: ButtonStyle(
                              elevation: MaterialStateProperty.all(7),
                              backgroundColor: MaterialStateColor.resolveWith(
                                  (states) => Colors.green)),
                          child: Text(
                            "Confirmar firma",
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          )),
                      SizedBox(
                        height: 14,
                      ),
                      Container(
                          decoration:
                              BoxDecoration(border: Border.all(width: 2)),
                          child: Signature(
                            controller: controllerFirma,
                            width: 350,
                            height: 200,
                            backgroundColor: Colors.white,
                          ))
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "FIRMA",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      ElevatedButton(
                          onPressed: () async {
                            setState(() {
                              firma = "";
                              controllerFirma.value = [];
                            });
                          },
                          style: ButtonStyle(
                              elevation: MaterialStateProperty.all(7),
                              backgroundColor: MaterialStateColor.resolveWith(
                                  (states) => Colors.green)),
                          child: Text(
                            "Limpiar",
                            style: TextStyle(color: Colors.white),
                          )),
                      Image.memory(
                        bytesFirma,
                        width: 350,
                        height: 200,
                      ),
                    ],
                  ),
                ),
          CheckboxListTile(
            title: Text("OMITIR FIRMA"),
            value: omitirFirma,
            onChanged: (value) {
              setState(() {
                omitirFirma = value!;
              });
            },
          )
        ],
      ),
    );
  }

  Widget viewEstadoPagoScreen() {
    return SingleChildScrollView(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildProgressBar(),
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ESTADO PAGO',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Column(
                children: RADIO_ESTADO_PAGO.asMap().entries.map((entry) {
                  int idx = entry.key;
                  dynamic model = entry.value;
                  return RadioListTile(
                    value: model["value"],
                    groupValue: idEstadoPago,
                    title: Text(model["label"]),
                    onChanged: (value) {
                      setState(() {
                        idEstadoPago = value;
                        if (value == PAGADO_A_CONDUCTOR) {
                          mostrarInputMonto = true;
                          mostrarInputOtroEstadoPago = false;
                        } else if (value == OTRO_PAGO) {
                          mostrarInputMonto = false;
                          mostrarInputOtroEstadoPago = true;
                        } else {
                          mostrarInputMonto = false;
                          mostrarInputOtroEstadoPago = false;
                          montoPagadoAConductor = '';
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              mostrarInputOtroEstadoPago
                  ? TextField(
                      onChanged: (text) {
                        setState(() {
                          valorOtroEstadoPago = text;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Especifique el nombre de otro estado pago',
                      ),
                    )
                  : Container(),
              mostrarInputMonto
                  ? TextField(
                      keyboardType: TextInputType.number,
                      onChanged: (text) {
                        setState(() {
                          montoPagadoAConductor = text;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Monto recibido por conductor',
                      ),
                    )
                  : Container(),
              CheckboxListTile(
                title: Text('OMITIR DATOS ESTADO PAGO'),
                value: omitirEstadoPago,
                onChanged: (bool? value) {
                  setState(() {
                    omitirEstadoPago = value!;
                  });
                },
              ),
            ],
          ),
        )
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ENTREGADO'),
        centerTitle: true,
      ),
      body: Container(
          child: currentView == FOTO_VIEW
              ? viewFotografiaScreen()
              : currentView == QUIEN_RECIBE_VIEW
                  ? viewReceptorScreen()
                  : currentView == FIRMA_VIEW
                      ? viewFirmaScreen(controllerFirma)
                      : viewEstadoPagoScreen()),
      bottomNavigationBar: _buildNavigationButtons(),
    );
  }
}
