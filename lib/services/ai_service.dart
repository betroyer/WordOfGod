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

    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/chat/completions',
        data: {
          'model': settings.aiModel,
          'messages': payloadMessages,
          'temperature': 0.4,
        },
      );
      final choices = response.data?['choices'] as List<dynamic>?;
      final content = choices?.firstOrNull?['message']?['content'] as String?;
      if (content == null || content.trim().isEmpty) {
        throw StateError('The AI returned an empty response.');
      }
      return content.trim();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        throw StateError(
          'Could not reach the AI service. Check your internet connection and try again.',
        );
      }
      final status = e.response?.statusCode;
      throw StateError(
        'AI request failed${status != null ? ' ($status)' : ''}. Check your API key and endpoint.',
      );
    }
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
