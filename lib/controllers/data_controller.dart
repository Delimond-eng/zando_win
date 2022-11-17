import 'dart:isolate';

import 'package:get/get.dart';
import 'package:zando_m/models/operation.dart';
import 'package:zando_m/reports/models/daily_count.dart';
import 'package:zando_m/reports/report.dart';

import '../global/foreground_task.dart';
import '../global/utils.dart';
import '../models/client.dart';
import '../models/compte.dart';
import '../models/currency.dart';
import '../models/facture.dart';
import '../models/user.dart';
import '../reports/models/dashboard_count.dart';
import '../services/db_helper.dart';
import '../services/native_db_helper.dart';
import '../services/synchonisation.dart';

class DataController extends GetxController {
  static DataController instance = Get.find();
  var users = <User>[].obs;
  var factures = <Facture>[].obs;
  var filteredFactures = <Facture>[].obs;
  var clients = <Client>[].obs;
  var clientFactures = <Client>[].obs;
  var comptes = <Compte>[].obs;
  var allComptes = <Compte>[].obs;
  var currency = Currency().obs;
  var dashboardCounts = <DashboardCount>[].obs;
  var dailySums = <DailyCount>[].obs;
  var paiements = <Operations>[].obs;
  var paiementDetails = <Operations>[].obs;
  var inventories = <Operations>[].obs;
  var daySellCount = 0.0.obs;
  var dataLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    refreshDatas();
  }

  Future<void> refreshDatas() async {
    refreshCurrency();
    loadActivatedComptes();
    loadClients();
  }

  //* Load all users list*//
  loadUsers() async {
    var db = await DbHelper.initDb();
    var userData = await db.query("users");
    if (userData != null) {
      users.clear();
      for (var e in userData) {
        users.add(User.fromMap(e));
      }
      users.removeWhere((user) => user.userName.contains("ad"));
    }
  }

  Future loadFilterFactures(String key) async {
    ReceivePort receivePort = ReceivePort();
    try {
      var query;
      if (key == "all") {
        query = await NativeDbHelper.rawQuery(
            "SELECT * FROM factures INNER JOIN clients ON factures.facture_client_id = clients.client_id WHERE NOT factures.facture_state='deleted' ORDER BY factures.facture_id DESC");
      }
      if (key == "pending") {
        query = await NativeDbHelper.rawQuery(
            "SELECT * FROM factures INNER JOIN clients ON factures.facture_client_id = clients.client_id WHERE factures.facture_statut = 'en cours' OR factures.facture_statut = 'en attente'  AND NOT factures.facture_state='deleted' ORDER BY factures.facture_id DESC");
      }

      if (key == "completed") {
        query = await NativeDbHelper.rawQuery(
            "SELECT * FROM factures INNER JOIN clients ON factures.facture_client_id = clients.client_id WHERE factures.facture_statut='paie' AND NOT factures.facture_state='deleted' ORDER BY factures.facture_id DESC");
      }

      if (query != null) {
        final isolate = await Isolate.spawn(
            ForegroundIsolate.readFilteredFactureFromForeground,
            [receivePort.sendPort, query]);
        final list = await receivePort.first;
        filteredFactures.clear();
        filteredFactures.addAll(list);
        isolate.kill(priority: Isolate.immediate);
      }
    } catch (e) {}
    return "end";
  }

  refreshDashboardCounts() async {
    var counts = await Report.getCount();
    dashboardCounts.clear();
    await Future.delayed(const Duration(milliseconds: 100));
    dashboardCounts.addAll(counts);
  }

  refreshDayCompteSum() async {
    var sums = await Report.getDayAccountSums();
    dailySums.clear();
    await Future.delayed(const Duration(milliseconds: 100));
    dailySums.addAll(sums);
  }

  refreshCurrency() async {
    var db = await DbHelper.initDb();
    var taux = await db.query("currencies");
    if (taux.isNotEmpty) {
      currency.value = Currency.fromMap(taux.first);
    } else {
      editCurrency();
    }
  }

  countDaySum() async {
    var s = await Report.dayAll();
    daySellCount.value = s;
  }

  Future loadFacturesEnAttente() async {
    ReceivePort receivePort = ReceivePort();
    try {
      final isolate = await Isolate.spawn(
          ForegroundIsolate.readFacturePendingOnIsolate, receivePort.sendPort);
      final list = await receivePort.first;
      factures.clear();
      factures.addAll(list);
      isolate.kill(priority: Isolate.immediate);
    } catch (e) {}
    return "end";
  }

  Future loadClients() async {
    ReceivePort receivePort = ReceivePort();
    try {
      final isolate = await Isolate.spawn(
          ForegroundIsolate.readClientsFromIsolate, receivePort.sendPort);
      final list = await receivePort.first;
      clients.clear();
      clients.addAll(list);
      isolate.kill(priority: Isolate.immediate);
    } catch (e) {}

    return "end";
  }

  Future loadPayments(String key, {int field}) async {
    ReceivePort receivePort = ReceivePort();
    switch (key) {
      case "all":
        var query = await NativeDbHelper.rawQuery(
          "SELECT SUM(operations.operation_montant) AS totalPay, * FROM factures INNER JOIN operations ON factures.facture_id = operations.operation_facture_id INNER JOIN clients ON factures.facture_client_id = clients.client_id WHERE NOT operations.operation_state='deleted' GROUP BY operations.operation_facture_id ORDER BY operations.operation_facture_id DESC",
        );
        if (query != null) {
          final isolate = await Isolate.spawn(
              ForegroundIsolate.readPaiesFromIsolate,
              [receivePort.sendPort, query]);
          final list = await receivePort.first;
          paiements.clear();
          paiements.addAll(list);
          isolate.kill(priority: Isolate.immediate);
        }
        break;
      case "details":
        var query = await NativeDbHelper.rawQuery(
          "SELECT SUM(operations.operation_montant) AS totalPay, * FROM factures INNER JOIN operations ON factures.facture_id = operations.operation_facture_id INNER JOIN clients ON factures.facture_client_id = clients.client_id WHERE NOT operations.operation_state='deleted' GROUP BY operations.operation_facture_id ORDER BY operations.operation_id DESC",
        );
        if (query != null) {
          final isolate = await Isolate.spawn(
              ForegroundIsolate.readPaiesFromIsolate,
              [receivePort.sendPort, query]);
          final list = await receivePort.first;

          isolate.kill(priority: Isolate.immediate);

          var strDate = dateToString(parseTimestampToDate(field));
          var filtersList =
              list.where((op) => op.operationDate.contains(strDate));
          paiements.clear();
          paiements.addAll(filtersList);
        }
        break;
      case "date":
        var query = await NativeDbHelper.rawQuery(
          "SELECT SUM(operations.operation_montant) AS totalPay, * FROM factures INNER JOIN operations ON factures.facture_id = operations.operation_facture_id INNER JOIN clients ON factures.facture_client_id = clients.client_id WHERE NOT operations.operation_state='deleted' GROUP BY operations.operation_facture_id ORDER BY operations.operation_facture_id DESC",
        );
        if (query != null) {
          final isolate = await Isolate.spawn(
              ForegroundIsolate.readPaiesFromIsolate,
              [receivePort.sendPort, query]);
          final list = await receivePort.first;

          isolate.kill(priority: Isolate.immediate);
          paiements.clear();
          paiements.addAll(list);
          var strDate = dateToString(parseTimestampToDate(field));
          var p = paiements
              .where((e) => e.operationDate.contains(strDate))
              .toList();
          paiements.clear();
          paiements.addAll(p);
          break;
        }
    }
    return "end";
  }

  Future showPaiementDetails(int factureId) async {
    ReceivePort receivePort = ReceivePort();
    var query = await NativeDbHelper.rawQuery(
        "SELECT * FROM factures INNER JOIN operations ON factures.facture_id = operations.operation_facture_id INNER JOIN clients ON factures.facture_client_id = clients.client_id WHERE NOT operations.operation_state='deleted' AND operations.operation_facture_id = $factureId");
    if (query != null) {
      final isolate = await Isolate.spawn(
          ForegroundIsolate.readPaiesFromIsolate,
          [receivePort.sendPort, query]);
      final list = await receivePort.first;
      paiementDetails.clear();
      paiementDetails.addAll(list);
      isolate.kill(priority: Isolate.immediate);
    }
    return "end";
  }

  Future loadInventories(String fword, {fkey}) async {
    ReceivePort receivePort = ReceivePort();
    try {
      switch (fword) {
        case "all":
          var query = await NativeDbHelper.rawQuery(
              "SELECT SUM(operations.operation_montant) AS totalPay, * FROM operations INNER JOIN comptes on operations.operation_compte_id = comptes.compte_id WHERE NOT operations.operation_state='deleted' GROUP BY operations.operation_create_At,operations.operation_compte_id ORDER BY operations.operation_create_At DESC");

          if (query != null) {
            final isolate = await Isolate.spawn(
                ForegroundIsolate.readInventoriesFromForeground,
                [receivePort.sendPort, query]);
            final list = await receivePort.first;
            inventories.clear();
            inventories.addAll(list);
            isolate.kill(priority: Isolate.immediate);
          }

          break;
        case "compte":
          var query = await NativeDbHelper.rawQuery(
              "SELECT SUM(operations.operation_montant) AS totalPay, * FROM operations INNER JOIN comptes on operations.operation_compte_id = comptes.compte_id WHERE NOT operations.operation_state='deleted' AND operations.operation_compte_id = $fkey GROUP BY operations.operation_create_At, operations.operation_compte_id ORDER BY operations.operation_create_At DESC");
          if (query != null) {
            final isolate = await Isolate.spawn(
                ForegroundIsolate.readInventoriesFromForeground,
                [receivePort.sendPort, query]);
            final list = await receivePort.first;
            inventories.clear();
            inventories.addAll(list);
            isolate.kill(priority: Isolate.immediate);
          }
          break;
        case "type":
          var query = await NativeDbHelper.rawQuery(
              "SELECT SUM(operations.operation_montant) AS totalPay, * FROM operations INNER JOIN comptes on operations.operation_compte_id = comptes.compte_id WHERE NOT operations.operation_state='deleted' AND operations.operation_type = '$fkey' GROUP BY operations.operation_create_At , operations.operation_compte_id ORDER BY operations.operation_create_At DESC");

          if (query != null) {
            final isolate = await Isolate.spawn(
                ForegroundIsolate.readInventoriesFromForeground,
                [receivePort.sendPort, query]);
            final list = await receivePort.first;
            inventories.clear();
            inventories.addAll(list);
            isolate.kill(priority: Isolate.immediate);
          }
          break;
        case "date":
          var ies =
              inventories.where((e) => e.operationDate.contains(fkey)).toList();
          inventories.clear();
          inventories.addAll(ies);
          break;
        case "mois":
          var ies = inventories
              .where((e) => lastChars(e.operationDate, 7).contains(fkey))
              .toList();
          inventories.clear();
          inventories.addAll(ies);
          break;
      }
    } catch (e) {}
    return "end";
  }

  loadActivatedComptes() async {
    try {
      var allAccounts = await NativeDbHelper.rawQuery(
          "SELECT * FROM comptes WHERE compte_status='actif' AND NOT compte_state='deleted'");
      if (allAccounts != null) {
        comptes.clear();
        allAccounts.forEach((e) {
          comptes.add(Compte.fromMap(e));
        });
      }
    } catch (e) {}
  }

  loadAllComptes() async {
    try {
      var json = await NativeDbHelper.rawQuery(
          "SELECT * FROM comptes WHERE NOT compte_state='deleted'");
      if (json != null) {
        allComptes.clear();
        json.forEach((e) {
          allComptes.add(Compte.fromMap(e));
        });
      }
    } catch (e) {}
  }

  editCurrency({String value}) async {
    try {
      var db = await DbHelper.initDb();
      var data = Currency(currencyValue: value);
      var checked = await db.query("currencies");
      if (checked.isEmpty && value == null) {
        var data = Currency(currencyValue: "2000");
        await db.insert("currencies", data.toMap());
      }
      if (value != null) {
        await db.update(
          "currencies",
          data.toMap(),
          where: "cid=?",
          whereArgs: [1],
        );
        refreshCurrency();
      }
    } catch (e) {}
  }

  Future syncUserData() async {
    var db = await DbHelper.initDb();
    final batch = db.batch();
    var syncDatas = await Synchroniser.outPutData();
    try {
      if (syncDatas.users.isNotEmpty) {
        for (var user in syncDatas.users) {
          var check = await db.rawQuery(
            "SELECT * FROM users WHERE user_id = ?",
            [user.userId],
          );
          if (check.isEmpty) {
            batch.insert("users", user.toMap());
          } else {
            batch.update(
              "users",
              user.toMap(),
              where: "user_id=?",
              whereArgs: [user.userId],
            );
          }
          var res = await batch.commit();
          print("committed $res");
        }
        return "end";
      }
    } catch (e) {}
  }
}
