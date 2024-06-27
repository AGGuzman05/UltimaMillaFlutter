// ignore_for_file: constant_identifier_names, prefer_const_constructors
import "package:flutter/material.dart";

class CustomColors {
  static const BoltrackMenuBlue = Color(0xFF00467A);
  static const BoltrackLogoBlue = Color(0xFF1F69AD);
  static const Naranja = Color(0xFFF2A20C);
  static const OrangeLight = Color(0xFFFFB74D);
  static const Orange = Color(0xFFE69F35);
  static const ColorOperation = Color(0xFF236D75);
  static const TransparentWhite = Color.fromRGBO(255, 255, 255, 0.5);
  static const Teal = Color(0xFF4DAB8C);
  static const Wine = Color(0xFF721A2F);
  static const Gris = Color(0xFFA0A0A0);
  static const Blue1 = Color(0xFF113A5F);
  static const Blue3 = Color(0xFF1A5993);
  static const Blue4 = Color(0xFF63A6E3);
  static const BlueDarken = Color(0xFF091D30);
  static const GreenBaseFigma = Color(0xFF84B044);
  static const RedFigma = Color(0xFFF23838);
  static const Yellow = Color(0xFFECF22C);
  static const Yellow2 = Color(0xFFF9C80E);
  static const GreyDarken = Color(0xFF212529);
  static const BlueLigthFigma = Color(0xFFF2F8FD);
  static const backgroundColorFigma = Color(0xFFFBFDFE);
  static const AmarilloBoltrack = Color(0xFFFFC107);
  static const VerdeBoltrack = Color(0xFF4DBD74);
  static const GreyDarkenFigma = Color(0xFF444D55);
  static const GreenGenerarHistoricoDiario = Color(0xFF84B044);
  static const GreenGenerarHistoricoDiario2 = Color(0xFF84B044);
  static const WhiteGenerarHistoricoDiario = Color(0xFFFBFDFE);
  static const darkGreen = Color(0xFF042412);
  static const skyblue = Color(0xFF0CB8F2);
  static const black = Color(0xFF0F0F0F);
  static const YellowArrow = Color(0xFFDBAE02);
  static const aqua = Color(0xFFD4EAFF);
  static const lemon = Color(0xFFFBE2B9);
  static const background = Color(0xFFF2F2F2);
}

class CustomStyles {
  static final padded = EdgeInsets.all(20);

  static final titulo = TextStyle(
    color: Colors.black,
    //textAlign: TextAlign.center,
    fontSize: 30,
    fontWeight: FontWeight.bold,
  );

  static final parrafo = TextStyle(
    //textAlign: TextAlign.left,
    fontSize: 16,
    //paddingLeft: 30,
  );

  static final botonCentrado = ButtonStyle(
    backgroundColor: MaterialStateProperty.all<Color>(Colors.grey),
    padding: MaterialStateProperty.all<EdgeInsets>(EdgeInsets.all(10)),
  );

  static final separador = BoxDecoration(
    border: Border(bottom: BorderSide(width: 1)),
  );

  static final rowModalHeaderSeguimiento = BoxDecoration(
    borderRadius: BorderRadius.circular(5),
    //flexShrink: 1,
    //marginBottom: 8,
    //padding: EdgeInsets.all(8),
    color: CustomColors.backgroundColorFigma,
  );

  static final rowModalBodySeguimiento = BoxDecoration(
      //flex: 1,
      //padding: EdgeInsets.all(width * 0.1),
      //justifyContent: 'center',
      //maxHeight: height * 0.75,
      //marginTop: height * 0.15,
      );

  static final modalSeguimiento = BoxDecoration(
    //flex: 1,
    //justifyContent: 'center',
    color: Colors.black.withOpacity(0.4),
  );

  static final cardStyle = BoxDecoration(
    //flexDirection: 'row',
    //width: width * 0.93,
    //backgroundColor: CustomColors.BlueLigthFigma,
    //alignSelf: 'center',
    //justifyContent: 'center',
    //elevation: 2,
    //paddingTop: 30,
    //marginBottom: 20,
    //paddingBottom: 30,
    borderRadius: BorderRadius.circular(10),
  );
}
