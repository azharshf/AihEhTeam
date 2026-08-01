// Fallback implementation used on platforms that don't have the browser
// (and therefore no Tesseract.js bridge) — Android/iOS/desktop native builds.
// It never fabricates data; it honestly reports OCR isn't available there.
import 'dart:typed_data';

import 'ocr_result.dart';

bool get isOcrSupported => false;

Future<OcrResult> recognizeText(Uint8List imageBytes, String mimeType) async {
  return const OcrResult(
    success: false,
    rawText: '',
    error: 'On-device OCR currently only runs in the web build of LipidWise AI.',
  );
}
