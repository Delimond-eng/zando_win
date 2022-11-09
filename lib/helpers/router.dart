import 'package:flutter/material.dart';
import 'package:zando_m/global/controllers.dart';
import 'package:zando_m/pages/factures.dart';
import 'package:zando_m/pages/stockages.dart';
import 'package:zando_m/pages/treasures.dart';
import '../pages/dashboard.dart';
import '../pages/clients.dart';
import '../pages/paiements.dart';
import '../pages/inventories.dart';
import '../pages/users.dart';

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case "/":
      if (!authController.checkUser) {
        return _getPageRoute(const Stockages());
      }
      return _getPageRoute(const DashBoard());
      break;
    case "/clients":
      return _getPageRoute(const Clients());
    case "/paiements":
      return _getPageRoute(const Paiements());
    case "/inventories":
      return _getPageRoute(const Inventories());
    case "/treasures":
      return _getPageRoute(const Treasures());
    case "/factures":
      return _getPageRoute(const Factures());
    case "/users":
      return _getPageRoute(const Users());
    case "/stocks":
      return _getPageRoute(const Stockages());
    default:
      return _getPageRoute(const DashBoard());
  }
}

PageRoute _getPageRoute(Widget child) {
  return SlideRightRoute(page: child);
}

class SlideRightRoute extends PageRouteBuilder {
  final Widget page;
  SlideRightRoute({this.page})
      : super(
          pageBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) =>
              page,
          transitionsBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) =>
              SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(5, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
}
