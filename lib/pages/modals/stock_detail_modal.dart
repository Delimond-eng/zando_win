import 'package:animate_do/animate_do.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zando_m/global/controllers.dart';
import 'package:zando_m/pages/modals/widgets/stock_detail_card.dart';
import 'package:zando_m/repositories/stock_repo/services/db_stock_helper.dart';
import 'package:zando_m/utilities/modals.dart';

import '../../components/topbar.dart';
import '../../repositories/stock_repo/models/mouvement.dart';
import '../../repositories/stock_repo/models/stock.dart';
import '../../widgets/costum_table.dart';
import '../../widgets/round_icon_btn.dart';

showStockDetails(BuildContext context,
    {Stock stock, List<MouvementStock> mouvts}) {
  showDialog(
    barrierColor: Colors.black12,
    context: context,
    builder: (BuildContext context) {
      return FadeInUp(
        child: Dialog(
          insetPadding: const EdgeInsets.all(20.0),
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ), //this right here
          child: Container(
            color: Colors.white,
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: Column(
              children: [
                TopBar(
                  color: Colors.indigo,
                  height: 70.0,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Stock détails",
                          style: GoogleFonts.didactGothic(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        RoundedIconBtn(
                          size: 30.0,
                          iconColor: Colors.pink,
                          color: Colors.white,
                          icon: CupertinoIcons.clear,
                          onPressed: () {
                            Get.back();
                          },
                        )
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    children: [
                      StockDetailCard(
                        color: Colors.indigo,
                        icon: CupertinoIcons.arrow_down_right_square,
                        title: "Quantité entrée",
                        value: stock.stockEn.toString().padLeft(2, "0"),
                      ),
                      StockDetailCard(
                        color: Colors.pink,
                        icon: CupertinoIcons.arrow_down_left_square,
                        title: "Quantité sortie",
                        value: stock.stockSo.toString().padLeft(2, "0"),
                      ),
                      StockDetailCard(
                        color: Colors.green,
                        icon: CupertinoIcons.checkmark_alt_circle,
                        title: "Solde",
                        value: stock.solde.toString().padLeft(2, "0"),
                      ),
                      Flexible(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: DetailTitle(
                                    title: "Date création stock",
                                    value: stock.stockDate,
                                  ),
                                ),
                                const SizedBox(
                                  width: 8.0,
                                ),
                                Flexible(
                                  child: DetailTitle(
                                    title: "stock n°",
                                    value: stock.stockId.toString(),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 8.0,
                            ),
                            DetailTitle(
                              title: "Article",
                              value: stock.article.articleLibelle,
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(10.0),
                    children: [
                      CostumTable(
                        cols: const [
                          "Date mouvement",
                          "Qté entrée",
                          "Qté sortie",
                          ""
                        ],
                        data: _createRows(context, mouvts, stock),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

List<DataRow> _createRows(
    BuildContext context, List<MouvementStock> data, Stock s) {
  return data
      .map(
        (data) => DataRow(
          cells: [
            DataCell(
              Text(
                data.mouvtDate,
                style: GoogleFonts.didactGothic(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            DataCell(
              Text(
                data.mouvtQteEn.toString(),
                style: GoogleFonts.didactGothic(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            DataCell(
              Text(
                data.mouvtQteSo.toString(),
                style: GoogleFonts.didactGothic(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            DataCell(
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.red,
                  elevation: 2,
                  padding: const EdgeInsets.all(8.0),
                ),
                child: Text(
                  "Supprimer",
                  style: GoogleFonts.didactGothic(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontSize: 12.0,
                  ),
                ),
                onPressed: () async {
                  var db = await DbStockHelper.initDb();

                  XDialog.show(context,
                      message:
                          "Etes-vous sûr de vouloir supprimer ce mouvement stock ?",
                      onValidated: () async {
                    int solde = s.solde;
                    if (solde == data.mouvtQteEn) {
                      XDialog.showMessage(context,
                          message:
                              "Impossible de supprimer ce mouvement \n Vs devrez supprimer le stok dans la page d'accueil !",
                          type: "warning");
                      Future.delayed(const Duration(seconds: 3), () {
                        Get.back();
                      });
                      return;
                    }
                    await db
                        .update("mouvements", {"mouvt_state": "deleted"},
                            where: "mouvt_id=?", whereArgs: [data.mouvtId])
                        .then((value) {
                      stockController.reloadData();
                      Get.back();
                    });
                  }, onFailed: () {});
                },
              ),
            )
          ],
        ),
      )
      .toList();
}

class DetailTitle extends StatelessWidget {
  final String title;
  final String value;
  const DetailTitle({
    Key key,
    this.value,
    this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border.all(color: Colors.grey, width: .2),
        borderRadius: BorderRadius.circular(5.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(5.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.didactGothic(
                color: Colors.indigo,
                fontSize: 18.0,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(
              width: 8.0,
            ),
            Text(
              value,
              style: GoogleFonts.didactGothic(
                color: Colors.black,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.0,
                fontSize: 18.0,
              ),
            )
          ],
        ),
      ),
    );
  }
}
