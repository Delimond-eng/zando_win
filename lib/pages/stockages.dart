import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zando_m/global/controllers.dart';
import 'package:zando_m/pages/components/stock_create_drawer.dart';
import 'package:zando_m/pages/modals/stock_detail_modal.dart';
import 'package:zando_m/pages/modals/stock_mouvement_modal.dart';
import 'package:zando_m/repositories/stock_repo/models/mouvement.dart';
import 'package:zando_m/repositories/stock_repo/services/db_stock_helper.dart';
import 'package:zando_m/utilities/modals.dart';
import 'package:zando_m/widgets/search_input.dart';

import '../repositories/stock_repo/models/stock.dart';
import '../responsive/base_widget.dart';
import '../widgets/costum_table.dart';
import '../widgets/custom_page.dart';
import '../widgets/empty_table.dart';

class Stockages extends StatefulWidget {
  const Stockages({Key key}) : super(key: key);

  @override
  State<Stockages> createState() => _StockagesState();
}

class _StockagesState extends State<Stockages> {
  final GlobalKey<ScaffoldState> _key = GlobalKey();
  List<Stock> stocks = <Stock>[];

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      dataController.dataLoading.value = true;
      stockController.reloadData().then((res) {
        dataController.dataLoading.value = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _key,
      endDrawer: StockCreateDrawer(
        onReload: () async {
          setState(() {});
          stockController.reloadData();
        },
      ),
      drawerScrimColor: Colors.transparent,
      body: CustomPage(
        title: "Stockage",
        icon: Icons.backpack_rounded,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Responsive(
              builder: (context, responsive) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: SearchInput(
                              hintText: "Recherche stock...",
                              onChanged: (value) {
                                stockController.reloadData(seachWord: value);
                              },
                            ),
                          ),
                          const SizedBox(
                            width: 10.0,
                          ),
                          ElevatedButton.icon(
                            onPressed: () async {
                              _key.currentState.openEndDrawer();
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(20.0),
                              backgroundColor: Colors.indigo,
                            ),
                            icon: const Icon(
                              CupertinoIcons.add,
                              size: 15.0,
                            ),
                            label: Text(
                              "Nouveau stock",
                              style: GoogleFonts.didactGothic(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Obx(() {
                        return (stockController.stocks.isEmpty)
                            ? const EmptyTable()
                            : ListView(
                                padding: const EdgeInsets.all(10.0),
                                children: [
                                  CostumTable(
                                    cols: const [
                                      "Date",
                                      "Article",
                                      "Prix d'achat",
                                      "Qté entrée",
                                      "Qté sortie",
                                      "Solde",
                                      ""
                                    ],
                                    data: _createRows(context),
                                  ),
                                ],
                              );
                      }),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  List<DataRow> _createRows(BuildContext context) {
    return stockController.stocks
        .map(
          (data) => DataRow(
            color: data.solde > 0
                ? null
                : MaterialStateProperty.all(Colors.pink[100]),
            onSelectChanged: (val) async {
              var db = await DbStockHelper.initDb();
              Xloading.showLottieLoading(context);
              await db
                  .rawQuery(
                      "SELECT * FROM mouvements WHERE NOT mouvt_state = 'deleted' AND mouvt_stock_id=${data.stockId}")
                  .then((result) {
                Xloading.dismiss();
                var mouvements = <MouvementStock>[];
                result
                    .forEach((v) => mouvements.add(MouvementStock.fromMap(v)));
                if (val) {
                  if (mouvements.isEmpty) {
                    XDialog.showMessage(
                      context,
                      message: "Aucun mouvement pour ce stock!",
                      type: "warning",
                    );
                    return;
                  }
                  showStockDetails(context, mouvts: mouvements, stock: data);
                }
              });
            },
            cells: [
              DataCell(
                Text(
                  data.stockDate,
                  style: GoogleFonts.didactGothic(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              DataCell(
                Text(
                  data.article.articleLibelle,
                  style: GoogleFonts.didactGothic(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              DataCell(
                Text(
                  '${data.stockPrixAchat} ${data.stockPrixAchatDevise}',
                  style: GoogleFonts.didactGothic(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              DataCell(
                Text(
                  data.stockEn.toString(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.didactGothic(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              DataCell(
                Text(
                  data.stockSo.toString(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.didactGothic(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              DataCell(
                Text(
                  data.solde.toString(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.didactGothic(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              DataCell(
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.blue,
                        elevation: 2,
                        padding: const EdgeInsets.all(8.0),
                      ),
                      child: Text(
                        "Entrer",
                        style: GoogleFonts.didactGothic(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontSize: 12.0,
                        ),
                      ),
                      onPressed: () async {
                        showStokMouvementModal(
                          context,
                          "Mouvement entrée stock de l'article : ${data.article.articleLibelle}",
                          onReload: () {
                            Get.back();
                            stockController.reloadData();
                          },
                          a: data.article,
                          s: data,
                          isEn: true,
                        );
                      },
                    ),
                    const SizedBox(
                      width: 5,
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.pink,
                        elevation: 2,
                        padding: const EdgeInsets.all(8.0),
                      ),
                      child: Text(
                        "Sortir",
                        style: GoogleFonts.didactGothic(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontSize: 12.0,
                        ),
                      ),
                      onPressed: () async {
                        showStokMouvementModal(context,
                            "Mouvement sortie stock de l'article : ${data.article.articleLibelle}",
                            onReload: () {
                          Get.back();
                          stockController.reloadData();
                        }, a: data.article, s: data, color: Colors.pink);
                      },
                    ),
                    const SizedBox(
                      width: 5,
                    ),
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
                      onPressed: () =>
                          deleteStock(int.parse(data.stockId.toString())),
                    ),
                  ],
                ),
              )
            ],
          ),
        )
        .toList();
  }

  void deleteStock(int id) async {
    print(id);
    var db = await DbStockHelper.initDb();
    XDialog.show(context,
        message: "Etes-vous sûr de vouloir supprimer définitivement ce stock ?",
        onValidated: () async {
      await db
          .update("stocks", {"stock_state": "deleted"},
              where: "stock_id=?", whereArgs: [id])
          .then((stockId) {
        db.update("mouvements", {"mouvt_state": "deleted"},
            where: "mouvt_stock_id=?", whereArgs: [stockId]);
      });
      await stockController.reloadData();
    }, onFailed: () {});
  }
}
