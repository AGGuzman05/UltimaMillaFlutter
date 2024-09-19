// ignore_for_file: prefer_const_constructors, non_constant_identifier_names, prefer_const_literals_to_create_immutables

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:ultimaMillaFlutter/screen/gestionarPuntosdeInteres.dart';
import 'package:ultimaMillaFlutter/screen/modals/ConfirmDialog.dart';
import 'package:ultimaMillaFlutter/screen/widgets/customShimmer.dart';
import 'package:ultimaMillaFlutter/screen/widgets/menuDrawer.dart';
import 'package:ultimaMillaFlutter/services/shared_functions.dart';
import 'package:ultimaMillaFlutter/util/const/constants.dart';
import 'package:ultimaMillaFlutter/util/const/parametroConexion.dart';
import 'package:ultimaMillaFlutter/util/const/wrappedFields.dart';

class GestionarClientes extends StatefulWidget {
  const GestionarClientes({super.key});

  @override
  State<GestionarClientes> createState() => _GestionarClientesState();
}

class _GestionarClientesState extends State<GestionarClientes> {
  bool loadingData = false;
  bool createPoi = false;
  List<dynamic> listaClientes = [];
  List<dynamic> listaFiltrada = [];

  TextEditingController controllerNombre = TextEditingController();
  TextEditingController controllerCodigo = TextEditingController();
  TextEditingController controllerTelefono = TextEditingController();
  TextEditingController controllerEmail = TextEditingController();
  TextEditingController controllerDireccion = TextEditingController();
  TextEditingController controllerNota = TextEditingController();
  TextEditingController controllerNit = TextEditingController();
  TextEditingController controllerLatitud = TextEditingController();
  TextEditingController controllerLongitud = TextEditingController();

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    getListaClientes();
  }

  @override
  void dispose() {
    controllerNombre.dispose();
    controllerCodigo.dispose();
    controllerNit.dispose();
    controllerTelefono.dispose();
    controllerEmail.dispose();
    controllerDireccion.dispose();
    controllerNota.dispose();
    controllerLatitud.dispose();
    controllerLongitud.dispose();
    super.dispose();
  }

  void openCustomDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  Future<void> getListaClientes() async {
    setState(() {
      loadingData = true;
    });
    var clientes =
        await doFetchJSONv2(URL_UM_V2 + ENDPOINTS.OBTENERCLIENTES, {});
    setState(() {
      listaClientes = clientes['body'];
      listaFiltrada = clientes['body'];
      loadingData = false;
    });
    print(listaClientes);
  }

  void limpiarCampos() {
    setState(() {
      controllerNombre.text = "";
      controllerCodigo.text = "";
      controllerNit.text = "";
      controllerTelefono.text = "";
      controllerEmail.text = "";
      controllerDireccion.text = "";
      controllerNota.text = "";
    });
  }

  bool validarCamposObligatorios() {
    return controllerCodigo.text.isNotEmpty && controllerNombre.text.isNotEmpty;
  }

  Future<void> guardarEditarCliente(bool isEditing) async {
    try {
      if (validarCamposObligatorios()) {
        var result = await doFetchJSONv2(
            URL_UM_V2 + ENDPOINTS.COMPROBAREXISTECODIGOCLIENTE,
            {"codigo": controllerCodigo.text});
        bool existeCliente = result?['body']?['cantidad'] > 1;
        if (!existeCliente) {
          var user = await obtenerUsuario();

          if (!isEditing) {
            var nuevoCliente =
                await doFetchJSONv2(URL_UM_V2 + ENDPOINTS.CREARNUEVOCLIENTE, {
              "nombre": controllerNombre.text,
              "codigo": controllerCodigo.text,
              "nit": controllerNit.text,
              "telefono": controllerTelefono.text,
              "email": controllerEmail.text,
              "direccion": controllerDireccion.text,
              "nota": controllerNota.text,
              "createdFrom": 102,
            });

            if (nuevoCliente['code'] == "SUCCESS") {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                      "El CLIENTE se creo exitosamente. Recuerde que tambien debe crear PUNTOS DE INTERES o sucursales para cada cliente.")));
              Navigator.of(context).pop();
              getListaClientes();
            }

            if (createPoi) {
              var result = await doFetchJSONv2(
                  URL_UM_V2 + ENDPOINTS.COMPROBAREXISTECODIGOPUNTOINTERES,
                  {"codigo": controllerCodigo.text});
              bool existePoi = result?['body']?['cantidad'] > 1;
              if (!existePoi) {
                var nuevoPoi = await doFetchJSONv2(
                    URL_UM_V2 + ENDPOINTS.CREARNUEVOPUNTOINTERES, {
                  "idCliente": nuevoCliente['body']?['id'],
                  "nombre": controllerNombre.text,
                  "codigo": controllerCodigo.text,
                  "telefono": controllerTelefono.text,
                  "email": controllerEmail.text,
                  "referenciaDireccion": controllerDireccion.text,
                  "nota": controllerNota.text,
                  "lat": 0,
                  "lng": 0,
                  "coordenadasPoligono": null,
                  "idGeocerca": 0,
                  "meta": null,
                  "idVendedor": 0,
                  "idRegion": 0,
                  "idZona": 0,
                  "createdFrom": 102,
                });
                if (nuevoPoi['code'] == "ERROR") {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          "Ocurrio un error al crear el PUNTO DE INTERES.")));
                }
              }
            }
          } else {
            var edit = await doFetchJSON(URL_UM, {
              'data_op': {
                "token": user['token'],
                "nombre": controllerNombre.text ?? "",
                "nit": controllerNit.text ?? "",
                "telefono": controllerTelefono.text ?? "",
                "email": controllerEmail.text ?? "",
                "direccion": controllerDireccion.text ?? "",
                "nota": controllerNota.text ?? "",
                "codigo": controllerCodigo.text ?? "",
              },
              'op': 'UPDATE-CLIENTEINDIVIDUALDESDEMOVIL'
            });
            if (edit['error'] == false) {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("El cliente se EDITO exitosamente.")));
              Navigator.of(context).pop();
              getListaClientes();
            }
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  "El CODIGO de CLIENTE ya existe. Pruebe con otro codigo.")));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Los campos CODIGO y NOMBRE son OBLIGATORIOS.")));
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> showModalCancelar() async {
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return ConfirmDialog(
              title: "Alerta",
              content:
                  "Confirma que desea DESCARTAR la CREACION/EDICION del punto de interes?",
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
                guardarEditarCliente(false);
              },
              onCancel: () {
                Navigator.of(context).pop();
              });
        });
  }

  Future<void> showModalConfirmarEdicion() async {
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return ConfirmDialog(
              title: "Alerta",
              content:
                  "Confirma que desea EDITAR el cliente? Verifique toda la informacion que ha ingresado",
              confirmButtonText: "Si",
              cancelButtonText: "No",
              onConfirm: () {
                Navigator.of(context).pop();
                guardarEditarCliente(true);
              },
              onCancel: () {
                Navigator.of(context).pop();
              });
        });
  }

  void buscar(String text) {
    try {
      if (text.isNotEmpty) {
        print(text);
        final coincidencias = listaClientes.where((e) {
          return e['codigo']
                  .toString()
                  .toLowerCase()
                  .contains(text.toLowerCase()) ||
              e['nombre'].toString().toLowerCase().contains(text.toLowerCase());
        }).toList();
        setState(() {
          listaFiltrada = coincidencias;
        });
      } else {
        setState(() {
          listaFiltrada = List.from(listaClientes);
        });
      }
    } catch (error) {
      print(error);
    }
  }

  Widget HeaderSection() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: Color(0xFF21203F),
          margin: EdgeInsets.symmetric(vertical: 8),
          padding: EdgeInsets.all(10),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(left: 4),
                  height: 40,
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
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget bottomSheetContent(client) {
    bool isEditing = client != null;
    if (isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            controllerNombre.text = client['nombre'] ?? "";
            controllerCodigo.text = client['codigo'] ?? "";
            controllerNit.text = client['nit'] ?? "";
            controllerTelefono.text = client['telefono'] ?? "";
            controllerEmail.text = client['email'] ?? "";
            controllerDireccion.text = client['direccion'] ?? "";
            controllerNota.text = client['nota'] ?? "";
          });
        }
      });
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: MediaQuery.of(context).viewInsets,
            child: Column(
              children: [
                Text(
                  isEditing ? "EDITAR CLIENTE" : "NUEVO CLIENTE",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w300),
                ),
                Wrap(
                  children: wrappedFields(
                    "Client",
                    controllerNombre,
                    controllerCodigo,
                    controllerTelefono,
                    controllerEmail,
                    controllerDireccion,
                    controllerNota,
                    controllerNit,
                    controllerLatitud,
                    controllerLongitud,
                  )
                      .map((item) => Container(
                            padding: EdgeInsets.all(8),
                            width: MediaQuery.of(context).size.width *
                                item['large'],
                            child: TextField(
                              decoration: InputDecoration(
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
                          ))
                      .toList(),
                ),
                if (!isEditing)
                  StatefulBuilder(
                      builder: (BuildContext context, StateSetter setState) {
                    return CheckboxListTile(
                      title: Text(
                          "Crear tambien un punto de interes con los mismos valores."),
                      value: createPoi,
                      onChanged: (value) {
                        setState(() {
                          createPoi = value!;
                        });
                      },
                    );
                  })
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
                  onPressed: showModalCancelar, child: Text("Cancelar")),
              isEditing
                  ? ElevatedButton(
                      onPressed: showModalConfirmarEdicion,
                      child: Text("Editar"))
                  : ElevatedButton(
                      onPressed: showModalConfirmarGuardado,
                      child: Text("Guardar"))
            ],
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text("CLIENTES"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(FeatherIcons.menu),
          onPressed: openCustomDrawer,
        ),
      ),
      drawer: menuDrawer(context, Screens.CLIENTES),
      body: loadingData
          ? customShimmer()
          : SingleChildScrollView(
              child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: SizedBox()),
                    ElevatedButton(
                        onPressed: () {
                          limpiarCampos();
                          showModalBottomSheet(
                            context: context,
                            isDismissible: false,
                            enableDrag: false,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(16.0),
                              ),
                            ),
                            builder: (BuildContext context) {
                              return WillPopScope(
                                onWillPop: () async {
                                  return false;
                                },
                                child: bottomSheetContent(null),
                              );
                            },
                          );
                        },
                        child: Text("NUEVO CLIENTE")),
                  ],
                ),
                HeaderSection(),
                Divider(),
                Column(
                  children: listaFiltrada
                      .map((item) => Card(
                              child: Container(
                            padding: EdgeInsets.all(8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          "CODIGO: ",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12),
                                        ),
                                        ConstrainedBox(
                                          constraints:
                                              BoxConstraints(maxWidth: 170),
                                          child: Text(
                                            item['codigo']
                                                    .toString()
                                                    .toUpperCase() ??
                                                "",
                                            style: TextStyle(fontSize: 12),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          "NOMBRE: ",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12),
                                        ),
                                        ConstrainedBox(
                                          constraints:
                                              BoxConstraints(maxWidth: 170),
                                          child: Text(
                                            item['nombre']
                                                    .toString()
                                                    .toUpperCase() ??
                                                "",
                                            style: TextStyle(fontSize: 12),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Column(
                                  children: [
                                    ElevatedButton(
                                        onPressed: () {
                                          limpiarCampos();
                                          showModalBottomSheet(
                                            context: context,
                                            isDismissible: false,
                                            enableDrag: false,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.vertical(
                                                top: Radius.circular(16.0),
                                              ),
                                            ),
                                            builder: (BuildContext context) {
                                              return WillPopScope(
                                                  onWillPop: () async {
                                                    return false;
                                                  },
                                                  child:
                                                      bottomSheetContent(item));
                                            },
                                          );
                                        },
                                        child: Text("EDITAR")),
                                    Padding(
                                        padding: EdgeInsets.only(bottom: 2)),
                                    ElevatedButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    GestionarPuntosdeInteres(
                                                      cliente: item,
                                                    )),
                                          );
                                        },
                                        child: Text("VER")),
                                  ],
                                )
                              ],
                            ),
                          )))
                      .toList(),
                ),
              ],
            )),
    );
  }
}
