// ignore_for_file: prefer_const_declarations, prefer_const_constructors, use_build_context_synchronously, deprecated_member_use

import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:ultimaMillaFlutter/screen/auth/login_screen.dart';
import 'package:ultimaMillaFlutter/screen/widgets/menuDrawer.dart';
import 'package:ultimaMillaFlutter/services/shared_functions.dart';
import 'package:ultimaMillaFlutter/util/const/constants.dart';
import 'package:url_launcher/url_launcher.dart';

class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  String googlePlayVersion = "Cargando...";
  String localVersion = Constants.apkVersion;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void openCustomDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  @override
  void initState() {
    super.initState();
    _getLatestVersion();
  }

  void _getLatestVersion() async {
    String url =
        'https://google-play-store-scraper-api.p.rapidapi.com/app-details';

    Map<String, String> headers = {
      'x-rapidapi-key': 'f82224c278mshca06063e87609a0p1b6cf7jsn428eaa5530c7',
      'x-rapidapi-host': 'google-play-store-scraper-api.p.rapidapi.com',
      'Content-Type': 'application/json'
    };

    Map<String, dynamic> body = {
      'language': 'en',
      'country': 'us',
      'appID': 'bo.com.boltrack.ultimamilla'
    };

    try {
      var response = await http.post(Uri.parse(url),
          headers: headers, body: jsonEncode(body));

      if (response.statusCode == 200) {
        var result = jsonDecode(response.body);
        setState(() {
          googlePlayVersion = result['data']['version'];
        });
        if (googlePlayVersion != "Cargando..." &&
            localVersion.toString() != googlePlayVersion.toString()) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                content: Text("Hay una actualizacion disponible"),
                actions: [
                  TextButton(
                    child: Text("OK"),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        }
      } else {
        print('Request failed with status: ${response.statusCode}');
      }
    } catch (error) {
      print('Error: $error');
    }
  }

  goToStore() async {
    String url =
        "https://play.google.com/store/apps/details?id=bo.com.boltrack.ultimamilla&pcampaignid=web_share";
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not open the map.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text("CONFIGURACION"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(FeatherIcons.menu),
          onPressed: openCustomDrawer,
        ),
      ),
      drawer: menuDrawer(context, Screens.CONFIGURACION),
      body: Center(
        child: Column(
          children: [
            Padding(padding: EdgeInsets.symmetric(vertical: 20)),
            Text(
              "Version: $localVersion",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            if (!kIsWeb)
              if (Platform.isAndroid)
                if (googlePlayVersion != "Cargando..." &&
                    localVersion.toString() != googlePlayVersion.toString())
                  ElevatedButton(
                      onPressed: goToStore,
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text("ACTUALIZAR APP"),
                          SizedBox(
                            width: 12,
                          ),
                          Icon(Icons.upload)
                        ],
                      )),
            Padding(padding: EdgeInsets.symmetric(vertical: 7)),
            ElevatedButton(
                onPressed: () async {
                  await clearUserData();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text("CERRAR SESION"),
                    SizedBox(
                      width: 12,
                    ),
                    Icon(Icons.logout)
                  ],
                )),
          ],
        ),
      ),
    );
  }
}
