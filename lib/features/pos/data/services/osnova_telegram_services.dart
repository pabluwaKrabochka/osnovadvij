import 'dart:convert';
import 'dart:io';
import '../../../../core/utils/money_formatter.dart';
import '../../presentation/widgets/cash_operations_z_report.dart';

class OsnovaTelegramService {
  OsnovaTelegramService._();
  static final OsnovaTelegramService instance = OsnovaTelegramService._();

  String botToken = '';
  String chatId = '';
  String ownerChatId = '';
  int? defaultTopicId;

  Future<void> Function(String token, String chatId)? onConfigSaved;

  bool get isConfigured =>
      botToken.trim().isNotEmpty && chatId.trim().isNotEmpty;

  bool get isOwnerConfigured =>
      botToken.trim().isNotEmpty && ownerChatId.trim().isNotEmpty;

  void configure({
    required String token,
    required String targetChatId,
    String? targetOwnerChatId,
    int? topicId,
    bool updateTopic = false,
    bool persist = true,
  }) {
    botToken = token.trim();
    chatId = targetChatId.trim();
    if (targetOwnerChatId != null) {
      ownerChatId = targetOwnerChatId.trim();
    }
    if (updateTopic) {
      defaultTopicId = (topicId != null && topicId > 1) ? topicId : null;
    }
    if (persist) {
      onConfigSaved?.call(botToken, chatId);
    }
  }

  /// Розбирає посилання вигляду https://t.me/c/2145678901/42/105 або https://t.me/c/2145678901/105
  static ({String? chatId, int? topicId}) parseTelegramLink(String raw) {
    final trimmed = raw.trim();
    final match = RegExp(
      r't\.me/c/(\d+)(?:/(\d+))?(?:/(\d+))?',
      caseSensitive: false,
    ).firstMatch(trimmed);

    if (match == null) {
      return (chatId: null, topicId: null);
    }

    final internalChatDigits = match.group(1);
    final secondNum = match.group(2);
    final thirdNum = match.group(3);

    final parsedChatId =
        internalChatDigits != null ? '-100$internalChatDigits' : null;
    final parsedTopicId =
        (secondNum != null && thirdNum != null) ? int.tryParse(secondNum) : null;

    return (
      chatId: parsedChatId,
      topicId:
          (parsedTopicId != null && parsedTopicId > 1) ? parsedTopicId : null,
    );
  }

