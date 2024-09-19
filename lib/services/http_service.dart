import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ultimaMillaFlutter/model/api_result.dart';
import 'package:ultimaMillaFlutter/util/const/api_string_code.dart';
import 'package:ultimaMillaFlutter/util/const/parametroConexion.dart';
import 'package:ultimaMillaFlutter/util/const/sharedpreferences_key.dart';

class HttpService {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  // HttpService({required this.baseUrl});

  Future<dynamic> get(String endpoint) async {
    final response = await http.get(Uri.parse('$URL_UM/$endpoint'));
    return _handleResponse(response);
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic>? data) async {
    final response = await http.post(
      Uri.parse('$URL_UM/$endpoint'),
      body: data != null ? json.encode(data) : null,
      // headers: {'Content-Type': 'application/json', },
      headers: await getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$URL_UM/$endpoint'),
      body: data,
      headers: {'Content-Type': 'application/json'},
    );
    return _handleResponse(response);
  }

  ApiResult _handleResponse(http.Response response) {
    ApiResult apiResult = ApiResult(
      success: false,
    );
    try {
      final body = Body.fromMap(json.decode(response.body));
      if (response.statusCode == 400) {
        apiResult.body = body;
        return apiResult;
      }
      if (response.statusCode == 200) {
        apiResult.success = true;
        apiResult.body = body;
      } else {
        throw Exception('Error en la solicitud HTTP: ${response.statusCode}');
      }
      return apiResult;
    } catch (err) {
      // print('_handleResponse err');
      // print(err.toString());
      Body body = Body(status: ApiStringCode.failure, message: err.toString());
      apiResult.body = body;
      return apiResult;
    }
  }

  Future<Map<String, String>> getHeaders() async {
    final SharedPreferences prefs = await _prefs;
    String? token = prefs.getString(SharedPreferencesKey.token);
    Map<String, String> header = {
      'Content-Type': 'application/json',
    };
    if (token != null) {
      header['Authorization'] = "Bearer $token";
    }
    // print('header');
    // print(header);
    return header;
  }
}
