import '../../../global/utils.dart';
import 'stock.dart';

class MouvementStock {
  dynamic mouvtId;
  dynamic mouvtQteEn;
  dynamic mouvtQteSo;
  dynamic mouvtStockId;
  dynamic mouvtTimestamp;
  String mouvtDate;
  String mouvtState;
  Stock stock;

  MouvementStock({
    this.mouvtId,
    this.mouvtQteEn,
    this.mouvtQteSo,
    this.mouvtStockId,
    this.mouvtTimestamp,
    this.mouvtState,
  });

  Map<String, dynamic> toMap() {
    Map<String, dynamic> data = {};
    if (mouvtId != null) {
      data["mouvt_id"] = int.parse(mouvtId.toString());
    }
    if (mouvtQteEn != null) {
      data["mouvt_qte_en"] = int.parse(mouvtQteEn.toString());
    }

    if (mouvtQteSo != null) {
      data["mouvt_qte_so"] = int.parse(mouvtQteSo.toString());
    }

    if (mouvtStockId != null) {
      data["mouvt_stock_id"] = int.parse(mouvtStockId.toString());
    }
    DateTime now =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    if (mouvtTimestamp == null) {
      data["mouvt_create_At"] = convertToTimestamp(now);
    } else {
      data["mouvt_create_At"] = int.parse(mouvtTimestamp);
    }
    if (mouvtState != null) {
      data["mouvt_state"] = mouvtState;
    } else {
      data["mouvt_state"] = "allowed";
    }
    return data;
  }

  MouvementStock.fromMap(Map<String, dynamic> data) {
    mouvtId = data["mouvt_id"];
    mouvtQteEn = data["mouvt_qte_en"];
    mouvtQteSo = data["mouvt_qte_so"];
    mouvtStockId = data["mouvt_stock_id"];
    mouvtTimestamp = data["mouvt_create_At"];
    mouvtState = data["mouvt_state"];
    if (data["stock_id"] != null) {
      stock = Stock.fromMap(data);
    }
    try {
      mouvtDate = dateToString(
          parseTimestampToDate(int.parse(data["mouvt_create_At"].toString())));
    } catch (err) {}
  }
}
