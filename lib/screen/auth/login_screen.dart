// ignore_for_file: avoid_print, use_build_context_synchronously, use_key_in_widget_constructors, library_private_types_in_public_api, prefer_const_constructors

import 'dart:async';
import 'dart:convert';
import 'package:ultimaMillaFlutter/screen/pendientesScreen.dart';
import 'package:ultimaMillaFlutter/util/const/base_url.dart';
import 'package:ultimaMillaFlutter/util/const/constants.dart';
import 'package:ultimaMillaFlutter/util/const/shared_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:ultimaMillaFlutter/services/shared_functions.dart';

class LoginScreen extends StatefulWidget {
  static const routeName = '/LoginScreen';
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _username = "";
  String _password = "";
  bool passwordVisible = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  Future<Map<String, dynamic>> _login(
      String usuario, String contrasenia) async {
    try {
      var body = {
        'data_op': {
          'usuario': usuario,
          'password': contrasenia,
        },
        'op': 'READ-COMPROBARLOGINULTIMAMILLA',
      };
      var response = await doFetchJSON(URL_UM, body);
      print(jsonEncode(body));
      print(response);

      if (response['error'] == false) {
        return response;
      } else {
        return {'error': true};
      }
    } catch (err, stackTrace) {
      print("login err");
      print(err);
      print(stackTrace);
      return {'error': true};
    }
  }

  Future<void> _validarFormulario() async {
    try {
      if (_username.isEmpty) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Alerta"),
              content: const Text("El campo Usuario es obligatorio"),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("OK"),
                ),
              ],
            );
          },
        );
        return;
      }
      if (_password.isEmpty) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Alerta"),
              content: const Text("El campo Password es obligatorio"),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("OK"),
                ),
              ],
            );
          },
        );
        return;
      }

      setState(() {
        _username = _username.trim();
        _password = _password.trim();
      });
      final response = await _login(_username, _password);
      print(response);
      if (response['error'] == false) {
        await guardarUsuario(response);
        Map usuario = await obtenerUsuario();
        if (usuario.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PendientesScreen()),
          );
        }
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Alerta"),
              content: const Text("Contraseña Incorrecta ó Usuario Inválido"),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("OK"),
                ),
              ],
            );
          },
        );
      }
    } catch (err, stacktrace) {
      print("LoginScreen validarFormulario err");
      print(err);
      print(stacktrace);
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Error"),
            content: Text(err.toString()),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SingleChildScrollView(
          child: Container(
            height: MediaQuery.of(context).size.height,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/backgroundPicture.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  margin: EdgeInsets.all(7),
                  padding: EdgeInsets.all(5),
                  decoration: BoxDecoration(
                      color: CustomColors.BoltrackMenuBlue.withOpacity(0.7),
                      borderRadius: BorderRadius.all(Radius.circular(12))),
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/blogo.png',
                        width: MediaQuery.of(context).size.width * 0.8,
                        height: MediaQuery.of(context).size.height * 0.15,
                      ),
                      const Text(
                        'GESTION \n ULTIMA MILLA',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Montserrat',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 15),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            TextField(
                              style: TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'Usuario:',
                                labelStyle: TextStyle(
                                    color: Colors.white, fontSize: 18),
                                prefixIcon: Icon(
                                  FeatherIcons.user,
                                  color: Colors.white,
                                ),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _username = value;
                                });
                              },
                            ),
                            TextField(
                              style: TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Contraseña:',
                                labelStyle: TextStyle(
                                    color: Colors.white, fontSize: 18),
                                prefixIcon: Icon(
                                  FeatherIcons.lock,
                                  color: Colors.white,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    passwordVisible
                                        ? FeatherIcons.eyeOff
                                        : FeatherIcons.eye,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      passwordVisible = !passwordVisible;
                                    });
                                  },
                                ),
                              ),
                              obscureText: !passwordVisible,
                              onChanged: (value) {
                                setState(() {
                                  _password = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ButtonStyle(
                            elevation: MaterialStateProperty.all(7),
                            backgroundColor: MaterialStateColor.resolveWith(
                                (states) =>
                                    CustomColors.GreenGenerarHistoricoDiario2)),
                        onPressed: /*_cargandoLogin ? null :*/
                            _validarFormulario,
                        child: const Text(
                          'INICIAR SESION',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.all(7),
                        child: Text(
                          "Version ${Constants.appVersion}",
                          style: TextStyle(fontSize: 14, color: Colors.white),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
