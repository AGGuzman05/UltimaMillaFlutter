// ignore_for_file: prefer_const_constructors, avoid_print, use_key_in_widget_constructors, library_private_types_in_public_api, prefer_const_literals_to_create_immutables, use_build_context_synchronously

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ultimaMillaFlutter/screen/auth/login_screen.dart';
import 'package:ultimaMillaFlutter/screen/pendientesScreen.dart';
import 'package:ultimaMillaFlutter/services/shared_functions.dart';
import 'package:ultimaMillaFlutter/util/const/base_url.dart';

Future<void> main() async {
  runApp(MyApp());
}

class MyApp extends StatefulWidget with WidgetsBindingObserver {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool loggedIn = false;
  Timer? numeroIntervaloUpdateCredentials;
  AppLifecycleState? _lastLifecycleState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    finalize();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lastLifecycleState = state;
    //_handleAppStateChange(state);
  }

  Future<void> initialize() async {
    var user = await obtenerUsuario();
    setState(() {
      if (user != null) {
        loggedIn = true;
      }
    });

    try {
      // Aquí puedes manejar otros listeners, como notificaciones
      // Example: FirebaseMessaging.onMessage.listen((RemoteMessage message) { ... });
    } catch (err) {
      print('initialize err: $err');
    }
  }

  void finalize() {
    try {
      print("finalize");
      if (numeroIntervaloUpdateCredentials != null) {
        numeroIntervaloUpdateCredentials!.cancel();
      }
    } catch (err) {
      print("finalize err: $err");
    }
  }

  Future<void> updateCredentias() async {
    try {
      numeroIntervaloUpdateCredentials =
          Timer.periodic(Duration(seconds: 30), (timer) async {
        print("updateCredentias");
        if (loggedIn) {
          print("user esta logueado renovar token");
          var usuario = await obtenerUsuario();
          if (usuario != null) {
            var usuarioExiste = await checkUsuarioExiste();
            if (usuarioExiste) {
              await updateToken();
            } else {
              setState(() {
                loggedIn = false;
              });
              await clearUserData();
            }
          }
        }
      });
    } catch (err) {
      print("updateCredentias err: $err");
    }
  }

  Future<void> checkCredentials() async {
    try {
      var usuario = await obtenerUsuario();
      if (usuario != null) {
        var usuarioExiste = await checkUsuarioExiste();
        var corte = await checkTieneCorte();
        if (!usuarioExiste || corte) {
          setState(() {
            loggedIn = false;
          });
          await clearUserData();
        } else {
          await updateWithNoToken();
          updateCredentias();
        }
      }
    } catch (err) {
      print("checkCredentials err: $err");
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          content: Text(err.toString()),
        ),
      );
    }
  }

  Future<bool> checkUsuarioExiste() async {
    try {
      var usuario = await obtenerUsuario();
      var objLogin = {
        'id': usuario['id'],
        'idEmpresa': usuario['idEmpresa'],
      };
      var data = await doFetchJSON(URL_UM, {
        'data_op': objLogin,
        'op': "READ-CHECKUSUARIOEXISTEULTIMAMILLA",
      });
      return !data['error'] && data['data'].isNotEmpty;
    } catch (err) {
      print("checkUsuarioExiste err: $err");
      return false;
    }
  }

  Future<bool> checkTieneCorte() async {
    try {
      var usuario = await obtenerUsuario();
      var objLogin = {
        'idEmpresa': usuario['idEmpresa'],
        'checkConsumoUM': true,
      };
      var data = await doFetchJSON(URL_UM, {
        'data_op': objLogin,
        'op': "READ-CHECKCORTE",
      });
      if (!data['error'] && data['data'].isNotEmpty) {
        var result = data['data'][0];
        return result['corte'] == 1;
      }
      return false;
    } catch (err) {
      print("checkTieneCorte err: $err");
      return false;
    }
  }

  Future<void> updateToken() async {
    try {
      var usuario = await obtenerUsuario();
      var obj = {
        'token': usuario['token'],
        'id': usuario['id'],
      };
      var data = await doFetchJSON(URL_UM, {
        'data_op': obj,
        'op': "CREATE-RENOVARTOKENULTIMAMILLA",
      });
      if (!data['error']) {
        usuario['token'] = data['data'];
        await guardarUsuario(usuario);
      }
    } catch (err) {
      print("updateToken err: $err");
    }
  }

  Future<void> updateWithNoToken() async {
    try {
      var usuario = await obtenerUsuario();
      var obj = {
        'idEmpresa': usuario['idEmpresa'],
        'id': usuario['id'],
      };
      var data = await doFetchJSON(URL_UM, {
        'data_op': obj,
        'op': "CREATE-RENOVARWITHNOTOKENULTIMAMILLA",
      });
      if (!data['error']) {
        usuario['token'] = data['data'];
        await guardarUsuario(usuario);
      }
    } catch (err) {
      print("updateWithNoToken err: $err");
    }
  }
/*
  Future<void> _handleAppStateChange(AppLifecycleState state) async {
    if (_lastLifecycleState == AppLifecycleState.inactive || _lastLifecycleState == AppLifecycleState.paused) {
      if (state == AppLifecycleState.resumed) {
        print("App has come to the foreground!");
        if (loggedIn) {
          updateCredentias();
        }
      } else {
        print("app in background");
        // Manejo de nivel de batería y otras operaciones al ir al fondo
        if (numeroIntervaloUpdateCredentials != null) {
          numeroIntervaloUpdateCredentials!.cancel();
        }
      }
    }
    
    setState(() {
      _lastLifecycleState = state;
    });
  }*/

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: loggedIn ? PendientesScreen() : LoginScreen(),
    );
  }
}
