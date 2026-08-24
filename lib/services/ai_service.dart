import 'package:dio/dio.dart';

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
    if (settings.effectiveAiApiKey.isEmpty) {
      throw StateError(
        'Add an AI API key in Settings to use the assistant online.',
      );
    }

    final online = await _network.isOnline;
    if (!online) {
      throw StateError(
        'No internet connection. Connect to Wi‑Fi or mobile data to use the AI Bible Assistant.',
      );
    }

    final payloadMessages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
    ];
    if (contextVerse != null) {
      payloadMessages.add({
        'role': 'system',
        'content':
            'Selected passage context: ${contextVerse.reference}\n"${contextVerse.verse.content}"',
      });
    }
    if (extraInstruction != null) {
      payloadMessages.add({'role': 'system', 'content': extraInstruction});
    }
    payloadMessages.addAll(messages);

    final dio = Dio(
      BaseOptions(
        baseUrl: settings.aiBaseUrl.replaceAll(RegExp(r'/$'), ''),
        headers: {
          'Authorization': 'Bearer ${settings.effectiveAiApiKey}',
          'Content-Type': 'application/json',
        },
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 90),
      ),
    );

    const maxAttempts = 3;
    DioException? lastError;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final response = await dio.post<Map<String, dynamic>>(
          '/chat/completions',
          data: {
            'model': settings.aiModel,
            'messages': payloadMessages,
            'temperature': 0.4,
            'max_tokens': 900,
          },
        );
        final choices = response.data?['choices'] as List<dynamic>?;
        final content = choices?.firstOrNull?['message']?['content'] as String?;
        if (content == null || content.trim().isEmpty) {
          throw StateError('The AI returned an empty response.');
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
          final wait = _retryDelay(e, attempt);
          await Future<void>.delayed(wait);
          continue;
        }
        throw StateError(_describeDioError(e));
      }
    }

    throw StateError(_describeDioError(lastError!));
  }

  Duration _retryDelay(DioException e, int attempt) {
    final header = e.response?.headers.value('retry-after');
    if (header != null) {
      final seconds = int.tryParse(header);
      if (seconds != null && seconds > 0) {
        return Duration(seconds: seconds.clamp(1, 30));
      }
    }
    // 2s, 4s, 8s
    return Duration(seconds: 1 << attempt);
  }

  String _describeDioError(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return 'Could not reach the AI service. Check your internet connection and try again.';
    }

    final status = e.response?.statusCode;
    final apiMessage = _extractApiMessage(e.response?.data);

    switch (status) {
      case 401:
        return 'AI authentication failed (401). Your API key may be invalid or revoked. '
            'Create a new key in OpenAI and update Settings.';
      case 403:
        return 'AI access denied (403). Check that your API key is allowed to use this model.';
      case 404:
        return 'AI endpoint or model not found (404). Check the base URL and model name in Settings.';
      case 429:
        if (apiMessage != null &&
            (apiMessage.toLowerCase().contains('quota') ||
                apiMessage.toLowerCase().contains('billing') ||
                apiMessage.toLowerCase().contains('insufficient'))) {
          return 'AI quota exceeded (429). Your OpenAI account needs billing credit '
              'or a higher usage limit. Add payment at platform.openai.com, wait a minute, then try again.\n\n'
              '$apiMessage';
        }
        return 'AI rate limit reached (429). Too many requests right now. '
            'Wait a few seconds and tap Retry.'
            '${apiMessage != null ? '\n\n$apiMessage' : ''}';
      case 500:
      case 502:
      case 503:
        return 'The AI service is temporarily unavailable ($status). Try again shortly.';
      default:
        return 'AI request failed${status != null ? ' ($status)' : ''}.'
            '${apiMessage != null ? '\n$apiMessage' : ' Check your API key, model, and endpoint in Settings.'}';
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
