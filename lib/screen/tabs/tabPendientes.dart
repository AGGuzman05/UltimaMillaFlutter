// ignore_for_file: prefer_const_constructors, sort_child_properties_last, non_constant_identifier_names, avoid_print, library_private_types_in_public_api, use_build_context_synchronously, prefer_typing_uninitialized_variables

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ultimaMillaFlutter/screen/QRScreen.dart';
import 'package:ultimaMillaFlutter/screen/actualizarUbicacionScreen.dart';
import 'package:ultimaMillaFlutter/screen/detallePedidoScreen.dart';
import 'package:ultimaMillaFlutter/screen/modals/DialogHelper.dart';
import 'package:ultimaMillaFlutter/services/shared_functions.dart';
import 'package:ultimaMillaFlutter/util/const/base_url.dart';
import 'package:ultimaMillaFlutter/util/const/colors.dart';
import 'package:ultimaMillaFlutter/util/const/constants.dart';

class TabPendientes extends StatefulWidget {
  final dynamic pedido;
  final String date;

  const TabPendientes({super.key, required this.pedido, required this.date});

  @override
  _TabPendientesState createState() => _TabPendientesState();
}

class _TabPendientesState extends State<TabPendientes> {
  late GoogleMapController _controller;

  DateTime selectedDate = DateTime.now();
  bool showMapView = false;
  List<dynamic> rutasTotales = [];
  List<dynamic> pendientesPorFecha = [];
  List<dynamic> backupPorFecha = [];
  List<dynamic> agrupadosPorPuntoInteres = [];
  List<dynamic> grupoPedidosSelected = [];
  Map<String, dynamic> destination = {};
  Map<String, dynamic> mapDirectionResult = {};
  String message = "No hay conexion a Internet.";
  bool showCalendar = false;
  bool filterByPuntoInteres = false;
  bool showPedidosRezagados = false;
  bool showDetallePedidosModal = false;
  bool showModal = false;
  bool showProgressDialog = false;
  List<dynamic> sinCompletar = [];
  dynamic usuario = {};
  Map latlng = {};
  BitmapDescriptor? truckIcon;

  @override
  void initState() {
    super.initState();
    getUbicacionVehiculo();
    _handleDate();
    _getPedidosSinCompletar();
    getRutasFiltradas();
    _loadTruckIcon();
  }

  Future<void> getUbicacionVehiculo() async {
    var usuario = await obtenerUsuario();
    var data_op = {
      'placa': usuario['idUnidad'],
      'token': usuario['token'],
      'checkConsumoUM': true,
    };
    try {
      var response = await doFetchJSON(URL_GESTION, {
        'data_op': data_op,
        'op': 'READ-OBTENEREVENTOACTUALVEHICULO',
      });
      if (response['error'] == false) {
        setState(() {
          latlng = {
            'lat': response['data'][0]['LATITUD'],
            'lng': response['data'][0]['LONGITUD'],
          };
        });
      }
    } catch (error) {
      print(error);
    }
  }

