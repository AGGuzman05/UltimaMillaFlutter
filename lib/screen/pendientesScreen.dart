// ignore_for_file: prefer_const_constructors, library_private_types_in_public_api, avoid_print, unused_element, file_names

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ultimaMillaFlutter/screen/auth/login_screen.dart';
import 'package:ultimaMillaFlutter/screen/rutasScreen.dart';
import 'package:ultimaMillaFlutter/services/shared_functions.dart';
import 'package:ultimaMillaFlutter/util/const/base_url.dart';
import 'package:ultimaMillaFlutter/util/const/constants.dart';

class PendientesScreen extends StatelessWidget {
  const PendientesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Pendientes();
  }
}

class Pendientes extends StatefulWidget {
  const Pendientes({super.key});

  @override
  _PendientesState createState() => _PendientesState();
}

class _PendientesState extends State<Pendientes> {
  int cantidad = 0;
  Map<String, int>? detalleCantidad;
  bool rutaIniciada = false;
  Map<String, dynamic>? user;
  String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchUserAndRoutes();
    });
  }

  Future<void> fetchUserAndRoutes() async {
    try {
      var usuario = await obtenerUsuario();
      setState(() {
        user = usuario;
      });

      var pedidos = await _obtenerRutas();
      var filtradas = pedidos.where((obj) {
        return [
          PENDIENTE_ENTREGA,
          EN_RUTA,
          EN_PAUSA,
        ].contains(obj['idConceptoEstadoPedido']);
      }).toList();

      var rutaIniciada = filtradas.firstWhere(
        (obj) => [EN_RUTA, EN_PAUSA].contains(obj['idConceptoEstadoPedido']),
      );

      var fechasArr = filtradas
          .map((obj) => obj['fechaHoraEntregaFin'].split("T")[0])
          .toList();

      var count = <String, int>{};
      fechasArr.forEach((fecha) {
        count[fecha] = (count[fecha] ?? 0) + 1;
      });

      if (rutaIniciada != null) {
        setState(() {
          this.rutaIniciada = true;
        });
      }

      if (user!['idEmpresa'] == 6290) {
        count.removeWhere((key, value) => key != today);
      }

      setState(() {
        cantidad = filtradas.length;
        detalleCantidad = count;
      });
    } catch (e) {
      print(e);
      await clearUserData();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LoginScreen(),
        ),
      );
    }
  }

  Future<List<Map<String, dynamic>>> _obtenerRutas() async {
    var usuario = await obtenerUsuario();
    var dataOp = {'token': usuario['token']};
    try {
      var rutas = await doFetchJSON(URL_UM, {
        'data_op': dataOp,
        'op': 'READ-OBTENERASIGNACIONPEDIDOSULTIMAMILLA',
      });
      if (rutas['error'] == false) {
        return List<Map<String, dynamic>>.from(rutas['data']);
      } else {
        //await clearUserData();
        return [];
      }
    } catch (err) {
      print("obtenerRutas err");
      print(err);
      return [];
    }
  }

  void _showAlert(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _irPantallaSiguiente() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RutasScreen(
          date: today,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var userData = user ?? {};

    return Builder(builder: (context) {
      return PopScope(
        canPop: false,
        child: Scaffold(
          appBar: AppBar(
            title: Text('TOTAL PENDIENTES'),
            actions: [
              IconButton(
                icon: Icon(Icons.logout),
                onPressed: () async {
                  await clearUserData();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LoginScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  _buildUserInfo(userData),
                  if (userData['idEmpresa'] != 6290) _buildTotalPendientes(),
                  if (detalleCantidad != null) _buildDetalleCantidad(),
                ],
              ),
            ),
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: cantidad > 0 ? _irPantallaSiguiente : null,
              child: Text(
                cantidad > 0
                    ? "VER MIS PEDIDOS DE HOY"
                    : "SIN PEDIDOS ASIGNADOS HOY",
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildUserInfo(Map<String, dynamic> userData) {
    return Container(
      padding: EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Image.asset("assets/images/person.png", width: 64, height: 64),
              SizedBox(width: 8.0),
              Text(userData['nombre'] ?? ''),
            ],
          ),
          Row(
            children: [
              Image.asset("assets/images/truck64.png", width: 64, height: 64),
              SizedBox(width: 8.0),
              Text(userData['idUnidad'] ?? ''),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalPendientes() {
    return Row(
      children: [
        Image.asset("assets/images/downloading.png", width: 64, height: 64),
        SizedBox(width: 8.0),
        Text("Total Pendientes: $cantidad"),
      ],
    );
  }

  Widget _buildDetalleCantidad() {
    return Column(
      children: detalleCantidad!.entries.map((entry) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RutasScreen(
                  date: (entry.key),
                ),
              ),
            );
          },
          child: Container(
            padding: EdgeInsets.all(8.0),
            margin: EdgeInsets.symmetric(vertical: 4.0),
            decoration: BoxDecoration(
              color: Colors.yellow[100],
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("CANT. PDTES."),
                Text(entry.key),
                Text(
                  entry.value.toString(),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
