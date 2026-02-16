import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/modelo_entrega.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'hospital_protocolo_v2.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE protocolos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        dataHora TEXT,
        assinaturaBytes BLOB,
        titulo TEXT,
        status INTEGER DEFAULT 0 
      )
    ''');

    await db.execute('''
      CREATE TABLE itens(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        protocolo_id INTEGER,
        nomePaciente TEXT,
        prontuario TEXT,
        tipoDocumento TEXT,
        volume TEXT,
        comCapa INTEGER,
        FOREIGN KEY (protocolo_id) REFERENCES protocolos (id) ON DELETE CASCADE
      )
    ''');
  }

  // --- MÉTODOS DE AÇÃO ---

  Future<void> salvarProtocoloCompleto(
      Protocolo protocolo, List<ItemEntrega> itens) async {
    Database db = await database;
    await db.transaction((txn) async {
      int protocoloId = await txn.insert('protocolos', protocolo.toMap());
      for (var item in itens) {
        final itemComVinculo = ItemEntrega(
          protocoloId: protocoloId,
          nomePaciente: item.nomePaciente,
          prontuario: item.prontuario,
          tipoDocumento: item.tipoDocumento,
        );
        await txn.insert('itens', itemComVinculo.toMap());
      }
    });
  }

  Future<List<Protocolo>> getProtocolos() async {
    Database db = await database;
    final List<Map<String, dynamic>> mapsProtocolos =
        await db.query('protocolos', orderBy: "id DESC");

    List<Protocolo> listaCompleta = [];

    for (var mapProto in mapsProtocolos) {
      Protocolo p = Protocolo.fromMap(mapProto);
      final List<Map<String, dynamic>> mapsItens =
          await db.query('itens', where: 'protocolo_id = ?', whereArgs: [p.id]);

      List<ItemEntrega> itensDoProtocolo = List.generate(mapsItens.length, (i) {
        return ItemEntrega.fromMap(mapsItens[i]);
      });

      listaCompleta.add(Protocolo(
        id: p.id,
        dataHora: p.dataHora,
        assinaturaBytes: p.assinaturaBytes,
        itens: itensDoProtocolo,
      ));
    }
    return listaCompleta;
  }

  // --- NOVO MÉTODO: EXCLUIR ---
  Future<void> excluirProtocolo(int id) async {
    Database db = await database;
    // Como configuramos ON DELETE CASCADE, isso apaga os itens automaticamente
    await db.delete('protocolos', where: 'id = ?', whereArgs: [id]);
  }

  //  Novo método para coletar assinatura depois de ja ter preenchido e salvado protocolo
  Future<void> assinarProtocolo(int id, List<int> assinatura) async {
    Database db = await database;
    await db.update(
      'protocolos',
      {
        'assinaturaBytes': assinatura,
        'status': 1 // Marca como Finalizado
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
