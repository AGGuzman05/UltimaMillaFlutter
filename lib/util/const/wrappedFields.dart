import 'package:flutter/cupertino.dart';

List<dynamic> wrappedFields(
  String clientOrPOI,
  TextEditingController controllerNombre,
  TextEditingController controllerCodigo,
  TextEditingController controllerTelefono,
  TextEditingController controllerEmail,
  TextEditingController controllerDireccion,
  TextEditingController controllerNota,
  TextEditingController controllerNit,
  TextEditingController controllerLatitud,
  TextEditingController controllerLongitud,
) {
  return [
    {
      "label": "Nombre",
      "controller": controllerNombre,
      "value": controllerNombre.text,
      "large": 0.5,
      "editable": true
    },
    {
      "label": "Codigo",
      "controller": controllerCodigo,
      "value": controllerCodigo.text,
      "large": 0.5,
      "editable": true
    },
    if (clientOrPOI == "Client")
      {
        "label": " NIT",
        "controller": controllerNit,
        "value": controllerNit?.text,
        "large": 0.45,
        "editable": false
      },
    {
      "label": "Telefono",
      "controller": controllerTelefono,
      "value": controllerTelefono.text,
      "large": 0.5,
      "editable": true
    },
    {
      "label": "Email",
      "controller": controllerEmail,
      "value": controllerEmail.text,
      "large": 0.5,
      "editable": true
    },
    {
      "label": " Referencia Direccion",
      "controller": controllerDireccion,
      "value": controllerDireccion.text,
      "large": 1,
      "editable": true
    },
    {
      "label": " Nota",
      "controller": controllerNota,
      "value": controllerNota.text,
      "large": 1,
      "editable": true
    },
    if (clientOrPOI == "POI") ...[
      {
        "label": " Latitud",
        "controller": controllerLatitud,
        "value": null,
        "large": 0.45,
        "editable": false
      },
      {
        "label": " Longitud",
        "controller": controllerLongitud,
        "value": null,
        "large": 0.45,
        "editable": false
      }
    ]
  ];
}
