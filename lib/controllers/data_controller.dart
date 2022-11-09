import 'package:get/get.dart';
import 'package:zando_m/models/operation.dart';
import 'package:zando_m/reports/models/daily_count.dart';
import 'package:zando_m/reports/report.dart';

import '../global/controllers.dart';
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
        List<Facture> temps = <Facture>[];
        for (var e in query) {
          await Future.delayed(const Duration(microseconds: 1000));
          temps.add(Facture.fromMap(e));
        }
        filteredFactures.clear();
        filteredFactures.addAll(temps);
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
    print("loading");
    try {
      var allFactures = await NativeDbHelper.rawQuery(
          "SELECT * FROM factures INNER JOIN clients ON factures.facture_client_id = clients.client_id WHERE factures.facture_statut = 'en cours' AND NOT factures.facture_state='deleted' ORDER BY factures.facture_id DESC");
      if (allFactures != null) {
        List<Facture> tempsList = <Facture>[];
        for (var e in allFactures) {
          await Future.delayed(const Duration(microseconds: 1000));
          tempsList.add(Facture.fromMap(e));
        }
        factures.clear();
        factures.addAll(tempsList);
      }
    } catch (e) {}
    return "end";
  }

  Future loadClients() async {
    try {
      var allClients = await NativeDbHelper.rawQuery(
          "SELECT * FROM clients WHERE NOT client_state ='deleted' ORDER BY client_id DESC");
      if (allClients != null) {
        List<Client> tempsList = <Client>[];
        for (var e in allClients) {
          await Future.delayed(const Duration(microseconds: 1000));
          tempsList.add(Client.fromMap(e));
        }
        clients.clear();
        clients.addAll(tempsList);
      }
    } catch (e) {}
    return "end";
  }

  Future loadPayments(String key, {int field}) async {
    switch (key) {
      case "all":
        var query = await NativeDbHelper.rawQuery(
          "SELECT SUM(operations.operation_montant) AS totalPay, * FROM factures INNER JOIN operations ON factures.facture_id = operations.operation_facture_id INNER JOIN clients ON factures.facture_client_id = clients.client_id WHERE NOT operations.operation_state='deleted' GROUP BY operations.operation_facture_id ORDER BY operations.operation_facture_id DESC",
        );
        if (query != null) {
          List<Operations> tempsList = <Operations>[];
          for (var e in query) {
            await Future.delayed(const Duration(microseconds: 500));
            tempsList.add(Operations.fromMap(e));
          }
          paiements.clear();
          paiements.addAll(tempsList);
        }
        break;
      case "details":
        var query = await NativeDbHelper.rawQuery(
          "SELECT SUM(operations.operation_montant) AS totalPay, * FROM factures INNER JOIN operations ON factures.facture_id = operations.operation_facture_id INNER JOIN clients ON factures.facture_client_id = clients.client_id WHERE NOT operations.operation_state='deleted' GROUP BY operations.operation_facture_id ORDER BY operations.operation_id DESC",
        );
        if (query != null) {
          List<Operations> tempsList = <Operations>[];
          for (var e in query) {
            await Future.delayed(const Duration(microseconds: 500));
            tempsList.add(Operations.fromMap(e));
          }
          var strDate = dateToString(parseTimestampToDate(field));
          var filtersList =
              tempsList.where((op) => op.operationDate.contains(strDate));
          paiements.clear();
          paiements.addAll(filtersList);
        }
        break;
      case "date":
        var query = await NativeDbHelper.rawQuery(
          "SELECT SUM(operations.operation_montant) AS totalPay, * FROM factures INNER JOIN operations ON factures.facture_id = operations.operation_facture_id INNER JOIN clients ON factures.facture_client_id = clients.client_id WHERE NOT operations.operation_state='deleted' GROUP BY operations.operation_facture_id ORDER BY operations.operation_facture_id DESC",
        );
        if (query != null) {
          List<Operations> tempsList = <Operations>[];

          for (var e in query) {
            await Future.delayed(const Duration(microseconds: 1000));
            tempsList.add(Operations.fromMap(e));
          }
          paiements.clear();
          paiements.addAll(tempsList);
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
    var query = await NativeDbHelper.rawQuery(
        "SELECT * FROM factures INNER JOIN operations ON factures.facture_id = operations.operation_facture_id INNER JOIN clients ON factures.facture_client_id = clients.client_id WHERE NOT operations.operation_state='deleted' AND operations.operation_facture_id = $factureId");
    if (query != null) {
      List<Operations> tempsList = <Operations>[];
      for (var e in query) {
        await Future.delayed(const Duration(microseconds: 1000));
        tempsList.add(Operations.fromMap(e));
      }
      paiementDetails.clear();
      paiementDetails.addAll(tempsList);
    }
    return "end";
  }

  Future loadInventories(String fword, {fkey}) async {
    try {
      switch (fword) {
        case "all":
          var query = await NativeDbHelper.rawQuery(
              "SELECT SUM(operations.operation_montant) AS totalPay, * FROM operations INNER JOIN comptes on operations.operation_compte_id = comptes.compte_id WHERE NOT operations.operation_state='deleted' GROUP BY operations.operation_create_At,operations.operation_compte_id ORDER BY operations.operation_create_At DESC");

          if (query != null) {
            List<Operations> tempsList = <Operations>[];
            for (var e in query) {
              await Future.delayed(const Duration(microseconds: 1000));
              tempsList.add(Operations.fromMap(e));
            }
            inventories.clear();
            inventories.addAll(tempsList);
          }

          break;
        case "compte":
          var query = await NativeDbHelper.rawQuery(
              "SELECT SUM(operations.operation_montant) AS totalPay, * FROM operations INNER JOIN comptes on operations.operation_compte_id = comptes.compte_id WHERE NOT operations.operation_state='deleted' AND operations.operation_compte_id = $fkey GROUP BY operations.operation_create_At, operations.operation_compte_id ORDER BY operations.operation_create_At DESC");
          if (query != null) {
            List<Operations> tempsList = <Operations>[];
            for (var e in query) {
              await Future.delayed(const Duration(microseconds: 1000));
              tempsList.add(Operations.fromMap(e));
            }
            inventories.clear();
            inventories.addAll(tempsList);
          }
          break;
        case "type":
          var query = await NativeDbHelper.rawQuery(
              "SELECT SUM(operations.operation_montant) AS totalPay, * FROM operations INNER JOIN comptes on operations.operation_compte_id = comptes.compte_id WHERE NOT operations.operation_state='deleted' AND operations.operation_type = '$fkey' GROUP BY operations.operation_create_At , operations.operation_compte_id ORDER BY operations.operation_create_At DESC");

          if (query != null) {
            List<Operations> tempsList = <Operations>[];
            for (var e in query) {
              await Future.delayed(const Duration(microseconds: 1000));
              tempsList.add(Operations.fromMap(e));
            }
            inventories.clear();
            inventories.addAll(tempsList);
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

  Future syncData() async {
    var db = await DbHelper.initDb();
    final batch = db.batch();
    authController.isSyncIn.value = true;
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
        }
        await batch.commit();
      }
      if (syncDatas.clients.isNotEmpty) {
        try {
          for (var client in syncDatas.clients) {
            if (client.clientState == "allowed") {
              var check = await db.rawQuery(
                "SELECT * FROM clients WHERE client_id = ?",
                [client.clientId],
              );
              if (check.isEmpty) {
                batch.insert("clients", client.toMap());
              }
            }
          }
          await batch.commit();
        } catch (err) {}
      }
      if (syncDatas.factures.isNotEmpty) {
        try {
          for (var facture in syncDatas.factures) {
            if (facture.factureState == "allowed") {
              var check = await db.query(
                "factures",
                where: "facture_id= ?",
                whereArgs: [facture.factureId],
              );
              if (check.isEmpty) {
                batch.insert("factures", facture.toMap());
              }
            }
          }
          await batch.commit();
        } catch (e) {
          print(e);
        }
      }
      if (syncDatas.factureDetails.isNotEmpty) {
        try {
          for (var detail in syncDatas.factureDetails) {
            if (detail.factureDetailState == "allowed") {
              var check = await db.rawQuery(
                "SELECT * FROM facture_details WHERE facture_detail_id = ?",
                [detail.factureDetailId],
              );
              if (check.isEmpty) {
                batch.insert("facture_details", detail.toMap());
              }
            }
          }
          await batch.commit();
        } catch (e) {}
      }
      if (syncDatas.operations.isNotEmpty) {
        try {
          for (var operation in syncDatas.operations) {
            if (operation.operationState == "allowed") {
              var check = await db.rawQuery(
                "SELECT * FROM operations WHERE operation_id = ?",
                [operation.operationId],
              );
              if (check.isEmpty) {
                batch.insert("operations", operation.toMap());
              }
            }
          }
          await batch.commit();
        } catch (e) {}
      }
      if (syncDatas.comptes.isNotEmpty) {
        try {
          for (var compte in syncDatas.comptes) {
            if (compte.compteState == "allowed") {
              var check = await db.rawQuery(
                "SELECT * FROM comptes WHERE compte_id = ? ",
                [compte.compteId],
              );
              if (check.isEmpty) {
                batch.insert("comptes", compte.toMap());
              } else {
                batch.update(
                  "comptes",
                  compte.toMap(),
                  where: "compte_id=?",
                  whereArgs: [compte.compteId],
                );
              }
            }
            await batch.commit();
          }
        } catch (e) {}
      }
      authController.isSyncIn.value = false;
      await refreshDatas();
      return "end";
    } catch (err) {
      print(err);
    }
  }
}
