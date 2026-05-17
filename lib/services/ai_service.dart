import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:ar_ai_smart_study/utils/constants.dart';

class ScanAnalysis {
  final String cleanedText;
  final String explanation;

  const ScanAnalysis({
    required this.cleanedText,
    required this.explanation,
  });
}

class AIService extends ChangeNotifier {
  bool _isLoading = false;
  String? _lastExplanation;
  String? _error;

  bool get isLoading => _isLoading;
  String? get lastExplanation => _lastExplanation;
  String? get error => _error;
  bool get isConfigured => AppConstants.aiBackendUrl.trim().isNotEmpty;

  /// OCR мәтінін түзетіп, нақты сұраққа/тапсырмаға жауап беру
  Future<ScanAnalysis> analyzeScan(
    String rawRecognizedText, {
    String language = 'auto',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final responseLanguage = _resolveLanguage(language, rawRecognizedText);
      final prompt = _buildScanAnalysisPrompt(
        rawRecognizedText,
        responseLanguage,
      );
      final responseText = await _callAI(prompt);
      final analysis = _parseScanAnalysis(responseText, rawRecognizedText);
      _lastExplanation = analysis.explanation;
      _isLoading = false;
      notifyListeners();
      return analysis;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Танылған мәтінге AI түсіндірме жасау
  Future<String> getExplanation(
    String recognizedText, {
    String language = 'auto',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final responseLanguage = _resolveLanguage(language, recognizedText);
      final prompt = _buildPrompt(recognizedText, responseLanguage);
      final explanation = await _callAI(prompt);
      _lastExplanation = explanation;
      _isLoading = false;
      notifyListeners();
      return explanation;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Қосымша сұрақ қою
  Future<String> askFollowUp(
    String originalText,
    String explanation,
    String question, {
    String language = 'auto',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final responseLanguage = _resolveLanguage(
        language,
        question,
        originalText,
      );
      final langInstruction = _languageInstruction(responseLanguage);
      final prompt = '''
Сен — оқушыларға көмектесетін AI-мұғалімсің.
Сенің міндетің — дайын шаблонды қайталау емес, нақты сканерленген мәтінді түсініп, оқушының сұрағына дәл жауап беру.

Бұрынғы мәтін:
$originalText

Бұрынғы түсіндірме:
$explanation

Оқушының сұрағы:
$question

Осы сұраққа қарапайым тілмен, оқушыға түсінікті етіп жауап бер.
$langInstruction
Қажет болса мысал немесе формула қос.
Сұрақ түсініксіз болса, нақтылау сұрағын қой.
Жауапты бос жалпы сөздермен емес, сұрақтағы мәселені тікелей шешуден баста.
Егер OCR мәтінді қате немесе латынша транслитерациямен таныса, мағынасын сақтап түзетіп түсіндір.
''';

      final answer = await _callAI(prompt);
      _isLoading = false;
      notifyListeners();
      return answer;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  String _buildPrompt(String text, String language) {
    final langInstruction = _languageInstruction(language);

    return '''
Сен — оқушыларға көмектесетін AI-мұғалімсің.
Сен дайын шаблон жазбайсың және мәтінде жоқ нәрсені ойдан қоспайсың.
Сканерленген мәтінді алдымен мұқият оқып, оның нақты түрін анықтайсың.

Оқушы камерамен мына мәтінді сканерледі:
---
$text
---

Қатаң ережелер:
1. Алдымен мәтіннің түрін анықта: жай оқу мәтіні, анықтама, ереже, тарихи/ғылыми мәтін, сұрақ, тест, математикалық есеп, физика/химия есебі немесе басқа түр.
2. Егер мәтін жай абзац, теория, анықтама немесе оқу материалы болса, оны дәл сол тақырып бойынша түсіндір. Оны математикалық есеп деп санама.
3. Егер нақты есеп шарттары, сандар, теңдеу, сұрақ белгісі немесе "табыңыз/есептеңіз/дәлелдеңіз/шешіңіз" сияқты тапсырма анық көрінсе ғана шешім қадамдарын көрсет.
4. Формула тек мәтінде формула болса немесе тақырыпты түсіндіруге шынымен керек болса ғана қосылады.
5. OCR қате таныған сияқты болса, ең ықтимал дұрыс мәтінді қалпына келтіріп түсіндір, бірақ сенімсіз жерін қысқаша белгіле.
6. Жауапты сканерленген мәтіннің нақты мазмұнынан баста. Жалпы шаблон немесе ойдан шығарылған есеп жазба.

Жауап құрылымы:
## Бұл не туралы
Мәтіннің түрі мен тақырыбын 1-2 сөйлеммен айт.

## Түсіндірме
Нақты мәтіндегі негізгі ойларды түсіндір.

## Маңыздысы
Есте сақтайтын негізгі пункттерді қысқа жаз.

Егер бұл шынымен есеп болса, қосымша "## Шешімі" бөлімін қосып, қадаммен шығар.

$langInstruction
Қарапайым тілмен, оқушыға түсінікті етіп жаз.
Жалпы фразалармен шектелме: мәтіндегі нақты ұғымдарды, сандарды, терминдерді қолдан.
Егер сканерленген мәтін қазақша немесе орысша болса, оны дұрыс түсініп, жауапта кириллицаны сақта.
Егер OCR қазақша/орысша мәтінді латынша транслитерацияға ұқсатып таныса, мағынасын кириллицаға келтіріп түсіндір.
Markdown формат қолдан.
''';
  }

  String _buildScanAnalysisPrompt(String text, String language) {
    final langInstruction = _languageInstruction(language);

    return '''
Сен — сканнан алынған мәтінді түсінетін және нақты жауап беретін AI-мұғалімсің.
Сенің міндетің:
1. OCR қателерін түзетіп, суреттегі мәтінді мүмкіндігінше дұрыс қалпына келтіру.
2. Егер мәтін сұрақ болса, сұраққа бірден жауап беру.
3. Егер мәтін есеп/тапсырма болса, оны шешу.
4. Егер мәтін теория/абзац болса, қысқа әрі нақты түсіндіру.

Маңызды:
- Скандағы мәтінді жай көшіріп берме. Оқушыға керек жауапты бер.
- "Как зовут по настоящему Абая?" сияқты сұрақ болса, жауап: "Настоящее имя Абая — Ибрагим Кунанбаев." деп нақты жауап бер.
- Математикалық есеп болса, шартын қалпына келтіріп, шешімін қадаммен шығар.
- Тест болса, дұрыс нұсқаны таңда және қысқаша түсіндір.
- OCR екі нұсқа берсе, екеуін салыстырып, ең ықтимал дұрыс мәтінді құрастыр.
- Егер мәтін тым бұзылған болса, барынша ықтимал мағынасын қалпына келтіріп жауап бер, бірақ сенімсіз бөлігін белгіле.
- Жауапта OCR техникалық атауларын ("OCR нұсқа 1") қайталама.

OCR-дан алынған мәтін:
---
$text
---

$langInstruction

Қайтару форматы қатаң JSON болсын. Markdown қоршауын қолданба.
JSON құрылымы:
{
  "cleanedText": "Суреттегі қалпына келтірілген, оқуға түсінікті мәтін",
  "answer": "Оқушыға арналған нақты жауап, түсіндірме немесе шешім. Markdown қолдануға болады."
}
''';
  }

  ScanAnalysis _parseScanAnalysis(String responseText, String fallbackText) {
    try {
      final jsonText = _extractJsonObject(responseText);
      final data = jsonDecode(jsonText) as Map<String, dynamic>;
      final cleanedText = (data['cleanedText'] as String?)?.trim() ?? '';
      final answer = (data['answer'] as String?)?.trim() ?? '';

      return ScanAnalysis(
        cleanedText: cleanedText.isNotEmpty ? cleanedText : fallbackText.trim(),
        explanation: answer.isNotEmpty ? answer : responseText.trim(),
      );
    } catch (_) {
      return ScanAnalysis(
        cleanedText: fallbackText.trim(),
        explanation: responseText.trim(),
      );
    }
  }

  String _extractJsonObject(String text) {
    final trimmed = text.trim();
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      return trimmed;
    }

    final start = trimmed.indexOf('{');
    final end = trimmed.lastIndexOf('}');
    if (start >= 0 && end > start) {
      return trimmed.substring(start, end + 1);
    }

    throw const FormatException('JSON object not found');
  }

  String _resolveLanguage(
    String language,
    String primaryText, [
    String? secondaryText,
  ]) {
    if (language != 'auto') return language;

    final combinedText = '$primaryText ${secondaryText ?? ''}';
    if (_hasKazakhCyrillic(combinedText)) return 'kazakh';
    if (_hasRussianCyrillic(combinedText)) return 'russian';
    return 'kazakh';
  }

  String _languageInstruction(String language) {
    if (language == 'russian') {
      return '''
Отвечай строго на русском языке кириллицей.
Не используй латинскую транслитерацию для русских или казахских слов.
Если вопрос задан на казахском, можно кратко сохранить казахские термины кириллицей.
''';
    }

    if (language == 'english') {
      return 'Answer in English.';
    }

    return '''
Жауапты міндетті түрде қазақ тілінде, кирилл әліпбиімен жаз.
Латынша транслитерация қолданба: "kazaksha", "tusindirme", "zhauap" сияқты жазба.
Қазақ әріптерін дұрыс қолдан: ә, ғ, қ, ң, ө, ұ, ү, һ, і.
''';
  }

  bool _hasKazakhCyrillic(String text) {
    return RegExp(r'[ӘәҒғҚқҢңӨөҰұҮүҺһІі]').hasMatch(text);
  }

  bool _hasRussianCyrillic(String text) {
    return RegExp(r'[А-Яа-яЁё]').hasMatch(text);
  }

  Future<String> _callAI(String prompt) async {
    if (!isConfigured) {
      throw Exception(AppConstants.aiNotConfigured);
    }

    final response = await http.post(
      Uri.parse(AppConstants.aiBackendUrl),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'prompt': prompt,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['text'] as String;
    } else {
      throw Exception('AI қатесі: ${response.statusCode}. Қайтадан көріңіз.');
    }
  }
}
