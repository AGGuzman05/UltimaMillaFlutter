// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ultimaMillaFlutter/services/shared_functions.dart';

Future<dynamic> obtenerGeocercaConductoresCBN() async {
  try {
    print("ObtenerGeocerca");
    final usuario = await obtenerUsuario();
    final data_op = {"token": usuario['body']['token']};
    print(data_op);
    final op = "READ-COMBOGEOCERCACODIGO";

    final response = await http.post(
      Uri.parse("https://gestiondeflota.boltrack.net/api/datos"),
      headers: {
        "Content-Type": "application/json",
      },
      body: json.encode({"data_op": data_op, "op": op}),
    );

    var geocercas = [];
    if (jsonDecode(response.body)['error'] == false) {
      var data = jsonDecode(response.body)['data'];
      geocercas = data.where((geocerca) {
        return geocerca.containsKey('nombre') &&
            !geocerca['nombre'].toLowerCase().contains('dock') &&
            !geocerca['nombre'].toLowerCase().contains('tyt');
      }).toList();
      geocercas.add({"nombre": "OTRO", "id": -1});
    }
    return geocercas;
  } catch (err) {
    print("ObtenerGeocerca err");
    print(err);
    return [];
  }
}
