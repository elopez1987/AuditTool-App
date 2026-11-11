import 'dart:async';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'data_1.dart'; // Manteniendo tus modelos actuales

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('audit_tools.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // Tabla de Viajes / Vales
    await db.execute('''
      CREATE TABLE trips (
        vale TEXT PRIMARY KEY,
        ruta TEXT,
        operador TEXT,
        cortina TEXT
      )
    ''');

    // Tabla de Productos Planeados asociados a un Vale
    await db.execute('''
      CREATE TABLE planned_products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vale TEXT,
        sku TEXT,
        upc TEXT,
        name TEXT,
        unit TEXT,
        rotativa INTEGER,
        definitiva INTEGER,
        FOREIGN KEY (vale) REFERENCES trips (vale) ON DELETE CASCADE
      )
    ''');

    // Tabla de Registros de Auditoría y Capturas
    await db.execute('''
      CREATE TABLE audit_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vale TEXT,
        mode TEXT,
        sku TEXT,
        name TEXT,
        qty INTEGER,
        temp REAL,
        motivo TEXT,
        photo INTEGER,
        kind TEXT,
        unit TEXT,
        at TEXT,
        FOREIGN KEY (vale) REFERENCES trips (vale) ON DELETE CASCADE
      )
    ''');

    // Tabla de Aprobaciones de Vales
    await db.execute('''
      CREATE TABLE approvals (
        vale TEXT PRIMARY KEY,
        approved_at TEXT
      )
    ''');
  }

  // ──────────────────────── Operaciones de Base de Datos ────────────────────────

  Future<void> saveTripDB(Trip trip) async {
    final db = await instance.database;

    // Insertar o actualizar el viaje principal
    await db.insert('trips', {
      'vale': trip.vale,
      'ruta': trip.ruta,
      'operador': trip.operador,
      'cortina': trip.cortina,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    // Limpiar productos planeados anteriores para este vale y reinsertar
    await db.delete(
      'planned_products',
      where: 'vale = ?',
      whereArgs: [trip.vale],
    );
    for (var item in trip.plannedProducts) {
      await db.insert('planned_products', {
        'vale': trip.vale,
        'sku': item.product.sku,
        'upc': item.product.upc,
        'name': item.product.name,
        'unit': item.product.unit,
        'rotativa': item.rotativa,
        'definitiva': item.definitiva,
      });
    }
  }

  Future<void> deleteTripDB(String vale) async {
    final db = await instance.database;
    await db.delete('trips', where: 'vale = ?', whereArgs: [vale]);
    await db.delete('planned_products', where: 'vale = ?', whereArgs: [vale]);
    await db.delete('audit_records', where: 'vale = ?', whereArgs: [vale]);
    await db.delete('approvals', where: 'vale = ?', whereArgs: [vale]);
  }

  Future<void> addRecordsDB(List<AuditRecord> list) async {
    final db = await instance.database;
    for (var r in list) {
      await db.insert('audit_records', {
        'vale': r.vale,
        'mode': r.mode,
        'sku': r.sku,
        'name': r.name,
        'qty': r.qty,
        'temp': r.temp,
        'motivo': r.motivo,
        'photo': r.photo ? 1 : 0,
        'kind': r.kind.name,
        'unit': r.unit,
        'at': r.at.toIso8601String(),
      });
    }
  }

  Future<void> approveValeDB(String vale) async {
    final db = await instance.database;
    await db.insert('approvals', {
      'vale': vale.trim().toUpperCase(),
      'approved_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> loadAllDataIntoMemory(
    List<Trip> plannedTrips,
    List<AuditRecord> records,
    Map<String, DateTime> approvals,
  ) async {
    final db = await instance.database;

    // 1. Cargar viajes y sus productos planeados
    plannedTrips.clear();
    final tripMaps = await db.query('trips');
    for (var tMap in tripMaps) {
      String vale = tMap['vale'] as String;

      final productMaps = await db.query(
        'planned_products',
        where: 'vale = ?',
        whereArgs: [vale],
      );

      List<PlannedProduct> plannedProducts = productMaps.map((pMap) {
        Product product = Product(
          pMap['sku'] as String,
          pMap['upc'] as String,
          pMap['name'] as String,
          pMap['unit'] as String,
        );
        return PlannedProduct(
          product,
          pMap['rotativa'] as int,
          pMap['definitiva'] as int,
        );
      }).toList();

      plannedTrips.add(
        Trip(
          vale,
          tMap['ruta'] as String,
          tMap['operador'] as String,
          tMap['cortina'] as String,
          plannedProducts,
        ),
      );
    }

    // 2. Cargar registros de auditoría
    records.clear();
    final recordMaps = await db.query('audit_records');
    for (var rMap in recordMaps) {
      records.add(
        AuditRecord(
          rMap['vale'] as String,
          rMap['mode'] as String,
          rMap['sku'] as String,
          rMap['name'] as String,
          rMap['qty'] as int,
          rMap['temp'] as double,
          motivo: rMap['motivo'] as String,
          photo: (rMap['photo'] as int) == 1,
          kind: RecordKind.values.firstWhere(
            (k) => k.name == rMap['kind'],
            orElse: () => RecordKind.valid,
          ),
          unit: rMap['unit'] as String,
          at: DateTime.tryParse(rMap['at'] as String),
        ),
      );
    }

    // 3. Cargar aprobaciones
    approvals.clear();
    final approvalMaps = await db.query('approvals');
    for (var aMap in approvalMaps) {
      final v = aMap['vale'] as String;
      final d = DateTime.tryParse(aMap['approved_at'] as String);
      if (d != null) {
        approvals[v] = d;
      }
    }
  }
}
