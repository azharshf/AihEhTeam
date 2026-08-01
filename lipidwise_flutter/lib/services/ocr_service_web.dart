// Real, web-only OCR bridge. This calls into the Tesseract.js engine loaded
// in web/index.html via `window.lipidwiseRunOcr`, which actually decodes the
// image and runs text recognition on its pixels — there is no hardcoded or
// simulated result here.
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'ocr_result.dart';

@JS('lipidwiseRunOcr')
external JSPromise<JSString> _lipidwiseRunOcr(JSString dataUrl);

bool get isOcrSupported => true;

Future<OcrResult> recognizeText(Uint8List imageBytes, String mimeType) async {
  try {
    final base64Data = base64Encode(imageBytes);
    final dataUrl = 'data:$mimeType;base64,$base64Data';

    final jsText = await _lipidwiseRunOcr(dataUrl.toJS).toDart
        .timeout(const Duration(seconds: 45));
    final text = jsText.toDart.trim();

    if (text.isEmpty) {
      return const OcrResult(
        success: false,
        rawText: '',
        error: 'The OCR engine could not find any readable text in this image.',
      );
    }
    return OcrResult(success: true, rawText: text);
  } catch (e) {
    return OcrResult(
      success: false,
      rawText: '',
      error: 'OCR engine error: $e',
    );
  }
}
