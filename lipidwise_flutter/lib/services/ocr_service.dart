import 'dart:typed_data';

import 'ocr_result.dart';
import 'ocr_service_stub.dart' if (dart.library.html) 'ocr_service_web.dart' as platform;

export 'ocr_result.dart';

/// Thin façade over the platform-specific OCR bridge.
///
/// On the web build this actually runs Tesseract.js against the real image
/// bytes the user captured or selected — it does not return canned data.
class OcrService {
  static bool get isSupported => platform.isOcrSupported;

  static Future<OcrResult> recognizeText(
    Uint8List imageBytes, {
    String mimeType = 'image/jpeg',
  }) {
    return platform.recognizeText(imageBytes, mimeType);
  }
}