  Future<void> _loadTruckIcon() async {
    final icon = await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(size: Size(48, 48)),
      'assets/images/truck64.png',
    );
    setState(() {
      truckIcon = icon;
    });
  }

  _handleDate() {
    setState(() {
      selectedDate = DateTime.parse(widget.pedido);
    });
  }

  _getPedidosSinCompletar() async {
    // Simulate fetching data from storage
    List<dynamic> stored = [];
    setState(() {
      pendientesPorFecha = stored;
    });
  }

  List<dynamic> _groupByValue(List<dynamic> arr, String key) {
    Map<String, List<dynamic>> groupedMap = {};
    for (var item in arr) {
      String groupKey = item[key];
      if (!groupedMap.containsKey(groupKey)) {
        groupedMap[groupKey] = [];
      }
      groupedMap[groupKey]?.add(item);
    }
    return groupedMap.values.toList();
  }

  Future<dynamic> obtenerRutas() async {
    try {
      var usuario = await obtenerUsuario();
      Map<String, String> dataOp = {"token": usuario['token']};
      var obj = {
        "data_op": dataOp,
        "op": "READ-OBTENERASIGNACIONPEDIDOSULTIMAMILLA",
      };

      final data = await doFetchJSON(URL_UM, obj);
      if (data['error'] == false) {
        setState(() {
          rutasTotales = data['data'];
        });
      } else {
        DialogHelper.showSimpleDialog(context, 'Error', 'Ocurrio un error.');
      }
    } catch (e) {
      DialogHelper.showSimpleDialog(context, 'Error', '$e');
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller = controller;
  }

  _updateDistanceAndDuration(double distance, double duration) {
    setState(() {
      mapDirectionResult = {
        'distance': distance,
        'duration': duration,
      };
    });
  }

  String _getRecibidoPorText(dynamic formRecibe) {
    switch (formRecibe['idRespuestaConcepto']) {
      case 'CLIENTE':
        return 'Cliente';
      case 'FAMILIAR':
        return 'Familiar';
      case 'CONSERJE':
        return 'Conserje';
      case 'OTRO':
        return formRecibe['descripcionOtro'] ?? '';
      default:
        return '';
    }
  }

  String _getEstadoPagoText(dynamic formPago) {
    switch (formPago['idRespuestaConcepto']) {
      case 'PAGADO_A_TIENDA':
        return 'Pagado a tienda';
      case 'PAGADO_A_CONDUCTOR':
        return 'Pagado a conductor';
      case 'PENDIENTE_PAGO':
        return 'Pendiente pago';
      case 'TRANSFERENCIA':
        return 'Transferencia';
      case 'CREDITO':
        return 'Credito';
      default:
        return '';
    }
  }

  Widget _buildImage(String? base64Image, String placeholder) {
    if (base64Image != null && base64Image.isNotEmpty) {
      return Image.network(
        base64Image,
        width: 150,
        height: 140,
        fit: BoxFit.cover,
      );
    } else {
      return Container(
        width: 150,
        height: 140,
        color: Colors.grey,
        alignment: Alignment.center,
        child: Text(
          placeholder,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }

  Future<void> reintentarEnvio(
      Map<String, dynamic> data_op,
      Map<String, dynamic> data_opWF,
      Map<String, dynamic> data_opTE,
      int removeIndex) async {
    var user = await obtenerUsuario();

    try {
      var res = await doFetchJSON(
        URL_UM,
        {
          'data_op': {...data_op, 'token': user['token']},
          'op': 'UPDATE-ACTIVIDADGENERALULTIMAMILLA',
        },
      );

      var resWF = await doFetchJSON(
        URL_UM,
        {
          'data_op': {...data_opWF, 'token': user['token']},
          'op': 'CREATE-WFDETALLEPEDIDOULTIMAMILLA',
        },
      );

      await doFetchJSON(
        URL_UM,
        {
          'data_op': {...data_opTE, 'token': user['token']},
          'op': 'UPDATE-TIEMPOENTREGAMOVIL',
        },
      );

      await doFetchJSON(
        URL_UM,
        {
          'data_op': {...data_opTE, 'token': user['token']},
          'op': 'UPDATE-TIEMPOATENCIONCLIENTE',
        },
      );

      if (res['error'] == false && resWF['error'] == false) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        List<String> stored = prefs.getStringList('pedidosNoTerminados') ?? [];
        stored.removeAt(removeIndex);
        await prefs.setStringList('pedidosNoTerminados', stored);

        setState(() {
          showPedidosRezagados = false;
        });

        print("El pedido se completó correctamente");
        getPedidosSinCompletar();
      } else {
        print("Intente de nuevo más tarde");
      }
    } catch (error) {
      print(error);
    }
  }

  Future<void> getPedidosSinCompletar() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String stored = prefs.getString('pedidosNoTerminados') ?? '[]';
    setState(() {
      sinCompletar = json.decode(stored);
    });
  }

  void buscar(String text) {
    try {
      if (text.isNotEmpty) {
        print(text);
        final coincidencias = backupPorFecha.where((e) {
          return e['codigoPedido']
                  .toString()
                  .toLowerCase()
                  .contains(text.toLowerCase()) ||
              e['nombrePuntoInteres']
                  .toString()
                  .toLowerCase()
                  .contains(text.toLowerCase()) ||
              e['nombreCliente']
                  .toString()
                  .toLowerCase()
                  .contains(text.toLowerCase());
        }).toList();
        setState(() {
          pendientesPorFecha = coincidencias;
        });
      } else {
        setState(() {
          pendientesPorFecha = List.from(backupPorFecha);
        });
      }
    } catch (error) {
      print(error);
    }
  }

  List<List<Map<String, dynamic>>> groupByValue(List<dynamic> arr, String key) {
    Map<dynamic, List<Map<String, dynamic>>> groupedMap = {};

    for (var curr in arr) {
      if (!groupedMap.containsKey(curr[key])) {
        groupedMap[curr[key]] = [];
      }
      groupedMap[curr[key]]?.add(curr);
    }
    return groupedMap.values.toList();
  }

  Future<void> getRutasFiltradas() async {
    await obtenerRutas();

    List<dynamic> pdtes = rutasTotales.where((obj) {
      return obj['idConceptoEstadoPedido'] == PENDIENTE_ENTREGA ||
          obj['idConceptoEstadoPedido'] == EN_RUTA ||
          obj['idConceptoEstadoPedido'] == EN_PAUSA;
    }).toList();

    List<dynamic> pdtesFecha = [];
    for (int i = 0; i < pdtes.length; i++) {
      pdtes[i]['id'] = i;
      if (pdtes[i]['fechaHoraEntregaFin']
          .toString()
          .contains(DateFormat('yyyy-MM-dd').format(selectedDate))) {
        pdtesFecha.add(pdtes[i]);
      }
    }

    print("pendientes por fecha");
    print(pdtesFecha);

    List<dynamic> todosPorFecha = [];
    for (int i = 0; i < rutasTotales.length; i++) {
      rutasTotales[i]['id'] = i;
      if (rutasTotales[i]['fechaHoraEntregaFin']
          .toString()
          .contains(DateFormat('yyyy-MM-dd').format(selectedDate))) {
        todosPorFecha.add(rutasTotales[i]);
      }
    }

    List<dynamic> agrupadosPorPuntoInteres =
        groupByValue(todosPorFecha, 'idPuntoInteres');
    List<dynamic> finalAgrupados = [];

    for (int i = 0; i < agrupadosPorPuntoInteres.length; i++) {
      bool exclude = false;
      List<bool> values = [];
      for (var j in agrupadosPorPuntoInteres[i]) {
        if (j['idConceptoEstadoPedido'] == ENTREGA_TOTAL ||
            j['idConceptoEstadoPedido'] == ENTREGA_PARCIAL ||
            j['idConceptoEstadoPedido'] == NO_ENTREGADO_RECHAZADO) {
          values.add(true);
        } else {
          values.add(false);
        }
      }
      if (values.every((element) => element == true)) {
        exclude = true;
      }
      if (!exclude) {
        finalAgrupados.add(agrupadosPorPuntoInteres[i]);
      }
    }

    setState(() {
      backupPorFecha = pdtesFecha;
      pendientesPorFecha = pdtesFecha;
      agrupadosPorPuntoInteres = finalAgrupados;
    });
  }

  verDetalle(item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            //ActualizarUbicacionScreen(
            //  pedido: item,
            //  estado: ENTREGA_PARCIAL,
            //),

            //QRScreen(pedido: item),

            DetalleScreen(
          pedido: item,
          date: widget.date,
        ),
      ),
    );
  }
  /*

  Future<void> finalizarRutaGeneral() async {
    setState(() {
      showModal = false;
    });

    var usuario = await obtenerUsuario();

    SharedPreferences prefs = await SharedPreferences.getInstance();

    String listaPedidos = prefs.getString(KEYS.pedidosMarcados) ?? "[]";
    if (listaPedidos == null) {
      await prefs.setString(KEYS.pedidosMarcados, "[]");
      listaPedidos = "[]";
    }

    String listaAsignaciones =
        prefs.getString(KEYS.liberarDeAsignacion) ?? "[]";
    if (listaAsignaciones == null) {
      await prefs.setString(KEYS.liberarDeAsignacion, "[]");
      listaAsignaciones = "[]";
    }

    Map<String, dynamic> data_op = {
      'token': usuario.token,
      'listaPedidos': json.decode(listaPedidos),
    };

    Map<String, dynamic> data_op2 = {
      'token': usuario.token,
      'listaPedidos': json.decode(listaAsignaciones),
    };

    var data = await doFetchJSON(BASE_URL, {
      'data_op': data_op,
      'op': "CREATE-CREARDETALLEENTREGAULTIMAMILLA",
    });

    var data2 = await doFetchJSON(BASE_URL, {
      'data_op': data_op2,
      'op': "UPDATE-UMPEDIDOAFINALIZADOTULTIMAMILLA",
    });

    if (data['error'] == false && data2['error'] == false) {
      DialogHelper.showSimpleDialog(context, "Alerta",
          "Se finalizaron los pedidos de la ruta. La unidad está disponible para nuevas asignaciones.");
      await prefs.setString(KEYS.pedidosMarcados, "[]");
      await prefs.setString(KEYS.liberarDeAsignacion, "[]");
      var rutas = await obtenerRutas();
      var pdtes = rutas.where((obj) {
        return obj['idConceptoEstadoPedido'] == PENDIENTE_ENTREGA ||
            obj['idConceptoEstadoPedido'] == EN_RUTA ||
            obj['idConceptoEstadoPedido'] == EN_PAUSA;
      }).toList();
      setState(() {
        pendientes = pdtes;
      });
    } else {
      print("Data error: ${data['error']}");
      print("Data2 error: ${data2['error']}");
    }
  }
  */

  _mapView(List<dynamic> rutas) {
    if (latlng.isEmpty) {
      return Center(child: CircularProgressIndicator());
    } else {
      return SizedBox(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: LatLng(latlng['lat'], latlng['lng']),
              zoom: 12,
            ),
            myLocationEnabled: true,
            markers: _createMarkers()),
      );
    }
  }

  Set<Marker> _createMarkers() {
    Set<Marker> markers = {};

    markers.add(
      Marker(
        markerId: MarkerId('initial_position'),
        position: LatLng(latlng['lat'], latlng['lng']),
        icon: truckIcon!,
      ),
    );

    for (var marker in pendientesPorFecha) {
      markers.add(
        Marker(
          markerId: MarkerId(marker['id'].toString()),
          position: LatLng(
            double.parse(marker['latPuntoInteres']),
            double.parse(marker['lngPuntoInteres']),
          ),
          onTap: () {
            setState(() {
              destination = marker;
            });
          },
        ),
      );
    }

    return markers;
  }

  Widget ViewListaPendientes() {
    return SingleChildScrollView(
      child: Column(
        children: pendientesPorFecha.map((item) {
          var borderColor = AppColors.BoltrackMenuBlue;

          switch (item['idConceptoEstadoPedido']) {
            case EN_RUTA:
              borderColor = AppColors.SkyBlue;
              break;
            case ENTREGA_PARCIAL:
              borderColor = AppColors.OrangeLight;
              break;
            case NO_ENTREGADO_RECHAZADO:
              borderColor = AppColors.RedLight;
              break;
            case EN_PAUSA:
              borderColor = AppColors.PurpleLight;
              break;
            default:
              borderColor = AppColors.BoltrackMenuBlue;
          }

          var meta = (item.containsKey('meta') && item['meta'] is String)
              ? jsonDecode(item['meta'])
              : null;
          return GestureDetector(
            onTap: () {
              verDetalle(json.encode(item));
            },
            child: Stack(
              children: [
                Container(
                  margin: EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    border:
                        Border(left: BorderSide(color: borderColor, width: 4)),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Card(
                    elevation: 7,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Image.asset(
                              'assets/images/circle.png',
                              width: 20.0,
                              height: 20.0,
                            ),
                            SizedBox(width: 8.0),
                            if (item?['codigoPedido'] != null)
                              Text(
                                item?['codigoPedido'],
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                          ],
                        ),
                        SizedBox(height: 8.0),
                        Text(
                          item?['nombrePedido'] ?? "",
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4.0),
                        Text(
                          item?['nombrePuntoInteres'] ?? "",
                          style: TextStyle(fontSize: 14),
                        ),
                        SizedBox(height: 4.0),
                        Text(
                          item?['nombreCliente'] ?? "",
                          style: TextStyle(fontSize: 14),
                        ),
                        SizedBox(height: 4.0),
                        Row(
                          children: [
                            Image.asset(
                              'assets/images/pin.png',
                              width: 20.0,
                              height: 20.0,
                            ),
                            SizedBox(width: 8.0),
                            Text(
                              latlng.isNotEmpty
                                  ? getKilometros(
                                      latlng['lat'],
                                      latlng['lng'],
                                      double.parse(
                                        item['latPuntoInteres'],
                                      ),
                                      double.parse(item['lngPuntoInteres']))
                                  : 'Calculando...',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        SizedBox(height: 4.0),
                      ],
                    ),
                  ),
                ),
                Positioned(
                    bottom: 14,
                    right: 14,
                    child: (meta != null)
                        ? Row(
                            children: [
                              if (item?['meta'] != null &&
                                  meta['tipoServicio'] != null)
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(7)),
                                    color: AppColors.BoltrackMenuBlue,
                                  ),
                                  padding: EdgeInsets.all(4.0),
                                  margin: EdgeInsets.symmetric(vertical: 2.0),
                                  child: Text(
                                    meta['tipoServicio'].toString(),
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 10),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              SizedBox(
                                width: 4,
                              ),
                              if (item?['meta'] != null &&
                                  meta?['estadoPago'] != null)
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(7)),
                                    color: AppColors.Naranja,
                                  ),
                                  padding: EdgeInsets.all(4.0),
                                  margin: EdgeInsets.symmetric(vertical: 2.0),
                                  child: Text(
                                    '\$ ${meta['estadoPago']}',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 10),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                            ],
                          )
                        : SizedBox())
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget ViewAgrpadosPorCliente() {
    return SingleChildScrollView(
        child: agrupadosPorPuntoInteres.isNotEmpty
            ? ListView.builder(
                itemCount: agrupadosPorPuntoInteres.length,
                itemBuilder: (context, index) {
                  var item = agrupadosPorPuntoInteres[index];
                  int iniciados = 0;
                  item.forEach((e) {
                    if (e['idConceptoEstadoPedido'] == ENTREGA_TOTAL ||
                        e['idConceptoEstadoPedido'] == ENTREGA_PARCIAL ||
                        e['idConceptoEstadoPedido'] == NO_ENTREGADO_RECHAZADO) {
                      iniciados++;
                    }
                  });

                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          showDetallePedidosModal = true;
                          grupoPedidosSelected = item;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        margin: const EdgeInsets.all(7.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7.0),
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 20.0),
                                  decoration: BoxDecoration(
                                    color: Colors.amber,
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  child: Text(
                                    '${item.length} pedido(s)',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                                if (iniciados > 0)
                                  Container(
                                    padding: const EdgeInsets.all(7.0),
                                    margin: const EdgeInsets.only(left: 20.0),
                                    decoration: BoxDecoration(
                                      color: Colors.teal,
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),
                                    child: Text(
                                      'Iniciado',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                              ],
                            ),
                            Text(
                              item[0]['nombrePuntoInteres'] ?? '',
                              style: TextStyle(fontSize: 16.0),
                            ),
                            Text(
                              item[0]['nombreCliente'] ?? '',
                              style: TextStyle(fontSize: 16.0),
                            ),
                            /*
                            Text(
                              latlng['lat'] != null && latlng['lng'] != null
                                  ? '${getKilometros(
                                      ubicacion_actual.latitude,
                                      ubicacion_actual.longitude,
                                      item[0]['latPuntoInteres'],
                                      item[0]['lngPuntoInteres'],
                                    )} km'
                                  : 'Calculando...',
                              style: TextStyle(fontSize: 16.0),
                            ),
                            */
                          ],
                        ),
                      ),
                    ),
                  );
                })
            : SizedBox());
  }

  Widget ViewDetallePedidosModal() {
    return SingleChildScrollView(
        child: ListView.builder(
            itemCount: grupoPedidosSelected.length,
            itemBuilder: (context, index) {
              var e = grupoPedidosSelected[index];
              return GestureDetector(
                onTap: e['idConceptoEstadoPedido'] != 'ENTREGADO' &&
                        e['idConceptoEstadoPedido'] != 'ENTREGA_PARCIAL' &&
                        e['idConceptoEstadoPedido'] != 'NO_ENTREGADO_RECHAZADO'
                    ? () => {} //verDetalle(e)
                    : () => DialogHelper.showSimpleDialog(
                        context, 'Alerta', 'Este pedido ya fue gestionado'),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  padding: const EdgeInsets.all(2.0),
                  decoration: BoxDecoration(
                    color: Color(0xFFEFEFEF),
                    borderRadius: BorderRadius.circular(4.0),
                    border: Border(
                      left: BorderSide(
                        width: 4.0,
                        color: e['idConceptoEstadoPedido'] == PENDIENTE_ENTREGA
                            ? Colors.blue
                            : e['idConceptoEstadoPedido'] == EN_RUTA
                                ? Colors.lightBlueAccent
                                : e['idConceptoEstadoPedido'] == ENTREGA_TOTAL
                                    ? Colors.lightGreen
                                    : e['idConceptoEstadoPedido'] ==
                                            ENTREGA_PARCIAL
                                        ? Colors.orangeAccent
                                        : e['idConceptoEstadoPedido'] ==
                                                NO_ENTREGADO_RECHAZADO
                                            ? Colors.redAccent
                                            : Colors.purpleAccent,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e['nombrePedido'] ?? '',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(e['codigoPedido'] ?? ''),
                    ],
                  ),
                ),
              );
            }));
  }

  Widget ViewPedidosRezagados() {
    return SingleChildScrollView(
        child: ListView.builder(
            itemCount: sinCompletar.length,
            itemBuilder: (context, index) {
              var e = sinCompletar[index];
              var estado = e[0]['obj']?['idNuevoEstado'];
              var formRecibe = e[0]['obj']?['detalleFormulario'][1];
              var formPago = e[0]['obj']?['detalleFormulario'][3];

              return Container(
                  padding: const EdgeInsets.all(4.0),
                  margin: const EdgeInsets.all(3.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5.0),
                    border: Border.all(
                      width: 2.0,
                      color: Colors.blue,
                    ),
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () {},
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'EN RUTA > ${estado == ENTREGA_TOTAL ? 'ENTREGADO' : estado == ENTREGA_PARCIAL ? 'ENTREGA PARCIAL' : 'NO ENTREGADO'}',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: estado == ENTREGA_TOTAL
                                    ? Colors.green
                                    : estado == ENTREGA_PARCIAL
                                        ? Colors.orange
                                        : Colors.red,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text('CODIGO: ${e[0]['info']?['codigoPedido']}'),
                            Text('CLIENTE: ${e[0]['info']?['nombreCliente']}'),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    'COMENTARIO: ${e[0]['info']?['comentario']}'),
                                Text(
                                    'RECIBIDO POR: ${_getRecibidoPorText(formRecibe)} ${formRecibe['nombreReceptor'].isNotEmpty ? '- ${formRecibe['nombreReceptor']}' : ''}'),
                                Text(
                                    'ESTADO PAGO: ${_getEstadoPagoText(formPago)} ${formPago['idRespuestaConcepto'] == 'OTRO' ? formPago['otroEstadoPago'] : ''}'),
                                if (formPago['montoPagadoAConductor'] != null)
                                  Text(
                                      'MONTO PAGADO A CONDUCTOR (BS): ${formPago['montoPagadoAConductor']}'),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildImage(
                                      e[0]['obj']?['detalleFormulario'][0]
                                          ?['base64'],
                                      'SIN FOTO',
                                    ),
                                    _buildImage(
                                      e[0]['obj']?['detalleFormulario'][2]
                                          ?['base64'],
                                      'SIN FIRMA',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => reintentarEnvio(
                          e[0]['obj'],
                          e[0]['objWF'],
                          e[0]['objTE'],
                          index,
                        ),
                        child: Container(
                          color: Colors.lightBlue,
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          child: Center(
                            child: Text(
                              'REINTENTAR ENVIO',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ));
            }));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (usuario?['idEmpresa'] == VINOSKOHLBERG)
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              margin: EdgeInsets.all(20),
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Color(0xFF046D8B),
                borderRadius: BorderRadius.circular(25),
              ),
              child: IconButton(
                icon: Text(
                  '+',
                  style: TextStyle(fontSize: 35, color: Colors.white),
                ),
                onPressed: () {
                  //Navigator.push(context, NuevaVentaScreen());
                },
              ),
            ),
          ),
        Column(
          children: [
            Container(
              width: double.infinity,
              color: Color(0xFF21203F),
              padding: EdgeInsets.all(10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() {
                          showCalendar = true;
                        }),
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(7))),
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Row(
                            children: [
                              Icon(
                                Icons.event,
                              ),
                              Text(
                                DateFormat('yyyy-MM-dd').format(selectedDate),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(left: 4),
                        height: 40,
                        width: 150,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.all(Radius.circular(7)),
                          border: Border(
                              bottom: BorderSide(
                                  color: Color(0xFFCCCCCC), width: 2)),
                        ),
                        child: TextField(
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.only(top: -7, left: 4),
                            hintText: 'Buscar...',
                            border: InputBorder.none,
                          ),
                          onChanged: buscar,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      /*
                      Switch(
                        value: filterByPuntoInteres,
                        onChanged: (val) {
                          setState(() {
                            filterByPuntoInteres = val;
                          });
                        },
                        thumbColor: MaterialStateProperty.all(Colors.white),
                      ),*/
                      if (sinCompletar.isNotEmpty)
                        GestureDetector(
                          onTap: () => setState(() {
                            showPedidosRezagados = true;
                          }),
                          child: Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.lightBlue,
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Icon(
                              Icons.local_shipping_outlined,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      GestureDetector(
                        onTap: () => setState(() {
                          showMapView = !showMapView;
                          print(rutasTotales);
                        }),
                        child: Container(
                          margin: EdgeInsets.only(left: 4),
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Color(0xFFFA6532),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Icon(
                            showMapView ? Icons.list_alt : Icons.map,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: showMapView
                  ? _mapView(rutasTotales)
                  : pendientesPorFecha.isNotEmpty
                      ? filterByPuntoInteres
                          ? ViewAgrpadosPorCliente()
                          : ViewListaPendientes()
                      : Center(
                          child: Text(
                            'No hay asignaciones pendientes para la fecha seleccionada o para la busqueda realizada.',
                            style: TextStyle(
                              fontSize: 18,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
            ),
          ],
        ),
        if (showModal)
          Center(
            child: Container(
              padding: EdgeInsets.all(20),
              margin: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Desea finalizar su ruta?',
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: null,
                        child: Text('Si', style: TextStyle(fontSize: 18)),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.BoltrackMenuBlue),
                      ),
                      ElevatedButton(
                        onPressed: () => setState(() {
                          showModal = false;
                        }),
                        child: Text('No', style: TextStyle(fontSize: 18)),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.BoltrackMenuBlue),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        if (showDetallePedidosModal)
          Center(
            child: Container(
              padding: EdgeInsets.all(20),
              margin: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(width: 10),
                      Text('Seleccione un pedido para gestionarlo'),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.red),
                        onPressed: () => setState(() {
                          showDetallePedidosModal = false;
                          grupoPedidosSelected = [];
                        }),
                      ),
                    ],
                  ),
                  ViewDetallePedidosModal(),
                ],
              ),
            ),
          ),
        if (showPedidosRezagados)
          Center(
            child: Container(
              padding: EdgeInsets.all(20),
              margin: EdgeInsets.all(20),
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(width: 10),
                      Text(
                        'ENTREGAS \n NO COMPLETADAS',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.red),
                        onPressed: () => setState(() {
                          showPedidosRezagados = false;
                        }),
                      ),
                    ],
                  ),
                  ViewPedidosRezagados(),
                ],
              ),
            ),
          ),
        if (showProgressDialog)
          Center(
            child: CircularProgressIndicator(),
          ),
        if (showCalendar)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              margin: EdgeInsets.all(10),
              color: Colors.white,
              child: CalendarDatePicker(
                initialDate:
                    DateFormat('yyyy-MM-dd').parse(selectedDate.toString()),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
                onDateChanged: (date) {
                  setState(() {
                    selectedDate =
                        DateFormat('yyyy-MM-dd').parse(date.toString());
                    showCalendar = false;
                    getRutasFiltradas();
                  });
                },
              ),
            ),
          ),
      ],
    );
  }
}
