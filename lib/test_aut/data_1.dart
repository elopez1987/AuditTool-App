// Datos de Audit Tools: modelos, persistencia local y conciliación.
// Requiere en pubspec.yaml:  shared_preferences: ^2.2.0
import 'dart:convert';

import 'package:audit_tool/test_aut/DatabaseService.dart';
import 'package:shared_preferences/shared_preferences.dart';

const bool kBloquearAprobacionConDiferencias = false;

const modes = <String>['ROTATIVA', 'DEFINITIVA'];

/// Unidades de medida disponibles al planear un producto.
const unitOptions = <String>[
  'Cajas',
  'Piezas',
  'Paquetes',
  'Tarimas',
  'Kilos',
  'Litros',
];

// ───────────────────────── Modelos ─────────────────────────

class Product {
  final String sku, upc, name, unit;
  const Product(this.sku, this.upc, this.name, this.unit);

  bool matches(String code) {
    final value = code.trim().toUpperCase();
    return value.isNotEmpty &&
        (sku.toUpperCase() == value || upc.toUpperCase() == value);
  }

  Map<String, dynamic> toJson() => {
    'sku': sku,
    'upc': upc,
    'name': name,
    'unit': unit,
  };

  factory Product.fromJson(Map<String, dynamic> j) => Product(
    j['sku'] as String? ?? '',
    j['upc'] as String? ?? '',
    j['name'] as String? ?? '',
    j['unit'] as String? ?? 'Cajas',
  );
}

/// Cantidades planeadas. Son inmutables: la auditoría nunca las modifica.
class PlannedProduct {
  final Product product;
  final int rotativa;
  final int definitiva;
  const PlannedProduct(this.product, this.rotativa, this.definitiva);

  int expectedFor(String mode) => mode == 'ROTATIVA' ? rotativa : definitiva;

  Map<String, dynamic> toJson() => {
    'product': product.toJson(),
    'rotativa': rotativa,
    'definitiva': definitiva,
  };

  factory PlannedProduct.fromJson(Map<String, dynamic> j) => PlannedProduct(
    Product.fromJson(Map<String, dynamic>.from(j['product'] as Map)),
    j['rotativa'] as int? ?? 0,
    j['definitiva'] as int? ?? 0,
  );
}

class Trip {
  final String vale, ruta, operador, cortina;
  final List<PlannedProduct> plannedProducts;
  Trip(this.vale, this.ruta, this.operador, this.cortina, this.plannedProducts);

  Map<String, dynamic> toJson() => {
    'vale': vale,
    'ruta': ruta,
    'operador': operador,
    'cortina': cortina,
    'products': plannedProducts.map((p) => p.toJson()).toList(),
  };

  factory Trip.fromJson(Map<String, dynamic> j) => Trip(
    j['vale'] as String? ?? '',
    j['ruta'] as String? ?? '',
    j['operador'] as String? ?? '',
    j['cortina'] as String? ?? '',
    ((j['products'] as List?) ?? [])
        .map(
          (e) => PlannedProduct.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList(),
  );
}

/// valid  = recibido dentro de lo planeado.
/// excess = cantidad que excede lo planeado de un producto del vale (NC).
/// extra  = producto que no está en el vale (NC, lista de no planeados).
enum RecordKind { valid, excess, extra }

class AuditRecord {
  final String vale, mode, sku, name, motivo, unit;
  final int qty;
  final double temp;
  final bool photo;
  final RecordKind kind;
  final DateTime at;

  AuditRecord(
    this.vale,
    this.mode,
    this.sku,
    this.name,
    this.qty,
    this.temp, {
    this.motivo = '',
    this.photo = false,
    this.kind = RecordKind.valid,
    this.unit = 'Cajas',
    DateTime? at,
  }) : at = at ?? DateTime.now();

  bool get isNc => kind != RecordKind.valid;

  Map<String, dynamic> toJson() => {
    'vale': vale,
    'mode': mode,
    'sku': sku,
    'name': name,
    'motivo': motivo,
    'unit': unit,
    'qty': qty,
    'temp': temp,
    'photo': photo,
    'kind': kind.name,
    'at': at.toIso8601String(),
  };

