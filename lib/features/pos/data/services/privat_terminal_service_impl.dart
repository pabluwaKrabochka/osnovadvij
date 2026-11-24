import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/pos_entities.dart';
import '../../domain/repositories/pos_repositories.dart';

typedef JsonMap = Map<String, dynamic>;

class PrivatTerminalServiceImpl implements PrivatTerminalService {
  static const _keyClid = 'osnova_pb_clid';
  static const _keySecret = 'osnova_pb_secret';
  static const _keyClientToken = 'osnova_pb_client_token';
  static const _keyRetailerId = 'osnova_pb_retailer_id';
  static const _keyCashierPhone = 'osnova_pb_cashier_phone';

  static const _baseUrl = 'https://dio.privatbank.ua/api/nfcpos/integrators';

  @override
  Future<PrivatTerminalSettingsEntity> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return PrivatTerminalSettingsEntity(
      clid: prefs.getString(_keyClid) ?? '',
      secret: prefs.getString(_keySecret) ?? '',
      clientToken: prefs.getString(_keyClientToken) ?? '',
      retailerId: prefs.getString(_keyRetailerId) ?? '',
      cashierPhone: prefs.getString(_keyCashierPhone) ?? '',
    );
  }

  @override
  Future<void> saveSettings(PrivatTerminalSettingsEntity settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyClid, settings.clid.trim());
    await prefs.setString(_keySecret, settings.secret.trim());
    await prefs.setString(_keyClientToken, settings.clientToken.trim());
    await prefs.setString(_keyRetailerId, settings.retailerId.trim());
    await prefs.setString(
      _keyCashierPhone,
      _normalizePhone(settings.cashierPhone),
    );
  }

  String _normalizePhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('0') && digits.length == 10) {
      return '38$digits';
    }
    if (digits.startsWith('80') && digits.length == 11) {
      return '3$digits';
    }
    return digits;
  }

  @override
  Future<PrivatPaymentSession> initiatePayment({
    required int amountKopecks,
    required String purpose,
  }) async {
    final settings = await loadSettings();
    if (!settings.isConfigured) {
      throw Exception(
        'Заповніть ключі API ПриватБанку (clid, secret, client_token та телефон касира)',
      );
    }

    final payload = <String, dynamic>{
      'clid': settings.clid,
      'secret': settings.secret,
      'client_token': settings.clientToken,
      if (settings.retailerId.isNotEmpty) 'retailer_id': settings.retailerId,
      'phone': _normalizePhone(settings.cashierPhone),
      'amount': amountKopecks / 100.0,
      'currency': 'UAH',
      'purpose': purpose,
    };

    final responseMap = await _postJson(
      endpoint: '$_baseUrl/token.php',
      settings: settings,
      body: payload,
    );

    final token = (responseMap['token'] ??
            responseMap['payment_token'] ??
            responseMap['payment_id'] ??
            responseMap['id'])
        ?.toString();

    if (token == null || token.isEmpty) {
      final errMsg = (responseMap['message'] ??
              responseMap['error'] ??
              responseMap['description'] ??
              'ПриватБанк не повернув токен оплати')
          .toString();
      throw Exception(errMsg);
    }

    return PrivatPaymentSession(
      paymentToken: token,
      purpose: purpose,
    );
  }

  @override
  Future<PrivatPaymentPollResult> checkPaymentStatus(
    String paymentToken,
  ) async {
    final settings = await loadSettings();
    if (!settings.isConfigured) {
      return const PrivatPaymentPollResult(
        state: PrivatPaymentState.failed,
        message: 'Відсутні налаштування терміналу ПриватБанку',
      );
    }

    final payload = <String, dynamic>{
      'clid': settings.clid,
      'secret': settings.secret,
      'client_token': settings.clientToken,
      'token': paymentToken,
    };

    final responseMap = await _postJson(
      endpoint: '$_baseUrl/check.php',
      settings: settings,
      body: payload,
    );

    final rawStatus = (responseMap['status'] ??
            responseMap['state'] ??
            responseMap['payment_status'] ??
            'pending')
        .toString()
        .toLowerCase();

    final rrn = (responseMap['rrn'] ??
            responseMap['transaction_id'] ??
            responseMap['auth_code'] ??
            paymentToken)
        .toString();

    final message = (responseMap['message'] ??
            responseMap['error'] ??
            responseMap['description'])
        ?.toString();

    if (rawStatus == 'paid' ||
        rawStatus == 'success' ||
        rawStatus == 'approved' ||
        rawStatus == 'completed' ||
        rawStatus == 'ok') {
      return PrivatPaymentPollResult(
        state: PrivatPaymentState.paid,
        rrn: rrn,
        message: message,
      );
    }

    if (rawStatus == 'cancelled' ||
        rawStatus == 'canceled' ||
        rawStatus == 'expired' ||
        rawStatus == 'timeout') {
      return PrivatPaymentPollResult(
        state: PrivatPaymentState.cancelled,
        message: message ?? 'Оплату скасовано або вичерпано час очікування',
      );
    }

    if (rawStatus == 'failed' ||
        rawStatus == 'declined' ||
        rawStatus == 'rejected' ||
        rawStatus == 'error') {
      return PrivatPaymentPollResult(
        state: PrivatPaymentState.failed,
        message: message ?? 'Банк відхилив транзакцію',
      );
    }

    return PrivatPaymentPollResult(
      state: PrivatPaymentState.pending,
      message: message,
    );
  }

  Future<JsonMap> _postJson({
    required String endpoint,
    required PrivatTerminalSettingsEntity settings,
    required JsonMap body,
  }) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final request = await client.postUrl(Uri.parse(endpoint));
      request.headers.contentType = ContentType.json;
      request.headers.set('Accept', 'application/json');
      request.headers.set('clid', settings.clid);
      request.headers.set('secret', settings.secret);

      request.add(utf8.encode(jsonEncode(body)));
      final response = await request.close().timeout(const Duration(seconds: 10));
      final rawBody = await response.transform(utf8.decoder).join();

      if (rawBody.trim().isEmpty) {
        throw Exception(
          'Порожня відповідь від сервера ПриватБанку (${response.statusCode})',
        );
      }

      final decoded = jsonDecode(rawBody);
      if (decoded is! JsonMap) {
        throw Exception('Некоректний формат відповіді ПриватБанку');
      }

      if (response.statusCode >= 400) {
        final err = (decoded['message'] ??
                decoded['error'] ??
                'Помилка сервера ПриватБанку (${response.statusCode})')
            .toString();
        throw Exception(err);
      }

      return decoded;
    } on SocketException {
      throw Exception('Немає з\'єднання з інтернетом або сервером ПриватБанку');
    } finally {
      client.close();
    }
  }
}