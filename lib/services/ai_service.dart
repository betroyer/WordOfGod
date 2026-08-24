import 'package:dio/dio.dart';

import '../core/constants/app_constants.dart';
import '../data/repositories/bible_repository.dart';
import 'network_service.dart';
import 'settings_service.dart';

class AiService {
  AiService({NetworkService? network})
      : _network = network ?? NetworkService();

  final NetworkService _network;

  static const systemPrompt = '''
You are FaithPath's Bible study assistant. Stay focused on Scripture study.
Do not present interpretation as unquestionable fact.
When explaining a passage, use these labeled sections:
1. Scripture — what the passage directly says
2. Context — historical or literary information
3. Interpretation — a possible interpretation
4. Note — different Christian traditions may interpret some passages differently
Encourage the reader to verify important claims against Scripture and reliable study resources.
Be respectful, clear, and pastoral. Quote the provided KJV text when it is given.
''';

  Future<String> complete({
    required AppSettings settings,
    required List<Map<String, String>> messages,
    VerseRef? contextVerse,
    String? extraInstruction,
  }) async {
    if (!settings.aiEnabled) {
      throw StateError('AI is disabled in Settings.');
    }

    final apiKey = _sanitizeApiKey(settings.effectiveAiApiKey);
    if (apiKey.isEmpty) {
      throw StateError(
        'Add your Groq API key in Settings (console.groq.com/keys). It usually starts with gsk_.',
      );
    }

    final online = await _network.isOnline;
    if (!online) {
      throw StateError(
        'No internet connection. Connect to Wi‑Fi or mobile data to use the AI Bible Assistant.',
      );
    }

    final baseUrl = _sanitizeBaseUrl(settings.aiBaseUrl);
    var model = settings.aiModel.trim();
    if (model.isEmpty || _isRetiredGroqModel(model)) {
      model = AppConstants.aiModel;
    }

    // Groq is happier with a single system message.
    final systemParts = <String>[systemPrompt];
    if (contextVerse != null) {
      systemParts.add(
        'Selected passage context: ${contextVerse.reference}\n"${contextVerse.verse.content}"',
      );
    }
    if (extraInstruction != null && extraInstruction.trim().isNotEmpty) {
      systemParts.add(extraInstruction.trim());
    }

    final payloadMessages = <Map<String, String>>[
      {'role': 'system', 'content': systemParts.join('\n\n')},
      ...messages,
    ];

    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 90),
        validateStatus: (code) => code != null && code < 500,
      ),
    );

    const maxAttempts = 3;
    DioException? lastError;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final response = await dio.post<Map<String, dynamic>>(
          '/chat/completions',
          data: {
            'model': model,
            'messages': payloadMessages,
            'temperature': 0.4,
            'max_tokens': 900,
          },
        );

        final status = response.statusCode ?? 0;
        if (status == 401 || status == 403 || status == 404 || status == 400 || status == 429) {
          throw DioException(
            requestOptions: response.requestOptions,
            response: response,
            type: DioExceptionType.badResponse,
          );
        }

        final choices = response.data?['choices'] as List<dynamic>?;
        final content = choices?.firstOrNull?['message']?['content'] as String?;
        if (content == null || content.trim().isEmpty) {
          final apiMessage = _extractApiMessage(response.data);
          throw StateError(
            apiMessage ??
                'The AI returned an empty response. Try another Groq model in Settings.',
          );
        }
        return content.trim();
      } on DioException catch (e) {
        lastError = e;
        final status = e.response?.statusCode;
        final shouldRetry = status == 429 ||
            status == 503 ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout;

        if (shouldRetry && attempt < maxAttempts) {
          await Future<void>.delayed(_retryDelay(e, attempt));
          continue;
        }
        throw StateError(_describeDioError(e, model: model, baseUrl: baseUrl));
      }
    }

    throw StateError(
      _describeDioError(lastError!, model: model, baseUrl: baseUrl),
    );
  }

  String _sanitizeApiKey(String raw) {
    var key = raw.trim();
    if (key.toLowerCase().startsWith('bearer ')) {
      key = key.substring(7).trim();
    }
    if ((key.startsWith('"') && key.endsWith('"')) ||
        (key.startsWith("'") && key.endsWith("'"))) {
      key = key.substring(1, key.length - 1).trim();
    }
    return key;
  }

  String _sanitizeBaseUrl(String raw) {
    var url = raw.trim();
    if (url.isEmpty) return AppConstants.aiBaseUrl;
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    // Users sometimes paste the full chat path.
    const suffixes = ['/chat/completions', '/completions'];
    for (final suffix in suffixes) {
      if (url.endsWith(suffix)) {
        url = url.substring(0, url.length - suffix.length);
      }
    }
    if (!url.contains('://')) {
      url = 'https://$url';
    }
    return url;
  }

  bool _isRetiredGroqModel(String model) {
    const retired = {
      'llama-3.1-8b-instant',
      'llama3-8b-8192',
      'llama3-70b-8192',
      'mixtral-8x7b-32768',
      'gemma-7b-it',
      'gemma2-9b-it',
    };
    return retired.contains(model.trim());
  }

  Duration _retryDelay(DioException e, int attempt) {
    final header = e.response?.headers.value('retry-after');
    if (header != null) {
      final seconds = int.tryParse(header);
      if (seconds != null && seconds > 0) {
        return Duration(seconds: seconds.clamp(1, 30));
      }
    }
    return Duration(seconds: 1 << attempt);
  }

  String _describeDioError(
    DioException e, {
    required String model,
    required String baseUrl,
  }) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return 'Could not reach Groq. Check your internet connection and try again.';
    }

    final status = e.response?.statusCode;
    final apiMessage = _extractApiMessage(e.response?.data);

    switch (status) {
      case 401:
        return 'Groq authentication failed (401). Paste a valid Groq key from '
            'console.groq.com/keys (usually starts with gsk_).'
            '${apiMessage != null ? '\n\n$apiMessage' : ''}';
      case 403:
        return 'Groq access denied (403). Your key may not be allowed for this model.'
            '${apiMessage != null ? '\n\n$apiMessage' : ''}';
      case 404:
        return 'Groq endpoint or model not found (404).\n'
            'URL: $baseUrl\nModel: $model\n'
            'Tap “Use Groq defaults” in Settings, or pick a current model.'
            '${apiMessage != null ? '\n\n$apiMessage' : ''}';
      case 400:
        return 'Groq rejected the request (400). The model "$model" may be retired '
            'or invalid. Tap “Use Groq defaults” in Settings.'
            '${apiMessage != null ? '\n\n$apiMessage' : ''}';
      case 429:
        return 'Groq rate limit reached (429). Wait a few seconds and tap Retry.'
            '${apiMessage != null ? '\n\n$apiMessage' : ''}';
      case 500:
      case 502:
      case 503:
        return 'Groq is temporarily unavailable ($status). Try again shortly.';
      default:
        return 'AI request failed${status != null ? ' ($status)' : ''}.'
            '${apiMessage != null ? '\n$apiMessage' : ' Check Groq API key, URL, and model in Settings.'}';
    }
  }

  String? _extractApiMessage(dynamic data) {
    if (data is Map) {
      final error = data['error'];
      if (error is Map && error['message'] is String) {
        return (error['message'] as String).trim();
      }
      if (data['message'] is String) {
        return (data['message'] as String).trim();
      }
    }
    if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }
    return null;
  }
}

class AiPrompts {
  static const explain = 'Explain this verse.';
  static const simple = 'Explain this verse in simple language.';
  static const context = 'Give the historical and literary context.';
  static const questions = 'Generate Bible study questions for this passage.';
  static const apply = 'How can I apply this practically?';
  static const reflect = 'Help me reflect on this passage through questions.';
  static const chapter = 'Explain this entire chapter.';
  static const compare = 'What other Bible passages should I compare with this?';
}
