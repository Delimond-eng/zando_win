import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:zando_m/global/controllers.dart';
import 'package:zando_m/repositories/stock_repo/models/sync_model.dart';

import 'services/db_stock_helper.dart';
import 'package:http/http.dart' as http;

class SyncStock {
  static const String baseURL = "http://z-database.rtgroup-rdc.com";
  static Future syncOut() async {
    authController.isSyncIn.value = true;
    var db = await DbStockHelper.initDb();
    var stocks = await db.query("stocks");
    var mouvts = await db.query("mouvements");
    var articles = await db.query("articles");

    if (stocks.isNotEmpty) {
      send({"stocks": stocks});
      // for (var e in stocks) {
      //   Firestore.instance
      //       .collection('stocks')
      //       .document(e["stock_id"].toString())
      //       .set(e)
      //       .catchError((err) => print("error1"));
      // }
    }
    if (mouvts.isNotEmpty) {
      // for (var e in mouvts) {
      //   Firestore.instance
      //       .collection('mouvements')
      //       .document(e["mouvt_id"].toString())
      //       .set(e)
      //       .catchError((err) => print("error2"));
      // }
      send({"mouvements": mouvts});
    }
    if (articles.isNotEmpty) {
      send({"articles": articles});
      // for (var e in articles) {
      //   Firestore.instance
      //       .collection('articles')
      //       .document(e["article_id"].toString())
      //       .set(e);
      // }
    }
    authController.isSyncIn.value = false;
    return "end";
  }

  static Future syncIn() async {
    authController.isSyncIn.value = true;
    var db = await DbStockHelper.initDb();
    var datas = await receiveData();
    if (datas == null) {
      authController.isSyncIn.value = false;
      return;
    }
    try {
      // await Firestore.instance
      //     .collection("articles")
      //     .get()
      //     .then((result) async {

      // });
      final batch = db.batch();
      if (datas.articles.isNotEmpty) {
        for (var e in datas.articles) {
          var id = int.parse(e.articleId.toString());
          var state = e.articleState;
          var s = await db
              .query("articles", where: "article_id=?", whereArgs: [id]);
          if (s.isEmpty) {
            if (state != "deleted") {
              batch.insert("articles", e.toMap());
            }
          }
        }
      }
      await batch.commit();
    } catch (e) {}

    try {
      final batch = db.batch();
      // await Firestore.instance.collection("stocks").get().then((result) async {

      // });
      if (datas.stocks.isNotEmpty) {
        for (var e in datas.stocks) {
          var state = e.stockState;
          var id = int.parse(e.stockId.toString());
          var s =
              await db.query("stocks", where: "stock_id=?", whereArgs: [id]);
          if (s.isEmpty) {
            if (state != "deleted") {
              batch.insert("stocks", e.toMap());
            } else {
              batch.update(
                "stocks",
                e.toMap(),
                where: "stock_id=?",
                whereArgs: [id],
              );
            }
          }
        }
        await batch.commit();
      }
    } catch (e) {}

    try {
      final batch = db.batch();
      // await Firestore.instance
      //     .collection("mouvements")
      //     .get()
      //     .then((result) async {

      // });
      if (datas.mouvements.isNotEmpty) {
        for (var e in datas.mouvements) {
          var id = int.parse(e.mouvtId.toString());
          var state = e.mouvtState;
          var s = await db
              .query("mouvements", where: "mouvt_id=?", whereArgs: [id]);
          if (s.isEmpty) {
            if (state != "deleted") {
              batch.insert("mouvements", e.toMap());
            } else {
              batch.update(
                "mouvements",
                e.toMap(),
                where: "mouvt_id=?",
                whereArgs: [id],
              );
            }
          }
        }
        await batch.commit();
      }
    } catch (e) {}

    await stockController.reloadData();
    authController.isSyncIn.value = false;
    return "end";
  }

  // static Future<bool> checkIn(String col, {String id, String value}) async {
  //   var data = await Firestore.instance
  //       .collection(col)
  //       .where(id, isEqualTo: int.parse(value))
  //       .get();
  //   return data.isEmpty;
  // }
  static Future send(Map<String, dynamic> map) async {
    print("starting synch");
    String json = jsonEncode(map);
    Directory tempDir = await getTemporaryDirectory();
    String tempPath = tempDir.path;
    String filename = "file.json";
    File file = File("$tempPath/$filename");
    file.createSync();
    file.writeAsStringSync(json);
    // var users = await NativeDbHelper.query("users");
    // if (users != null) {
    //   if (users[0]['user_name'] == "admin") {
    //     return;
    //   }
    // }
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

  static Future<SyncStockModel> receiveData() async {
    http.Client client = http.Client();
    http.Response response;
    try {
      response = await client.get(Uri.parse("$baseURL/datas/sync/out"));
    } catch (err) {
      print("error from output data $err");
    }
    if (response != null) {
      if (response.statusCode != null && response.statusCode == 200) {
        return SyncStockModel.fromMap(jsonDecode(response.body));
      } else {
        return null;
      }
    } else {
      return null;
    }
  }
}
