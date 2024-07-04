import 'package:flutter/material.dart';
import 'package:ultimaMillaFlutter/screen/auth/login_screen.dart';
import 'package:ultimaMillaFlutter/screen/home_screen.dart';
import 'package:ultimaMillaFlutter/screen/not_found_screen.dart';
import 'package:ultimaMillaFlutter/screen/public_screen.dart';

class Routes {
  static final List<String> publicRoutes = [
    '/',
    PublicScreen.routeName,
  ];
  static final List<String> privateRoutes = [];

  static Route<dynamic> generateRoute(RouteSettings settings) {
    String routeName = settings.name!;
    Map<String, String> params = _getParams(settings);

    if (publicRoutes.contains(routeName)) {
      return MaterialPageRoute(
        builder: (_) => _buildPublicRoute(routeName, params),
      );
    }
    if (privateRoutes.contains(routeName)) {
      bool isAuthenticated = false; // Replace with your authentication logic
      if (isAuthenticated == true) {
        return MaterialPageRoute(
          builder: (_) => _buildPrivateRoute(routeName, params),
        );
      }
      if (isAuthenticated == false) {
        return MaterialPageRoute(builder: (_) => LoginScreen());
      }
    }
    return MaterialPageRoute(builder: (_) => const NotFoundScreen());
  }

  static Map<String, String> _getParams(RouteSettings settings) {
    Map<String, String> params = {};
    Uri uri = Uri.parse(settings.name!);
    params.addAll(uri.queryParameters);
    return params;
  }

  static Widget _buildPublicRoute(
      String routeName, Map<String, String> params) {
    switch (routeName) {
      case '/':
        return const HomeScreen();
      case PublicScreen.routeName:
        return const PublicScreen();
      default:
        return const NotFoundScreen();
    }
  }

  static Widget _buildPrivateRoute(
      String routeName, Map<String, String> params) {
    switch (routeName) {
      // do not delete this
      // case AppRoutes.privateScreen:
      //   // Access params as needed (e.g., params['paramName'])
      //   String exampleParam = params['exampleParam'] ?? '';
      //   return PrivateScreen(exampleParam: exampleParam);
      default:
        return const NotFoundScreen();
    }
  }
}
