import 'package:animate_do/animate_do.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zando_m/global/controllers.dart';
import 'package:zando_m/services/db_helper.dart';
import 'package:zando_m/widgets/empty_table.dart';

import '../models/compte.dart';
import '../responsive/base_widget.dart';
import '../services/native_db_helper.dart';
import '../services/synchonisation.dart';
import '../widgets/costum_table.dart';
import '../widgets/custom_page.dart';
import '../widgets/search_input.dart';
import 'components/add_account_drawer.dart';

class Treasures extends StatefulWidget {
  const Treasures({Key key}) : super(key: key);

  @override
  State<Treasures> createState() => _TreasuresState();
}

class _TreasuresState extends State<Treasures> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  @override
  void initState() {
    super.initState();
    dataController.loadAllComptes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawerScrimColor: Colors.transparent,
      endDrawer: const AddAccountDrawer(),
      backgroundColor: Colors.transparent,
      body: CustomPage(
        title: "Trésoreries",
        icon: CupertinoIcons.cube_box_fill,
        child: LayoutBuilder(builder: (context, constraints) {
          return Responsive(builder: (context, responsive) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Liste des comptes",
                        style: GoogleFonts.didactGothic(
                          fontSize: 18.0,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          _scaffoldKey.currentState.openEndDrawer();
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(20.0),
                          backgroundColor: Colors.indigo,
                        ),
                        icon: const Icon(
                          Icons.add,
                          size: 15.0,
                        ),
                        label: Text(
                          "Nouveau compte",
                          style: GoogleFonts.didactGothic(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                FadeInUp(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10.0,
                      vertical: 8.0,
                    ),
                    child: Row(
                      children: [
                        Flexible(
                          child: SearchInput(
                            spacedLeft: 0,
                            hintText: "Recherche compte...",
                            onChanged: (value) async {
                              var json = await NativeDbHelper.rawQuery(
                                  "SELECT * FROM comptes WHERE NOT compte_state='deleted' AND compte_libelle LIKE '%$value%'");
                              dataController.allComptes.clear();
                              json.forEach((e) {
                                dataController.allComptes
                                    .add(Compte.fromMap(e));
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Obx(
                    () => FadeInUp(
                      child: dataController.allComptes.isEmpty
                          ? const EmptyTable()
                          : ListView(
                              padding: const EdgeInsets.all(10.0),
                              children: [
                                CostumTable(
                                  cols: const [
                                    "Date création",
                                    "Libellé",
                                    "Devise",
                                    "Status",
                                    ""
                                  ],
                                  data: _createRows(),
                                ),
                              ],
                            ),
                    ),
                  ),
                )
              ],
            );
          });
        }),
      ),
    );
  }

  List<DataRow> _createRows() {
    return dataController.allComptes
        .map(
          (compte) => DataRow(
            cells: [
              DataCell(
                Text(
                  compte.compteDate,
                  style: GoogleFonts.didactGothic(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              DataCell(
                Text(
                  compte.compteLibelle,
                  style: GoogleFonts.didactGothic(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              DataCell(
                Text(
                  compte.compteDevise,
                  style: GoogleFonts.didactGothic(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.all(5.0),
                  decoration: BoxDecoration(
                    color: (compte.compteStatus == "actif")
                        ? Colors.green[200]
                        : Colors.red[100],
                    borderRadius: BorderRadius.circular(3.0),
                  ),
                  child: Text(
                    compte.compteStatus,
                    style: GoogleFonts.didactGothic(
                      fontWeight: FontWeight.w600,
                      fontSize: 10.0,
                      color: (compte.compteStatus == "actif")
                          ? Colors.green[700]
                          : Colors.red[700],
                    ),
                  ),
                ),
              ),
              DataCell(
                Row(
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: compte.compteStatus == "actif"
                            ? Colors.pink
                            : Colors.green,
                        elevation: 2,
                        padding: const EdgeInsets.all(8.0),
                      ),
                      child: Text(
                        (compte.compteStatus == "actif")
                            ? "Desactiver"
                            : "Activer",
                        style: GoogleFonts.didactGothic(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontSize: 12.0,
                        ),
                      ),
                      onPressed: () async {
                        var db = await DbHelper.initDb();
                        var map;
                        if (compte.compteStatus == "actif") {
                          map = {"compte_status": "inactif"};
                        } else {
                          map = {"compte_status": "actif"};
                        }
                        await db.update("comptes", map,
                            where: "compte_id=?",
                            whereArgs: [compte.compteId]).then((id) {
                          dataController.loadAllComptes();
                          dataController.loadActivatedComptes();
                        });
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
