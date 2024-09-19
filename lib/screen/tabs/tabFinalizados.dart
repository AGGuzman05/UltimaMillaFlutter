// ignore_for_file: library_private_types_in_public_api, prefer_const_constructors, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ultimaMillaFlutter/services/shared_functions.dart';
import 'package:ultimaMillaFlutter/util/const/parametroConexion.dart';
import 'package:ultimaMillaFlutter/util/const/colors.dart';
import 'package:ultimaMillaFlutter/util/const/constants.dart';

class TabFinalizados extends StatefulWidget {
  const TabFinalizados({super.key, required this.date});
  final String date;

  @override
  _TabFinalizadosState createState() => _TabFinalizadosState();
}

class _TabFinalizadosState extends State<TabFinalizados> {
  List<dynamic> finalizadas = [];
  List<dynamic> backup = [];
  dynamic selected;
  bool showCalendar = false;
  bool showProgressDialog = false;
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    handleDate();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Equivalent to componentDidMount
      getRutasFiltradas();
    });
  }

  void handleDate() {
    if (widget.date != null) {
      setState(() {
        selectedDate = DateTime.parse(widget.date);
      });
    } else {
      setState(() {
        selectedDate = DateTime.now();
      });
    }
  }

  Future<void> getRutasFiltradas() async {
    try {
      List<dynamic> todos = await obtenerRutas();
      List<dynamic> finalizadas = todos.where((ruta) {
        return ruta!['idConceptoEstadoPedido'] == ENTREGA_TOTAL ||
            ruta['idConceptoEstadoPedido'] == ENTREGA_PARCIAL ||
            ruta['idConceptoEstadoPedido'] == NO_ENTREGADO_RECHAZADO;
      }).toList();

      List<dynamic> finalizadasPorFecha = finalizadas.where((ruta) {
        return ruta['fechaHoraEntregaFin']
            .contains(DateFormat('yyyy-MM-dd').format(selectedDate));
      }).toList();

      setState(() {
        backup = finalizadasPorFecha;
        this.finalizadas = finalizadasPorFecha;
      });
    } catch (e) {
      print(e);
    }
  }

  Future<List> obtenerRutas() async {
    setState(() {
      showProgressDialog = true;
    });
    var user = await obtenerUsuario();
    var data_op = {
      'token': user['token'],
    };
    try {
      var rutas = await doFetchJSON(URL_UM, {
        "data_op": data_op,
        "op": "READ-OBTENERASIGNACIONPEDIDOSULTIMAMILLA",
      });
      setState(() {
        showProgressDialog = false;
      });
      return rutas['error'] == false ? rutas['data'] : [];
    } catch (err) {
      print('obtenerRutas err: $err');
      return [];
    }
  }

  void showConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Reactivar pedido'),
          content: Text(
              '¿Está seguro que desea reactivar el pedido ${selected?['codigoPedido']}?'),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                await reactivarPedido();
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Si'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('No'),
            ),
          ],
        );
      },
    );
  }

  Future<void> reactivarPedido() async {
    var user = await obtenerUsuario();
    var data_op = {
      'token': user['token'],
      'id': selected['idDetallePedido'],
    };
    try {
      var result = await doFetchJSON(URL_UM, {
        "data_op": data_op,
        "op": "UPDATE-REACTIVARDETALLEPEDIDO",
      });
      if (result['error'] == false) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Se reactivo el pedido')));
        getRutasFiltradas();
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Ocurrio un error')));
      }
    } catch (err) {
      print('reactivarPedido err: $err');
    }
  }

  void buscar(String text) {
    if (text.isNotEmpty) {
      List<dynamic> coincidencias = backup.where((e) {
        return e['codigoPedido'].toLowerCase().contains(text.toLowerCase()) ||
            e['nombrePuntoInteres']
                .toLowerCase()
                .contains(text.toLowerCase()) ||
            e['nombreCliente'].toLowerCase().contains(text.toLowerCase());
      }).toList();
      setState(() {
        finalizadas = coincidencias;
      });
    } else {
      setState(() {
        finalizadas = backup;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(10),
            color: Color(0xFF21203f),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() {
                    showCalendar = true;
                  }),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(Radius.circular(7))),
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
                        bottom: BorderSide(color: Color(0xFFCCCCCC), width: 2)),
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
          ),
          Expanded(
            child: ListView.separated(
                itemCount: finalizadas.length,
                itemBuilder: (context, index) {
                  var item = finalizadas[index];
                  var borderColor = AppColors.BoltrackMenuBlue;

                  switch (item['idConceptoEstadoPedido']) {
                    case ENTREGA_TOTAL:
                      borderColor = AppColors.GreenLight;
                      break;
                    case ENTREGA_PARCIAL:
                      borderColor = AppColors.OrangeLight;
                      break;
                    case NO_ENTREGADO_RECHAZADO:
                      borderColor = AppColors.RedLight;
                      break;

                    default:
                      borderColor = AppColors.GreenLight;
                  }
                  return Container(
                    margin: EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      border: Border(
                          left: BorderSide(color: borderColor, width: 4)),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Card(
                      elevation: 7,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                                ],
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.more_vert),
                                    onPressed: () {
                                      setState(() {
                                        selected =
                                            selected == item ? null : item;
                                      });
                                    },
                                  ),
                                  if (selected == item)
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(7),
                                        ),
                                      ),
                                      onPressed: () {
                                        showConfirmDialog(context);
                                      },
                                      child: Text('Reactivar\npedido',
                                          textAlign: TextAlign.center),
                                    ),
                                ].reversed.toList(),
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
                        ],
                      ),
                    ),
                  );
                },
                separatorBuilder: (context, index) => SizedBox() //Divider(),
                ),
          ),
          if (showProgressDialog) CircularProgressIndicator(),
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
      ),
    );
  }
}
