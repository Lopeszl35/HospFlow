import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'modelo_entrega.dart';

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
      onConfigure: _onConfigure, // Importante para ativar chaves estrangeiras
    );
  }

  // Ativa o suporte a Foreign Keys (Chaves Estrangeiras) no SQLite
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Tabela Pai (O Protocolo)
    await db.execute('''
      CREATE TABLE protocolos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        dataHora TEXT,
        assinaturaBytes BLOB
      )
    ''');

    // 2. Tabela Filho (Os Itens)
    // ON DELETE CASCADE significa: Se apagar o protocolo, apaga os itens dele automaticamente
    await db.execute('''
      CREATE TABLE itens(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        protocolo_id INTEGER,
        nomePaciente TEXT,
        prontuario TEXT,
        tipoDocumento TEXT,
        FOREIGN KEY (protocolo_id) REFERENCES protocolos (id) ON DELETE CASCADE
      )
    ''');
  }

  // --- MÉTODOS DE AÇÃO ---

  // Salvar um Protocolo COMPLETO (Pai + Filhos) em uma transação segura
  Future<void> salvarProtocoloCompleto(
      Protocolo protocolo, List<ItemEntrega> itens) async {
    Database db = await database;

    // Transaction garante que ou salva TUDO ou não salva NADA (segurança de dados)
    await db.transaction((txn) async {
      // 1. Salva o Protocolo e pega o ID gerado (Ex: Protocolo #10)
      int protocoloId = await txn.insert('protocolos', protocolo.toMap());

      // 2. Salva cada item ligando ao ID do protocolo
      for (var item in itens) {
        // Cria uma cópia do item, mas agora com o ID do pai
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

  // Buscar todos os protocolos com seus itens (Para a tela inicial)
  Future<List<Protocolo>> getProtocolos() async {
    Database db = await database;

    // Busca os protocolos (do mais novo para o mais antigo)
    final List<Map<String, dynamic>> mapsProtocolos =
        await db.query('protocolos', orderBy: "id DESC");

    List<Protocolo> listaCompleta = [];

    for (var mapProto in mapsProtocolos) {
      Protocolo p = Protocolo.fromMap(mapProto);

      // Para cada protocolo, busca os itens dele
      final List<Map<String, dynamic>> mapsItens =
          await db.query('itens', where: 'protocolo_id = ?', whereArgs: [p.id]);

      // Cria o objeto final com a lista de itens dentro
      List<ItemEntrega> itensDoProtocolo = List.generate(mapsItens.length, (i) {
        return ItemEntrega.fromMap(mapsItens[i]);
      });

      // Reconstrói o protocolo adicionando os itens
      listaCompleta.add(Protocolo(
        id: p.id,
        dataHora: p.dataHora,
        assinaturaBytes: p.assinaturaBytes,
        itens: itensDoProtocolo,
      ));
    }

    return listaCompleta;
  }
}
