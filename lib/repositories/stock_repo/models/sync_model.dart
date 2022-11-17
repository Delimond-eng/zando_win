import 'article.dart';
import 'stock.dart';
import 'mouvement.dart';

class SyncStockModel {
  List<Article> articles;
  List<Stock> stocks;
  List<MouvementStock> mouvements;

  SyncStockModel.fromMap(Map<String, dynamic> json) {
    if (json['data']['clients'] != null) {
      articles = <Article>[];
      json['data']['articles'].forEach((v) {
        articles.add(Article.fromMap(v));
      });
    }
    if (json['data']['stocks'] != null) {
      stocks = <Stock>[];
      json['data']['stocks'].forEach((v) {
        stocks.add(Stock.fromMap(v));
      });
    }

    if (json['data']['mouvements'] != null) {
      mouvements = <MouvementStock>[];
      json['data']['mouvements'].forEach((v) {
        mouvements.add(MouvementStock.fromMap(v));
      });
    }
  }
}
