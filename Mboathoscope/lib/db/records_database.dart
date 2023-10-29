import 'package:mboathoscope/models/records.dart' ;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class recordsDatabase{
  static final recordsDatabase instance = recordsDatabase._init();
  static Database? _database;
  recordsDatabase._init();


  Future<Database> get database async {
    if(_database != null) return _database!;
    _database = await _initDB('recordings.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB, );
  }
  Future _createDB(Database db, dynamic version)async{
    final textType = 'TEXT NOT NULL';

    await db.execute('''
        "CREATE DATABASE ${records} (
        "${RFields.id} $textType,"
        "${RFields.pathname} $textType,"
        "${RFields.filename} $textType,"
        "${RFields.dateTime} $textType,"
        "${RFields.audio} "
        ")''');

  }

  //From here on are CRUDE operations(functions)

  //create
  Future<Recordings> create(Recordings recording) async{
    final db = await instance.database;
    final id = await db.insert(records, recording.toJson());
    return recording.copy(id: id.toString());
  }

  //read
  Future<Recordings> read(int id) async {
    final db = await instance.database;
    // final orderBy = '${RFields.dateTime} ASC';
    // final results = await db.rawQuery('SELECT * FROM ')
    final maps = await db.query(records,
        columns: RFields.values,
        where: '${RFields.id} = ?',
        whereArgs: [id]
    );
    if(maps.isNotEmpty){
      return Recordings.fromJson(maps.first);
    }else{
      throw Exception('ID $id not found');
    }
  }

  //readAll
  Future<List<Recordings>> readAll() async {
    final db = await instance.database;
    final results = await db.query(records, orderBy: '${RFields.dateTime} DESC');

    return results.map((json) => Recordings.fromJson(json)).toList();
  }

  //update
  Future<int> update(Recordings recording) async {
    final db = await instance.database;
    return db.update(records,
        recording.toJson(),
        where: '${RFields.id} = ?',
        whereArgs: [recording.id]
    );
  }

  //delete
  Future<int> delete(int id) async {
    final db = await instance.database;
    return db.delete(records,
        where: '${RFields.id} = ?',
        whereArgs: [id]
    );
  }
  Future close() async{
    final db = await instance.database;
    db.close();
  }
}