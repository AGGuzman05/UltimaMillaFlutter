// ignore: constant_identifier_names
// ignore_for_file: constant_identifier_names, duplicate_ignore

const String URL_UM =
    'https://gestiondeflota.boltrack.net/apiUltimaMilla/datos';
const String URL_UM_V2 =
    'https://gestiondeflota.boltrack.net/apiultimamillav2/api/';
const String URL_GESTION = "https://gestiondeflota.boltrack.net/api/datos";

class ENDPOINTS {
  static const String OBTENERCLIENTES = "/cliente/obtener-lista-clientes";
  static const String COMPROBAREXISTECODIGOCLIENTE =
      "/cliente/obtener-cantidad-cliente-por-codigo";
  static const String CREARNUEVOCLIENTE = "/cliente/guardar-cliente";
  static const String COMPROBAREXISTECODIGOCLIENTEYPUNTOINTERES =
      "/cliente/obtener-cantidad-cliente-y-punto-interes-por-codigo ";
  static const String OBTENERPUNTOSDEINTERESPORCLIENTE =
      "/punto-interes/obtener-punto-interes-por-id-cliente";
  static const String COMPROBAREXISTECODIGOPUNTOINTERES =
      "/punto-interes/cantidad-punto-interes-por-codigo";
  static const String CREARNUEVOPUNTOINTERES =
      "/punto-interes/guardar-punto-interes";
}
