import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerService {
  // utility to extract first non-empty rawValue
  String extractCode(Barcode barcode) {
    return barcode.rawValue ?? '';
  }

  String extractFromCapture(BarcodeCapture capture) {
    for (final b in capture.barcodes) {
      final v = b.rawValue;
      if (v != null && v.trim().isNotEmpty) return v.trim();
    }
    return '';
  }
}
