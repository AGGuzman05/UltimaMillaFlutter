// ignore_for_file: constant_identifier_names

class Constants {
  static const String appVersion = "2.0.2";
  static const int BATERIA = 95;
  static const int ULTIMA_MILLA = 97;
}

class SubEntregado {
  static const int ENTREGA_EXITOSA = 1;
}

class SubNoEntregado {
  static const int TIENDA_CERRADA = 39;
  static const int SIN_EFECTIVO = 40;
  static const int NO_HIZO_PEDIDO = 41;
  static const int PRODUCTO_FALTANTE = 42;
  static const int FALTO_TIEMPO = 43;
  static const int ENCARGADO_AUSENTE = 44;
  static const int PRODUCTO_DANIADO = 45;
  static const int DIRECCION_NO_UBICADA = 46;
  static const int OTRO = 47;
}

class SubEntregaParcial {
  static const FALTA_PRODUCTO = 31;
  static const ERROR_PEDIDO = 32;
  static const PRODUCTO_DANIADO = 33;
  static const FALTA_EFECTIVO = 34;
  static const PRODUCTO_FALTANTE = 35;
  static const QUIEBRE_STOCK = 36;
  static const OTRO = 37;
}

class SubEnPausa {
  static const EN_PAUSA = 93;
}

const int PENDIENTE_ENTREGA = 21;
const int EN_RUTA = 22;
const int ENTREGADO = 23;
const int ENTREGA_PARCIAL = 24;
const int NO_ENTREGADO_RECHAZADO = 25;
const int EN_PAUSA = 88;
const String SELECCIONAR_ESTADO = "SELECCIONAR ESTADO";
const String SELECCIONAR_SUB_ESTADO = "SELECCIONAR SUB ESTADO";

const int MADISA = 7882;
const int MADISALP = 6345;
const int MADISACBBA = 6346;
const int MADISASC = 6347;
const int VETERQUIMICA = 3207;
const int VINOSKOHLBERG = 8148;

const int FOTO_VIEW = 1;
const int QUIEN_RECIBE_VIEW = 2;
const int FIRMA_VIEW = 3;
const int ESTADO_PAGO_VIEW = 4;

const int PREGUNTA_QUIEN_RECIBE = 50;
const int CLIENTE = 51;
const int FAMILIAR = 52;
const int CONSERJE = 53;
const int OTRO_RECIBE = 54;

const int PREGUNTA_ESTADO_PAGO = 55;
const int PAGADO_A_TIENDA = 56;
const int PAGADO_A_CONDUCTOR = 57;
const int PENDIENTE_PAGO = 58;
const int CREDITO = 89;
const int TRANSFERENCIA = 90;
const int OTRO_PAGO = 91;

const int PREGUNTA_FOTOGRAFIA = 59;
const int FOTOGRAFIA = 60;

const int PREGUNTA_FIRMA = 61;
const int FIRMA = 62;
