import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRService {
  static final TextRecognizer _textRecognizer = TextRecognizer();
  static const MethodChannel _channel = MethodChannel('ar_smart_study/ocr');

  /// Суреттен мәтінді тану
  static Future<String> recognizeText(String imagePath) async {
    String nativeText = '';
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        final text = await _channel.invokeMethod<String>(
          'recognizeCyrillicText',
          {'imagePath': imagePath},
        );
        nativeText = text?.trim() ?? '';
      } catch (_) {
        // Fall back to ML Kit if native OCR is unavailable on a device.
      }
    }

    final mlKitText = await _recognizeWithMlKit(imagePath);

    if (nativeText.isNotEmpty && mlKitText.isNotEmpty) {
      if (_normalizeForCompare(nativeText) == _normalizeForCompare(mlKitText)) {
        return nativeText;
      }

      return '''
OCR нұсқа 1:
$nativeText

OCR нұсқа 2:
$mlKitText
'''
          .trim();
    }

    if (nativeText.isNotEmpty) return nativeText;
    return mlKitText;
  }

  static Future<String> _recognizeWithMlKit(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizedText = await _textRecognizer.processImage(inputImage);

    final StringBuffer buffer = StringBuffer();
    for (TextBlock block in recognizedText.blocks) {
      for (TextLine line in block.lines) {
        buffer.writeln(line.text);
      }
      buffer.writeln();
    }

    return buffer.toString().trim();
  }

  static String _normalizeForCompare(String text) {
    return text.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Суреттен мәтін блоктарын тану (AR overlay үшін позициясымен)
  static Future<List<RecognizedBlock>> recognizeTextWithPositions(
      String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizedText = await _textRecognizer.processImage(inputImage);

    final List<RecognizedBlock> blocks = [];
    for (TextBlock block in recognizedText.blocks) {
      blocks.add(RecognizedBlock(
        text: block.text,
        boundingBox: block.boundingBox,
        lines: block.lines.map((l) => l.text).toList(),
      ));
    }

    return blocks;
  }

  static void dispose() {
    _textRecognizer.close();
  }
}

class RecognizedBlock {
  final String text;
  final Rect boundingBox;
  final List<String> lines;

  RecognizedBlock({
    required this.text,
    required this.boundingBox,
    required this.lines,
  });
}