  String _escapeHtml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
  }

  /// Визначає особистий числовий Chat ID власника (@Dominusssss) з приватних повідомлень боту
  Future<({bool ok, String? ownerId, String? username, String? error})>
      detectOwnerChatIdFromUpdates(
    String rawToken, {
    String preferredUsername = 'Dominusssss',
  }) async {
    final token = rawToken.trim();
    if (token.isEmpty || !token.contains(':')) {
      return (
        ok: false,
        ownerId: null,
        username: null,
        error: 'Спочатку вставте валідний API Token з @BotFather',
      );
    }

    final client = HttpClient();
    try {
      final uri = Uri.parse('https://api.telegram.org/bot$token/getUpdates');
      final request = await client.getUrl(uri);
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      final decoded = jsonDecode(body) as Map<String, dynamic>;

      if (decoded['ok'] != true) {
        return (
          ok: false,
          ownerId: null,
          username: null,
          error: (decoded['description'] as String?) ?? 'Помилка Telegram API',
        );
      }

      final results = (decoded['result'] as List<dynamic>? ?? []);
      String? fallbackPrivateId;
      String? fallbackUsername;

      for (final item in results.reversed) {
        final map = item as Map<String, dynamic>;
        final msg =
            (map['message'] ?? map['edited_message']) as Map<String, dynamic>?;
        final chat = msg?['chat'] as Map<String, dynamic>?;
        if (chat != null && chat['type'] == 'private' && chat['id'] != null) {
          final idStr = chat['id'].toString();
          final uname = chat['username'] as String?;
          if (uname != null &&
              uname.toLowerCase() == preferredUsername.toLowerCase()) {
            return (
              ok: true,
              ownerId: idStr,
              username: '@$uname',
              error: null,
            );
          }
          fallbackPrivateId ??= idStr;
          fallbackUsername ??= uname != null
              ? '@$uname'
              : (chat['first_name'] as String? ?? 'Особистий чат');
        }
      }

      if (fallbackPrivateId != null) {
        return (
          ok: true,
          ownerId: fallbackPrivateId,
          username: fallbackUsername,
          error: null,
        );
      }

      return (
        ok: false,
        ownerId: null,
        username: null,
        error:
            'Напишіть боту /start в особисті повідомлення з акаунту @$preferredUsername і натисніть ще раз.',
      );
    } catch (e) {
      return (
        ok: false,
        ownerId: null,
        username: null,
        error: 'Помилка мережі: $e',
      );
    } finally {
      client.close();
    }
  }

  /// Автоматично визначає Chat ID групи та ID гілки (топіку)
  Future<
      ({
        bool ok,
        String? chatId,
        String? chatTitle,
        int? topicId,
        String? topicName,
        String? error,
      })> detectChatIdFromUpdates(String rawToken) async {
    final token = rawToken.trim();
    if (token.isEmpty || !token.contains(':')) {
      return (
        ok: false,
        chatId: null,
        chatTitle: null,
        topicId: null,
        topicName: null,
        error:
            'Невірний формат токена. Потрібен API Token з @BotFather (вигляду 123456:ABC...)',
      );
    }

    final client = HttpClient();
    try {
      final uri = Uri.parse('https://api.telegram.org/bot$token/getUpdates');
      final request = await client.getUrl(uri);
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      final decoded = jsonDecode(body) as Map<String, dynamic>;

      if (decoded['ok'] != true) {
        return (
          ok: false,
          chatId: null,
          chatTitle: null,
          topicId: null,
          topicName: null,
          error: (decoded['description'] as String?) ?? 'Помилка Telegram API',
        );
      }

      final results = (decoded['result'] as List<dynamic>? ?? []);
      for (final item in results.reversed) {
        final map = item as Map<String, dynamic>;
        final msg = (map['message'] ??
            map['edited_message'] ??
            map['my_chat_member'] ??
            map['channel_post']) as Map<String, dynamic>?;
        final chat = msg?['chat'] as Map<String, dynamic>?;
        final type = chat?['type'] as String?;
        if (chat != null && chat['id'] != null && type != 'private') {
          final idStr = chat['id'].toString();
          final title = (chat['title'] as String?) ??
              (chat['username'] != null ? '@${chat['username']}' : 'Група');

          final rawThread = msg?['message_thread_id'];
          final parsedThread = rawThread is int
              ? rawThread
              : int.tryParse(rawThread?.toString() ?? '');
          final topicId =
              (parsedThread != null && parsedThread > 1) ? parsedThread : null;

          final replyTo = msg?['reply_to_message'] as Map<String, dynamic>?;
          final topicCreated =
              replyTo?['forum_topic_created'] as Map<String, dynamic>?;
          final topicName = topicCreated?['name'] as String?;

          return (
            ok: true,
            chatId: idStr,
            chatTitle: title,
            topicId: topicId,
            topicName: topicName,
            error: null,
          );
        }
      }

      return (
        ok: false,
        chatId: null,
        chatTitle: null,
        topicId: null,
        topicName: null,
        error:
            'Групових повідомлень не знайдено. Вимкніть Group Privacy у @BotFather, напишіть у групу /start@ваш_бот і натисніть ще раз.',
      );
    } catch (e) {
      return (
        ok: false,
        chatId: null,
        chatTitle: null,
        topicId: null,
        topicName: null,
        error: 'Помилка мережі: $e',
      );
    } finally {
      client.close();
    }
  }

  Future<bool> sendMessage(
    String htmlText, {
    int? topicId,
    String? overrideChatId,
  }) async {
    final targetChat = (overrideChatId ?? chatId).trim();
    if (botToken.trim().isEmpty || targetChat.isEmpty) return false;

    final effectiveTopicId =
        overrideChatId != null ? null : (topicId ?? defaultTopicId);
    final client = HttpClient();
    try {
      final uri =
          Uri.parse('https://api.telegram.org/bot$botToken/sendMessage');
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;

      final payload = <String, dynamic>{
        'chat_id': targetChat,
        'text': htmlText,
        'parse_mode': 'HTML',
      };
      if (effectiveTopicId != null && effectiveTopicId > 1) {
        payload['message_thread_id'] = effectiveTopicId;
      }

      request.write(jsonEncode(payload));

      final response = await request.close();
      await response.drain<void>();
      return response.statusCode == 200;
    } catch (_) {
      return false;
    } finally {
      client.close();
    }
  }

  Future<bool> notifyCashOperation({
    required CashOpType type,
    required int amountCents,
    required String reason,
  }) {
    final isIn = type == CashOpType.serviceIn;
    final emoji = isIn ? '🟢' : '🟠';
    final title = isIn ? 'СЛУЖБОВЕ ВНЕСЕННЯ' : 'СЛУЖБОВЕ ВИНЕСЕННЯ';
    final target = ownerChatId.trim().isNotEmpty ? ownerChatId : chatId;

    return sendMessage(
      '$emoji <b>OSNOVA POS • $title</b>\n'
      'Сума: <b>${MoneyFormatter.format(amountCents)}</b>\n'
      'Причина: ${_escapeHtml(reason)}',
      overrideChatId: target,
    );
  }

  Future<bool> notifyZReport(StandardZReportData z) {
    final modeTag = z.isAutoClosed ? '🤖 АВТОМАТИЧНО (23:50)' : '👤 ВРУЧНУ';
    final target = ownerChatId.trim().isNotEmpty ? ownerChatId : chatId;

    return sendMessage(
      '🔒 <b>Z-ЗВІТ №${z.shiftNumber} • OSNOVA</b> ($modeTag)\n'
      '━━━━━━━━━━━━━━━━━━\n'
      '💰 Загальний обіг: <b>${MoneyFormatter.format(z.totalTurnoverCents)}</b> (${z.receiptsCount} чеків)\n'
      '💵 Готівка: <b>${MoneyFormatter.format(z.cashSalesCents)}</b>\n'
      '💳 Термінал / Оплата24: <b>${MoneyFormatter.format(z.cardTerminalSalesCents)}</b>\n'
      '➕ Внесення: ${MoneyFormatter.format(z.serviceInTotalCents)}\n'
      '➖ Винесення: ${MoneyFormatter.format(z.serviceOutTotalCents)}\n'
      '━━━━━━━━━━━━━━━━━━\n'
      '🏦 <b>Залишок готівки в касі: ${MoneyFormatter.format(z.expectedCashInDrawerCents)}</b>',
      overrideChatId: target,
    );
  }

  /// Оперативне оповіщення з каси — надсилається ВИКЛЮЧНО власнику (@Dominusssss) в ЛС
  Future<bool> notifyOwnerAlert(String alertText) {
    if (!isOwnerConfigured) return Future.value(false);

    return sendMessage(
      '🔔 <b>OSNOVA POS • ОПОВІЩЕННЯ З КАСИ</b>\n'
      '${_escapeHtml(alertText)}',
      overrideChatId: ownerChatId,
    );
  }

  String buildEventPlainText({
    required String category,
    required String title,
    required String dateTimeText,
    required String priceText,
    required String description,
    required List<String> taggedUsernames,
  }) {
    final mentions = taggedUsernames
        .map((u) => u.trim())
        .where((u) => u.isNotEmpty)
        .map((u) => u.startsWith('@') ? u : '@$u')
        .toSet()
        .join(' ');

    final displayTitle = title.trim().isEmpty ? 'Назва заходу' : title.trim();
    final buffer = StringBuffer()
      ..writeln('🔥 АНОНС ПОДІЇ В OSNOVA • ${category.toUpperCase()}')
      ..writeln('🎯 $displayTitle')
      ..writeln('');

    if (dateTimeText.trim().isNotEmpty) {
      buffer.writeln('🗓 Коли: ${dateTimeText.trim()}');
    }
    if (priceText.trim().isNotEmpty) {
      buffer.writeln('🎟 Вхід / Умови: ${priceText.trim()}');
    }
    buffer.writeln('📍 Локація: вул. Арсенія Тарковського, 76А');

    if (description.trim().isNotEmpty) {
      buffer
        ..writeln('')
        ..writeln(description.trim());
    }

    if (mentions.isNotEmpty) {
      buffer
        ..writeln('')
        ..writeln('👀 Кличемо в гру: $mentions');
    }

    return buffer.toString().trimRight();
  }

  Future<bool> publishEventAnnouncement({
    required String category,
    required String title,
    required String dateTimeText,
    required String priceText,
    required String description,
    required List<String> taggedUsernames,
    int? topicId,
  }) {
    final mentions = taggedUsernames
        .map((u) => u.trim())
        .where((u) => u.isNotEmpty)
        .map((u) => u.startsWith('@') ? u : '@$u')
        .toSet()
        .join(' ');

    final buffer = StringBuffer()
      ..writeln(
          '🔥 <b>АНОНС ПОДІЇ В OSNOVA • ${_escapeHtml(category.toUpperCase())}</b>')
      ..writeln('🎯 <b>${_escapeHtml(title)}</b>')
      ..writeln('');

    if (dateTimeText.trim().isNotEmpty) {
      buffer.writeln('🗓 <b>Коли:</b> ${_escapeHtml(dateTimeText.trim())}');
    }
    if (priceText.trim().isNotEmpty) {
      buffer.writeln('🎟 <b>Вхід / Умови:</b> ${_escapeHtml(priceText.trim())}');
    }
    buffer.writeln('📍 <b>Локація:</b> вул. Арсенія Тарковського, 76А');

    if (description.trim().isNotEmpty) {
      buffer
        ..writeln('')
        ..writeln(_escapeHtml(description.trim()));
    }

    if (mentions.isNotEmpty) {
      buffer
        ..writeln('')
        ..writeln('👀 <b>Кличемо в гру:</b> $mentions');
    }

    return sendMessage(buffer.toString(), topicId: topicId);
  }
}