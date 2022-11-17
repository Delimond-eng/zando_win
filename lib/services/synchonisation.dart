import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:zando_m/global/controllers.dart';
import 'package:zando_m/repositories/facturation_repo/sync_in.dart';

import '../models/sync_model.dart';
import 'db_helper.dart';
import 'native_db_helper.dart';

class Synchroniser {
  static const String baseURL = "http://z-database.rtgroup-rdc.com";
  static Future inPutData() async {
    authController.isSyncIn.value = true;
    var db = await DbHelper.initDb();
    try {
      var users = await db.query("users");
      if (users.isNotEmpty) {
        send({"users": users});
      }
      var clients = await db.query("clients");
      if (clients.isNotEmpty) {
        await send({"clients": clients});
        await db.delete("clients",
            where: "client_state= ?", whereArgs: ["deleted"]);
      }
      var factures = await db.query("factures");
      if (factures.isNotEmpty) {
        await send({"factures": factures});
        await db.delete("factures",
            where: "facture_state= ?", whereArgs: ["deleted"]);
      }
      try {
        var factureDetails = await db.query("facture_details");
        if (factureDetails.isNotEmpty) {
          await send({"facture_details": factureDetails});
          await db.delete("facture_details",
              where: "facture_detail_state = ?", whereArgs: ["deleted"]);
        }
      } catch (err) {}

      try {
        var comptes = await db.query("comptes");
        if (comptes.isNotEmpty) {
          await send({"comptes": comptes});
          await db.delete("comptes",
              where: "compte_state = ?", whereArgs: ["deleted"]);
        }
      } catch (e) {}

      try {
        var operations = await db.query("operations");
        if (operations.isNotEmpty) {
          await send({"operations": operations});
          await db.delete("operations",
              where: "operation_state= ?", whereArgs: ["deleted"]);
        }
      } catch (err) {}

      await FacturationRepo.syncData();

      /*try {
        var articles = await db.query("articles",
            where: "article_state=?", whereArgs: ["allowed"]);
        if (articles.isNotEmpty) {
          await send({"articles": articles});
        }
      } catch (e) {}

      try {
        var stocks = await db
            .query("stocks", where: "stock_state=?", whereArgs: ["allowed"]);
        if (stocks.isNotEmpty) {
          await send({"stocks": stocks});
        }
      } catch (err) {}
      try {
        var mouvements = await db.query("mouvements",
            where: "mouvt_state=?", whereArgs: ["allowed"]);
        if (mouvements.isNotEmpty) {
          await send({"mouvements": mouvements});
        }
      } catch (err) {}
      */
    } catch (e) {
      print(e);
    }
    return "end";
  }

  static Future<SyncModel> outPutData() async {
    http.Client client = http.Client();
    http.Response response;
    try {
      response = await client.get(Uri.parse("$baseURL/datas/sync/out"));
    } catch (err) {
      print("error from output data $err");
    }
    if (response != null) {
      if (response.statusCode != null && response.statusCode == 200) {
        return SyncModel.fromMap(jsonDecode(response.body));
      } else {
        return null;
      }
    } else {
      return null;
    }
  }

  static Future send(Map<String, dynamic> map) async {
    print("starting synch");
    String json = jsonEncode(map);
    Directory tempDir = await getTemporaryDirectory();
    String tempPath = tempDir.path;
    String filename = "file.json";
    File file = File("$tempPath/$filename");
    file.createSync();
    file.writeAsStringSync(json);
    var users = await NativeDbHelper.query("users");
    if (users != null) {
      if (users[0]['user_name'] == "admin") {
        return;
      }
    }
    try {
      var request =
          http.MultipartRequest('POST', Uri.parse("$baseURL/datas/sync/in"));

      request.files.add(
        http.MultipartFile.fromBytes(
          'fichier',
          file.readAsBytesSync(),
          filename: filename.split("/").last,
        ),
      );
      request
          .send()
          .then((result) async {
            http.Response.fromStream(result).then((response) {
              if (response.statusCode == 200) {
                print(response.body);
              }
            });
          })
          .catchError((err) => print('error : $err'))
          .whenComplete(() {});
    } catch (err) {
      print("error from $err");
    }
  }
}
