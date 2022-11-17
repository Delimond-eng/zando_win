import '../../global/controllers.dart';
import '../../services/db_helper.dart';
import '../../services/synchonisation.dart';

class FacturationRepo {
  static Future syncData() async {
    var db = await DbHelper.initDb();
    final batch = db.batch();
    authController.isSyncIn.value = true;
    var syncDatas = await Synchroniser.outPutData();
    if (syncDatas == null) {
      authController.isSyncIn.value = false;
      return "end";
    }
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
      await dataController.refreshDatas();
      return "end";
    } catch (err) {
      print(err);
    }
  }
}
