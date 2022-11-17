import 'dart:isolate';

import '../models/client.dart';
import '../models/facture.dart';
import '../models/operation.dart';
import '../services/native_db_helper.dart';

class ForegroundIsolate {
  static void readFacturePendingOnIsolate(SendPort port) async {
    try {
      var allFactures = await NativeDbHelper.rawQuery(
          "SELECT * FROM factures INNER JOIN clients ON factures.facture_client_id = clients.client_id WHERE factures.facture_statut = 'en cours' AND NOT factures.facture_state='deleted' ORDER BY factures.facture_id DESC");

      if (allFactures != null) {
        List<Facture> tempsList = <Facture>[];
        for (var e in allFactures) {
          await Future.delayed(const Duration(microseconds: 1000));
          tempsList.add(Facture.fromMap(e));
        }
        port.send(tempsList);
      }
    } catch (e) {}
  }

  static void readInventoriesFromForeground(List<dynamic> args) async {
    SendPort sendPort = args.first;
    List<Operations> tempsList = <Operations>[];
    for (var e in args.last) {
      await Future.delayed(const Duration(microseconds: 1000));
      tempsList.add(Operations.fromMap(e));
    }
    sendPort.send(tempsList);
  }

  static void readFilteredFactureFromForeground(List<dynamic> args) async {
    SendPort sendPort = args.first;
    List<Facture> temps = <Facture>[];
    for (var e in args.last) {
      await Future.delayed(const Duration(microseconds: 1000));
      temps.add(Facture.fromMap(e));
    }
    sendPort.send(temps);
  }

  static void readClientsFromIsolate(SendPort port) async {
    var allClients = await NativeDbHelper.rawQuery(
        "SELECT * FROM clients WHERE NOT client_state ='deleted' ORDER BY client_id DESC");
    if (allClients != null) {
      List<Client> tempsList = <Client>[];
      for (var e in allClients) {
        await Future.delayed(const Duration(microseconds: 1000));
        tempsList.add(Client.fromMap(e));
      }
      port.send(tempsList);
    }
  }

  static void readPaiesFromIsolate(List<dynamic> args) async {
    SendPort port = args.first;
    List<Operations> tempsList = <Operations>[];
    for (var e in args.last) {
      await Future.delayed(const Duration(microseconds: 1000));
      tempsList.add(Operations.fromMap(e));
    }
    port.send(tempsList);
  }
}