  factory AuditRecord.fromJson(Map<String, dynamic> j) => AuditRecord(
    j['vale'] as String? ?? '',
    j['mode'] as String? ?? 'ROTATIVA',
    j['sku'] as String? ?? '',
    j['name'] as String? ?? '',
    j['qty'] as int? ?? 0,
    (j['temp'] as num? ?? 0).toDouble(),
    motivo: j['motivo'] as String? ?? '',
    photo: j['photo'] as bool? ?? false,
    kind: RecordKind.values.firstWhere(
      (k) => k.name == j['kind'],
      orElse: () => RecordKind.valid,
    ),
    unit: j['unit'] as String? ?? 'Cajas',
    at: DateTime.tryParse(j['at'] as String? ?? ''),
  );
}

// Catálogo demo que se conserva para el simulador de escaneo.
const products = <Product>[
  Product(
    'LAL-100101',
    '7501020540011',
    'Leche LALA Entera 1L (caja 12)',
    'Cajas',
  ),
  Product(
    'LAL-100102',
    '7501020540028',
    'Leche LALA Deslactosada 1L (caja 12)',
    'Cajas',
  ),
  Product(
    'LAL-100103',
    '7501020540035',
    'Leche LALA Light 1L (caja 12)',
    'Cajas',
  ),
  Product(
    'LAL-100104',
    '7501020540042',
    'Leche LALA Deslactosada Light 1L (caja 12)',
    'Cajas',
  ),
  Product(
    'LAL-200201',
    '7501020540059',
    'Yoghurt LALA Bebible Fresa 1L (caja 8)',
    'Cajas',
  ),
  Product(
    'LAL-200202',
    '7501020540066',
    'Yoghurt LALA Griego Natural 900g (caja 6)',
    'Cajas',
  ),
  Product(
    'LAL-300301',
    '7501020540073',
    'Crema LALA Ácida 200ml (caja 24)',
    'Cajas',
  ),
  Product(
    'LAL-300302',
    '7501020540080',
    'Queso Oaxaca LALA 400g (caja 10)',
    'Cajas',
  ),
  Product(
    'LAL-300303',
    '7501020540097',
    'Mantequilla LALA con Sal 90g (caja 40)',
    'Cajas',
  ),
  Product(
    'LAL-400401',
    '7501020540103',
    'Leche LALA Chocolatada 250ml (caja 27)',
    'Cajas',
  ),
];

const demoVales = <String>[];
const motivos = <String, String>{
  'frio': 'Desviación de Temperatura',
  'faltante': 'Faltante de Origen',
  'danado': 'Producto Dañado / Mermado',
  'error': 'Error de Despacho en Rampa',
};

// ───────────────────────── Estado en memoria ─────────────────────────

final List<Trip> plannedTrips = [];
final List<AuditRecord> records = [];

/// vale (MAYÚSCULAS) -> fecha de aprobación.
final Map<String, DateTime> approvals = {};

String _k(String vale) => vale.trim().toUpperCase();

Trip? findTrip(String vale) {
  final v = _k(vale);
  for (final trip in plannedTrips) {
    if (trip.vale.toUpperCase() == v) return trip;
  }
  return null;
}

Product? findProduct(String code) {
  for (final p in products) {
    if (p.matches(code)) return p;
  }
  for (final trip in plannedTrips) {
    for (final item in trip.plannedProducts) {
      if (item.product.matches(code)) return item.product;
    }
  }
  return null;
}

bool isApproved(String vale) => approvals.containsKey(_k(vale));

bool hasRecords(String vale) =>
    records.any((r) => r.vale.toUpperCase() == _k(vale));

// ───────────────────────── Persistencia local ─────────────────────────

const _kTrips = 'audit_trips_v1';
const _kRecords = 'audit_records_v1';
const _kApprovals = 'audit_approvals_v1';

/// Llamar una vez al iniciar la app (antes de runApp).
/* Future<void> loadData() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    plannedTrips
      ..clear()
      ..addAll(
        _decodeList(prefs.getString(_kTrips)).map((e) => Trip.fromJson(e)),
      );
    records
      ..clear()
      ..addAll(
        _decodeList(prefs.getString(_kRecords))
            .map((e) => AuditRecord.fromJson(e)),
      );
    approvals.clear();
    final raw = prefs.getString(_kApprovals);
    if (raw != null) {
      (jsonDecode(raw) as Map).forEach((k, v) {
        final d = DateTime.tryParse(v as String);
        if (d != null) approvals[k as String] = d;
      });
    }
  } catch (_) {
    // Datos corruptos: se arranca vacío en lugar de tumbar la app.
  }
} */
/* 
Future<void> loadData() async {
  try {
    final prefs = await SharedPreferences.getInstance();

    // Cargar viajes planeados
    final tripsRaw = prefs.getString(_kTrips);
    if (tripsRaw != null) {
      plannedTrips.clear();
      plannedTrips.addAll(_decodeList(tripsRaw).map((e) => Trip.fromJson(e)));
    }

    // Cargar registros de auditoría
    final recordsRaw = prefs.getString(_kRecords);
    if (recordsRaw != null) {
      records.clear();
      records.addAll(
        _decodeList(recordsRaw).map((e) => AuditRecord.fromJson(e)),
      );
    }

    // Cargar aprobaciones
    approvals.clear();
    final raw = prefs.getString(_kApprovals);
    if (raw != null) {
      (jsonDecode(raw) as Map).forEach((k, v) {
        final d = DateTime.tryParse(v as String);
        if (d != null) approvals[k as String] = d;
      });
    }
  } catch (e) {
    // En caso de error de lectura, se inicializa vacío sin tumbar la app
    print('Error al cargar datos locales: $e');
  }
} */

Future<void> loadData() async {
  try {
    await DatabaseService.instance.loadAllDataIntoMemory(
      plannedTrips,
      records,
      approvals,
    );
  } catch (e) {
    print('Error al cargar datos desde SQLite: $e');
  }
}

Future<void> saveTrip(Trip trip) async {
  await DatabaseService.instance.saveTripDB(trip);
  plannedTrips.removeWhere((x) => x.vale.toUpperCase() == _k(trip.vale));
  plannedTrips.add(trip);
}

Future<void> deleteTrip(String vale) async {
  final v = _k(vale);
  await DatabaseService.instance.deleteTripDB(v);
  plannedTrips.removeWhere((x) => x.vale.toUpperCase() == v);
  records.removeWhere((r) => r.vale.toUpperCase() == v);
  approvals.remove(v);
}

Future<void> addRecords(List<AuditRecord> list) async {
  await DatabaseService.instance.addRecordsDB(list);
  records.addAll(list);
}

Future<void> approveVale(String vale) async {
  final v = _k(vale);
  await DatabaseService.instance.approveValeDB(v);
  approvals[v] = DateTime.now();
}

List<Map<String, dynamic>> _decodeList(String? raw) {
  if (raw == null || raw.isEmpty) return const [];
  return (jsonDecode(raw) as List)
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList();
}

Future<void> persist() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    _kTrips,
    jsonEncode(plannedTrips.map((t) => t.toJson()).toList()),
  );
  await prefs.setString(
    _kRecords,
    jsonEncode(records.map((r) => r.toJson()).toList()),
  );
  await prefs.setString(
    _kApprovals,
    jsonEncode(approvals.map((k, v) => MapEntry(k, v.toIso8601String()))),
  );
}

