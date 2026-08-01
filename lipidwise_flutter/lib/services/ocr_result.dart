/// Outcome of a real OCR pass over a captured/selected image.
///
/// [success] is only true when the OCR engine actually returned recognizable
/// text — there is no simulated/fallback "always succeeds" path.
class OcrResult {
  final bool success;
  final String rawText;
  final String? error;

  const OcrResult({required this.success, required this.rawText, this.error});
}
