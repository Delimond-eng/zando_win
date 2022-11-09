import 'package:firedart/firedart.dart';
import 'package:zando_m/global/controllers.dart';

import 'services/db_stock_helper.dart';

class SyncStock {
  static Future syncOut() async {
    authController.isSyncIn.value = true;
    var db = await DbStockHelper.initDb();
    var stocks = await db.query("stocks");
    var mouvts = await db.query("mouvements");
    var articles = await db.query("articles");

    try {
      if (stocks.isNotEmpty) {
        for (var e in stocks) {
          Firestore.instance
              .collection('stocks')
              .document(e["stock_id"].toString())
              .set(e);
        }
      }
      if (mouvts.isNotEmpty) {
        for (var e in mouvts) {
          Firestore.instance
              .collection('mouvements')
              .document(e["mouvt_id"].toString())
              .set(e);
        }
      }
      if (articles.isNotEmpty) {
        for (var e in articles) {
          Firestore.instance
              .collection('articles')
              .document(e["article_id"].toString())
              .set(e);
        }
      }
    } on Exception catch (e) {
      print("fireException: $e");
    }
    authController.isSyncIn.value = false;
    return "end";
  }

  static Future syncIn() async {
    authController.isSyncIn.value = true;
    var db = await DbStockHelper.initDb();

    try {
      await Firestore.instance
          .collection("mouvements")
          .get()
          .then((result) async {
        final batch = db.batch();
        for (var e in result) {
          var id = int.parse(e["mouvt_id"].toString());
          var state = e["mouvt_state"];
          var s = await db
              .query("mouvements", where: "mouvt_id=?", whereArgs: [id]);
          if (s.isEmpty) {
            if (state != "deleted") {
              batch.insert("mouvements", e.map);
            } else {
              batch.update("mouvements", e.map,
                  where: "mouvt_id=?", whereArgs: [id]);
            }
          }
        }
        await batch.commit();
      });
    } catch (e) {}
    try {
      await Firestore.instance
          .collection("articles")
          .get()
          .then((result) async {
        final batch = db.batch();
        for (var e in result) {
          var id = int.parse(e["article_id"].toString());
          var state = e["article_state"];
          var s = await db
              .query("articles", where: "article_id=?", whereArgs: [id]);
          if (s.isEmpty) {
            if (state != "deleted") {
              batch.insert("articles", e.map);
            }
          }
        }
        await batch.commit();
      });
    } catch (e) {}
    try {
      await Firestore.instance.collection("stocks").get().then((result) async {
        final batch = db.batch();
        for (var e in result) {
          var state = e["stock_state"];
          var id = int.parse(e["stock_id"].toString());
          var s =
              await db.query("stocks", where: "stock_id=?", whereArgs: [id]);
          if (s.isEmpty) {
            if (state != "deleted") {
              batch.insert("stocks", e.map);
            } else {
              batch.update("stocks", e.map,
                  where: "stock_id=?", whereArgs: [id]);
            }
          }
        }
        await batch.commit();
      });
    } catch (e) {}
    await stockController.reloadData();
    authController.isSyncIn.value = false;
    return "end";
  }

  static Future<bool> checkIn(String col, {String id, String value}) async {
    var data = await Firestore.instance
        .collection(col)
        .where(id, isEqualTo: int.parse(value))
        .get();
    return data.isEmpty;
  }
}
