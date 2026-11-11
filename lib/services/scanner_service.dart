// Único punto que toca el plugin del escáner. Si tu versión expone otro nombre de clase,
// solo cambia aquí (p. ej. FlutterBarcodeScanner <-> FlutterBarcodeScannerUpdate).
import 'package:flutter_barcode_scanner_update/flutter_barcode_scanner_update.dart';

class ScannerService {
  /// Devuelve el código leído, o null si el usuario canceló.
  static Future<String?> scan() async {
    final r = await FlutterBarcodeScanner.scanBarcode(
      '#DC2626', // color de la línea
      'Cancelar',
      true, // flash
      ScanMode.BARCODE,
    );
    if (r == '-1' || r.trim().isEmpty) return null; // '-1' = cancelado
    return r.trim();
  }
}