// ───────────────────────── Operaciones ─────────────────────────

/// Crea o reemplaza una planeación (mismo nombre de vale).
/* Future<void> saveTrip(Trip trip) async {
  plannedTrips.removeWhere((x) => x.vale.toUpperCase() == _k(trip.vale));
  plannedTrips.add(trip);
  await persist();
} */

/// Elimina el vale junto con sus capturas, NC y aprobación.
/* Future<void> deleteTrip(String vale) async {
  final v = _k(vale);
  plannedTrips.removeWhere((x) => x.vale.toUpperCase() == v);
  records.removeWhere((r) => r.vale.toUpperCase() == v);
  approvals.remove(v);
  await persist();
} */

/* Future<void> addRecords(List<AuditRecord> list) async {
  records.addAll(list);
  await persist();
}

Future<void> approveVale(String vale) async {
  approvals[_k(vale)] = DateTime.now();
  await persist();
} */

// ───────────────────────── Conciliación ─────────────────────────

/// Una línea = un producto planeado en un modo (rotativa o definitiva).
class ReconLine {
  final PlannedProduct item;
  final String mode;
  final int expected; // lo planeado (nunca se modifica)
  final int received; // recibido válido (acotado a lo planeado)
  final int excess; // excedente enviado a NC (no se mezcla con received)
  const ReconLine(
    this.item,
    this.mode,
    this.expected,
    this.received,
    this.excess,
  );

