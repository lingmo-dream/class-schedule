// 图片 OCR 服务：使用 HTTP 上传图片字节，返回识别出的课表文字。
import 'dart:convert';

import 'package:http/http.dart' as http;

class ImageOcrResult {
  const ImageOcrResult({required this.text, this.lines = const [], this.error});

  final String text;
  final List<OcrLine> lines;
  final String? error;

  bool get isSuccess => error == null && text.trim().isNotEmpty;
}

class OcrLine {
  const OcrLine({
    required this.text,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final String text;
  final double left;
  final double top;
  final double width;
  final double height;

  double get centerX => left + width / 2;
}

class ImageOcrService {
  const ImageOcrService({
    this.endpoint = defaultEndpoint,
    this.apiKey = defaultApiKey,
  });

  static const String defaultEndpoint = 'https://api.ocr.space/parse/image';
  // 公共演示密钥有配额限制，正式环境请替换为自己的 OCR 服务配置。
  static const String defaultApiKey = 'helloworld';

  final String endpoint;
  final String apiKey;

  Future<ImageOcrResult> recognize(
    List<int> bytes, {
    String fileName = 'schedule.png',
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(endpoint))
        ..fields['apikey'] = apiKey
        ..fields['language'] = 'chs'
        ..fields['OCREngine'] = '2'
        ..fields['isOverlayRequired'] = 'true'
        ..fields['detectOrientation'] = 'true'
        ..fields['scale'] = 'true'
        ..fields['isTable'] = 'true'
        ..files.add(
          http.MultipartFile.fromBytes('file', bytes, filename: fileName),
        );
      final response = await request.send().timeout(
        const Duration(seconds: 90),
      );
      final body = await response.stream.bytesToString();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return ImageOcrResult(
          text: '',
          error: 'OCR 服务返回 HTTP ${response.statusCode}',
        );
      }
      final json = jsonDecode(body) as Map<String, dynamic>;
      if (json['IsErroredOnProcessing'] == true) {
        final messages = (json['ErrorMessage'] as List<dynamic>? ?? const [])
            .join('；');
        return ImageOcrResult(
          text: '',
          error: messages.isEmpty ? 'OCR 处理失败' : messages,
        );
      }
      final results = (json['ParsedResults'] as List<dynamic>? ?? const []);
      final lines = <OcrLine>[];
      for (final result in results.whereType<Map>()) {
        final overlay = result['TextOverlay'];
        final rawLines = overlay is Map ? overlay['Lines'] : null;
        for (final rawLine in (rawLines as List<dynamic>? ?? const [])) {
          if (rawLine is! Map) continue;
          final words = rawLine['Words'] as List<dynamic>? ?? const [];
          final lineText =
              rawLine['LineText'] as String? ??
              words
                  .whereType<Map>()
                  .map((word) => word['WordText'] as String? ?? '')
                  .join();
          if (lineText.trim().isEmpty) continue;
          final left = _number(rawLine['MinLeft'] ?? rawLine['Left']);
          final top = _number(rawLine['MinTop'] ?? rawLine['Top']);
          final width = _number(rawLine['MaxWidth'] ?? rawLine['Width']);
          final height = _number(rawLine['MaxHeight'] ?? rawLine['Height']);
          lines.add(
            OcrLine(
              text: lineText,
              left: left,
              top: top,
              width: width,
              height: height,
            ),
          );
        }
      }
      final text = results
          .whereType<Map>()
          .map((item) => item['ParsedText'] as String? ?? '')
          .join('\n');
      return ImageOcrResult(
        text: text,
        lines: lines,
        error: text.trim().isEmpty ? 'OCR 未识别到文字' : null,
      );
    } on FormatException {
      return const ImageOcrResult(text: '', error: 'OCR 返回内容格式无效');
    } on Exception catch (error) {
      return ImageOcrResult(text: '', error: 'OCR 请求失败：$error');
    }
  }

  static double _number(dynamic value) => value is num ? value.toDouble() : 0;
}
