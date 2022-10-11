import 'package:animate_do/animate_do.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zando_m/pages/modals/payModal.dart';
import 'package:zando_m/utilities/modals.dart';
import 'package:zando_m/widgets/empty_table.dart';

import '../global/controllers.dart';
import '../models/facture.dart';
import '../responsive/base_widget.dart';
import '../services/native_db_helper.dart';
import '../widgets/costum_table.dart';
import '../widgets/custom_page.dart';
import '../widgets/filter_btn.dart';
import '../widgets/search_input.dart';
import 'modals/facture_details_modal.dart';

class Factures extends StatefulWidget {
  const Factures({Key key}) : super(key: key);

  @override
  State<Factures> createState() => _FacturesState();
}

class _FacturesState extends State<Factures> {
  var _filterKeyword = "all";
  @override
  void initState() {
    super.initState();
    dataController.loadFilterFactures("all");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawerScrimColor: Colors.black12,
      backgroundColor: Colors.transparent,
      body: CustomPage(
        title: "Factures",
        icon: CupertinoIcons.doc_on_doc_fill,
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
                      child: Text(
                        "Liste des factures",
                        style: GoogleFonts.didactGothic(
                          fontSize: 18.0,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _topFilters(context),
                    _dataTableViewer(context)
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _dataTableViewer(BuildContext context) {
    return Expanded(
      child: FadeInUp(
        child: Obx(() {
          return dataController.filteredFactures.isEmpty
              ? const EmptyTable()
              : ListView(
                  padding: const EdgeInsets.all(10.0),
                  children: [
                    CostumTable(
                      cols: const [
                        "Date création",
                        "Montant",
                        "Status",
                        "Client",
                        ""
                      ],
                      data: _createRows(context),
                    ),
                  ],
                );
        }),
      ),
    );
  }

  final List<Map> _filters = [
    {"keyw": "all", "title": "Toutes les factures"},
    {"keyw": "pending", "title": "Factures en cours"},
    {"keyw": "completed", "title": "Factures réglées"},
  ];

  Widget _topFilters(BuildContext context) {
    return FadeInUp(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 10.0,
          vertical: 8.0,
        ),
        child: StatefulBuilder(builder: (context, setter) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  ..._filters.map((e) {
                    return FilterBtn(
                      isSelected: e['keyw'] == _filterKeyword,
                      title: e['title'],
                      margin: 10.0,
                      icon: Icons.filter_list_rounded,
                      onPressed: () async {
                        setter(() {
                          _filterKeyword = e['keyw'];
                        });
                        Xloading.showLottieLoading(context);
                        Future.delayed(const Duration(milliseconds: 200),
                            () async {
                          await dataController.loadFilterFactures(e['keyw']);
                          Xloading.dismiss();
                        });
                      },
                    );
                  })
                ],
              ),
              const SizedBox(
                width: 10.0,
              ),
              Flexible(
                child: SearchInput(
                  spacedLeft: 0,
                  hintText: "Recherche facture par un nom du client ...",
                  onChanged: (kWord) async {
                    await _seachFactures(_filterKeyword, kWord);
                  },
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  _seachFactures(String key, String kword) async {
    try {
      var query;
      switch (key) {
        case "all":
          query = await NativeDbHelper.rawQuery(
              "SELECT * FROM factures INNER JOIN clients ON factures.facture_client_id = clients.client_id WHERE NOT factures.facture_state='deleted' AND NOT clients.client_state = 'deleted' AND clients.client_nom LIKE '%$kword%'");
          break;
        case "pending":
          query = await NativeDbHelper.rawQuery(
              "SELECT * FROM factures INNER JOIN clients ON factures.facture_client_id = clients.client_id WHERE factures.facture_statut='en cours' AND NOT factures.facture_state='deleted' AND NOT clients.client_state = 'deleted' AND  clients.client_nom LIKE '%$kword%'");
          break;
        case "completed":
          query = await NativeDbHelper.rawQuery(
              "SELECT * FROM factures INNER JOIN clients ON factures.facture_client_id = clients.client_id WHERE factures.facture_statut='paie' AND NOT factures.facture_state='deleted' AND NOT clients.client_state = 'deleted' AND clients.client_nom LIKE '%$kword%'");
          break;
        default:
          print("other");
      }
      if (query != null) {
        dataController.filteredFactures.clear();
        query.forEach((e) {
          dataController.filteredFactures.add(Facture.fromMap(e));
        });
      }
    } catch (e) {}
  }

  List<DataRow> _createRows(BuildContext context) {
    return dataController.filteredFactures
        .map(
          (data) => DataRow(
            cells: [
              DataCell(
                Text(
                  data.factureDateCreate,
                  style: GoogleFonts.didactGothic(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              DataCell(
                Text(
                  '${data.factureMontant} ${data.factureDevise}',
                  style: GoogleFonts.didactGothic(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.all(5.0),
                  decoration: BoxDecoration(
                    color: (data.factureStatut == "paie")
                        ? Colors.green[200]
                        : Colors.pink[100],
                    borderRadius: BorderRadius.circular(3.0),
                  ),
                  child: Text(
                    data.factureStatut,
                    style: GoogleFonts.didactGothic(
                      fontWeight: FontWeight.w600,
                      fontSize: 10.0,
                      color: (data.factureStatut == "paie")
                          ? Colors.green[700]
                          : Colors.pink,
                    ),
                  ),
                ),
              ),
              DataCell(
                Text(
                  data.client.clientNom,
                  style: GoogleFonts.didactGothic(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              DataCell(
                Row(
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: (data.factureStatut != "paie")
                            ? Colors.green
                            : Colors.grey,
                        elevation: 2,
                        padding: const EdgeInsets.all(8.0),
                      ),
                      child: Text(
                        "Payer",
                        style: GoogleFonts.didactGothic(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontSize: 12.0,
                        ),
                      ),
                      onPressed: (data.factureStatut != "paie")
                          ? () {
                              showPayModal(context, data);
                            }
                          : null,
                    ),
                    const SizedBox(
                      width: 5.0,
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.blue,
                        elevation: 2,
                        padding: const EdgeInsets.all(8.0),
                      ),
                      child: Text(
                        "Voir détals",
                        style: GoogleFonts.didactGothic(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontSize: 12.0,
                        ),
                      ),
                      onPressed: () async {
                        await factureDetailsModal(context, data);
                      },
                    ),
                  ],
                ),
              )
            ],
          ),
        )
        .toList();
  }
}