  int get missing => expected > received ? expected - received : 0;
  bool get complete => missing == 0;
  String get unit => item.product.unit;
}

/* class Reconciliation {
  final List<ReconLine> lines;
  final List<AuditRecord> unplanned; // productos fuera del vale
  const Reconciliation(this.lines, this.unplanned);

  bool get hasMissing => lines.any((l) => l.missing > 0);
  bool get hasExcess => lines.any((l) => l.excess > 0);
  bool get hasUnplanned => unplanned.isNotEmpty;

  bool get canApprove {
    if (lines.isEmpty || hasMissing) return false;
    if (kBloquearAprobacionConDiferencias && (hasExcess || hasUnplanned)) {
      return false;
    }
    return true;
  }

  List<String> get blockers {
    final out = <String>[];
    final miss = lines.where((l) => l.missing > 0).length;
    if (miss > 0) out.add('$miss línea(s) con faltantes.');
    if (kBloquearAprobacionConDiferencias) {
      final ex = lines.where((l) => l.excess > 0).length;
      if (ex > 0) out.add('$ex línea(s) con cantidades excedentes (NC).');
      if (hasUnplanned) {
        out.add('${unplanned.length} registro(s) de productos no planeados.');
      }
    }
    return out;
  }
} */

class Reconciliation {
  final List<ReconLine> lines;
  final List<AuditRecord> unplanned; // productos fuera del vale
  const Reconciliation(this.lines, this.unplanned);

  bool get hasMissing => lines.any((l) => l.missing > 0);
  bool get hasExcess => lines.any((l) => l.excess > 0);
  bool get hasUnplanned => unplanned.isNotEmpty;

  // 2. Permitir la aprobación general siempre que existan líneas de productos,
  // respetando la bandera global de bloqueo.
  bool get canApprove {
    if (lines.isEmpty) return false;
    if (kBloquearAprobacionConDiferencias) {
      if (hasMissing || hasExcess || hasUnplanned) return false;
    }
    return true; // Ahora se habilitará el botón aunque haya diferencias
  }

  List<String> get blockers {
    final out = <String>[];
    final miss = lines.where((l) => l.missing > 0).length;
    if (miss > 0)
      out.add('$miss línea(s) con faltantes (se guardarán en el registro).');
    final ex = lines.where((l) => l.excess > 0).length;
    if (ex > 0) out.add('$ex línea(s) con excedentes (NC).');
    if (hasUnplanned) {
      out.add(
        '${unplanned.length} registro(s) de productos no planeados (NC).',
      );
    }
    return out;
  }
}

Reconciliation reconcile(Trip trip) {
  final v = _k(trip.vale);
  final mine = records.where((r) => r.vale.toUpperCase() == v).toList();
  final lines = <ReconLine>[];
  for (final item in trip.plannedProducts) {
    for (final mode in modes) {
      int sum(RecordKind k) => mine
          .where(
            (r) => r.kind == k && r.mode == mode && r.sku == item.product.sku,
          )
          .fold<int>(0, (s, r) => s + r.qty);
      final expected = item.expectedFor(mode);
      final received = sum(RecordKind.valid);
      final excess = sum(RecordKind.excess);
      if (expected > 0 || received > 0 || excess > 0) {
        lines.add(ReconLine(item, mode, expected, received, excess));
      }
    }
  }

  // 🔹 MODIFICACIÓN: Incluir tanto los productos extra como los excedentes en la sección NC al final
  final unplanned = mine
      .where((r) => r.kind == RecordKind.extra || r.kind == RecordKind.excess)
      .toList();

  return Reconciliation(lines, unplanned);
}
