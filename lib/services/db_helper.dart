import 'dart:io';
//import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'global.dart' as db_path;

class DbHelper {
  static Future<void> initDbLibrary() async {
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
    }
  }

  static Future<Database> initDb() async {
    var databaseFactory = databaseFactoryFfi;
    final scriptDir = File(Platform.script.toFilePath()).parent;
    String appDocPath = scriptDir.path;
    String path = join(appDocPath, db_path.databaseName);
    var db = await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        onCreate: _onCreate,
        version: 1,
      ),
    );
    return db;
  }

  static _onCreate(Database db, int version) async {
    try {
      await db.execute(
          "CREATE TABLE IF NOT EXISTS users(user_id INTEGER NOT NULL PRIMARY KEY, user_name TEXT, user_role TEXT, user_pass TEXT, user_access TEXT)");
      await db.execute(
          "CREATE TABLE IF NOT EXISTS currencies(cid INTEGER NOT NULL PRIMARY KEY, cvalue TEXT)");
      await db.execute(
          "CREATE TABLE IF NOT EXISTS clients(client_id INTEGER NOT NULL PRIMARY KEY, client_nom TEXT,client_tel TEXT, client_adresse TEXT, client_state TEXT, user_id INTEGER, client_create_At INTEGER)");
      await db.execute(
          "CREATE TABLE IF NOT EXISTS factures(facture_id INTEGER NOT NULL PRIMARY KEY, facture_montant REAL, facture_devise TEXT, facture_client_id INTEGER NOT NULL, facture_create_At INTEGER, facture_statut TEXT, facture_state TEXT, user_id INTEGER)");
      await db.execute(
          "CREATE TABLE IF NOT EXISTS facture_details(facture_detail_id INTEGER NOT NULL PRIMARY KEY, facture_detail_libelle TEXT, facture_detail_qte REAL, facture_detail_pu REAL, facture_detail_devise TEXT, facture_detail_create_At INTEGER,facture_detail_state TEXT, facture_id INTEGER)");
      await db.execute(
          "CREATE TABLE IF NOT EXISTS comptes(compte_id INTEGER NOT NULL PRIMARY KEY, compte_libelle TEXT, compte_devise TEXT,compte_status TEXT, compte_create_At INTEGER, compte_state TEXT)");
      await db.execute(
          "CREATE TABLE IF NOT EXISTS operations(operation_id INTEGER NOT NULL PRIMARY KEY,operation_libelle TEXT,operation_type TEXT,operation_montant REAL, operation_devise TEXT, operation_compte_id INTEGER, operation_facture_id INTEGER, operation_mode TEXT, operation_user_id INTEGER, operation_state TEXT, operation_create_At INTEGER)");
    } catch (err) {
      print("error from transaction");
    }
  }
}
