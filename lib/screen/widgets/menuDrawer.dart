// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:ultimaMillaFlutter/screen/configuracionScreen.dart';
import 'package:ultimaMillaFlutter/screen/gestionarClientesScreen.dart';
import 'package:ultimaMillaFlutter/screen/pendientesScreen.dart';
import 'package:ultimaMillaFlutter/util/const/constants.dart';

Drawer menuDrawer(context, String current) {
  return Drawer(
    child: ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        DrawerHeader(
          decoration: BoxDecoration(
            color: Colors.blue,
          ),
          child: Text(
            'Gestion Ultima Milla', //reemplazar con logo de boltrack
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
            ),
          ),
        ),
        ListTile(
            title: Text('Asignaciones pendientes'),
            onTap: () => {
                  Navigator.pop(context),
                  if (current != Screens.PENDIENTES)
                    {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => PendientesScreen()),
                      )
                    }
                }),
        ListTile(
            title: Text('Gestion de clientes '),
            onTap: () => {
                  Navigator.pop(context),
                  if (current != Screens.CLIENTES)
                    {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => GestionarClientes()),
                      )
                    }
                }),
        ListTile(
            title: Text('Configuracion'),
            onTap: () => {
                  Navigator.pop(context),
                  if (current != Screens.CONFIGURACION)
                    {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ConfiguracionScreen()),
                      )
                    }
                }),
      ],
    ),
  );
}
