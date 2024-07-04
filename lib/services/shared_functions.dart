// ignore_for_file: avoid_print, prefer_interpolation_to_compose_strings, unnecessary_type_check, prefer_is_not_operator

import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:ultimaMillaFlutter/util/const/sharedpreferences_key.dart';

class SharedFunctions {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  deleteSharedPreferenceData() async {
    final SharedPreferences prefs = await _prefs;
    prefs.remove(SharedPreferencesKey.token);
    prefs.remove(SharedPreferencesKey.name);
    prefs.remove(SharedPreferencesKey.lastName);
  }
}

Future<void> storeObject(String key, dynamic obj) async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (obj is Map || obj is List) {
      String jsonStr = json.encode(obj);
      await prefs.setString(key, jsonStr);
    } else {
      print("Intentando guardar un no-objeto con storeObject");
    }
  } catch (e) {
    print(e);
  }
}

Future<void> storeString(String key, dynamic obj) async {
  if (obj is! String) {
    print("intentando guardar un no-string " + jsonEncode(obj));
  }
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString(key, obj);
}

Future<void> guardarUsuario(dynamic userData) async {
  try {
    if (userData is! Map) {
      //print("Error al registrar el usuario: $userData");
      return;
    }
    await storeObject(KEYS.userdata, userData);
  } catch (e) {
    print(e);
  }
}

Future<dynamic> obtenerUsuario() async {
  try {
    dynamic userdata = await getObjectOrNull(KEYS.userdata);
    if (userdata == null) return {};
    return userdata['data'][0];
  } catch (e) {
    print(e);
    return null;
  }
}

Future<dynamic> doFetchJSON(String url, dynamic data,
    [String method = "POST"]) async {
  try {
    Uri uri = Uri.parse(url);
    Map<String, String> headers = {
      "Content-Type": "application/json",
    };

    http.Response response;

    if (method == "GET" || method == "HEAD") {
      if (data != null && data.isNotEmpty) {
        print("OBJETO DATA TIENE QUE SER VACIO SI METHOD=GET/HEAD");
        print(data);
      }
      data = null; // No enviar body para GET/HEAD
      if (method == "GET") {
        response = await http.get(uri, headers: headers);
      } else {
        response = await http.head(uri, headers: headers);
      }
    } else if (method == "POST") {
      response = await http.post(
        uri,
        headers: headers,
        body: data != null ? jsonEncode(data) : null,
      );
    } else {
      throw Exception('Unsupported HTTP method');
    }
    return jsonDecode(response.body);
  } catch (err) {
    print('doFetchJSON err');
    print(err);
    return {"error": true, "exception": err.toString()};
  }
}

Future<Map<String, String>> getHeaders(
    {Map<String, dynamic> config = const {}}) async {
  final Map<String, String> HEADERS = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  final bool authenticate =
      config.containsKey('authenticate') ? config['authenticate'] : false;

  if (authenticate) {
    final usuario = await obtenerUsuario();
    final String token = usuario['body']['token'] as String;

    if ((token is! String)) {
      throw Exception('missing bearer token');
    }
    return {
      ...HEADERS,
      'Authorization': 'Bearer $token',
    };
  }

  return HEADERS;
}

Future<void> clearUserData() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(KEYS.userdata);
  } catch (error) {
    print(error);
  }
}

Future<String?> getStringOrNull(String key) async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  } catch (e) {
    print("Error getting string from SharedPreferences: $e");
    return null;
  }
}

Future<dynamic> getObjectOrNull(String key) async {
  String? storedObj = await getStringOrNull(key);
  if (storedObj != null) {
    return json.decode(storedObj);
  } else {
    return null;
  }
}

String getKilometros(dynamic lat1, dynamic lon1, dynamic lat2, dynamic lon2) {
  print(lat1);
  print(lat2);
  try {
    const double R = 6378.137; // Radio de la tierra en km
    double dLat = rad(lat2 - lat1);
    double dLong = rad(lon2 - lon1);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(rad(lat1)) * cos(rad(lat2)) * sin(dLong / 2) * sin(dLong / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double d = R * c;
    if (d > 1000) {
      return "Distancia no definida";
    } else {
      return d.toStringAsFixed(2) + " KM"; // Retorna dos decimales
    }
  } catch (e) {
    print(e);
    return "No se pudo calcular ruta";
  }
}

double rad(double x) {
  return x * pi / 180;
}

class KEYS {
  static const String expotoken = "S_EXPO_TOKEN_KEY_ULTIMA_MILLA";
  static const String userdata = "O_USERDATA_ULTIMA_MILLA";
  static const String subestado = "D_SUBESTADO_ULTIMA_MILLA";
  static const String detallePuntoEntrega =
      "D_DETALLE_PUNTO_ENTREGA_ULTIMA_MILLA";
  static const String ordenesCompletadas = "D_ORDENES_COMPLETADAS_ULTIMA_MILLA";
  static const String pedidosMarcados = "PEDIDOS_MARCADOS_ULTIMAMILLA";
  static const String liberarDeAsignacion = "LIBERAR_DE_ASIGNACION_ULTIMAMILLA";
  static const String pedidosNoTerminados = "PEDIDOS_NO_TERMINADOS";
}
