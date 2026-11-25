import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/osnova_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../domain/entities/pos_entities.dart';
import '../../domain/repositories/pos_repositories.dart';
import '../controllers/pos_controller.dart';
import 'osnova_toast.dart';

class Oplata24Dialogs {
  static InputDecoration _fieldDecoration({
    required String label,
    String? hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: OsnovaTheme.sageMuted, fontSize: 12.5),
      hintStyle: TextStyle(
        color: OsnovaTheme.sageMuted.withValues(alpha: 0.55),
        fontSize: 12.5,
      ),
      prefixIcon: Icon(icon, size: 18, color: OsnovaTheme.liveGreen),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFF0A1914),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(
          color: OsnovaTheme.liveGreen.withValues(alpha: 0.32),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(
          color: OsnovaTheme.liveGreen.withValues(alpha: 0.32),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: OsnovaTheme.goldBright, width: 1.5),
      ),
    );
  }

  static Future<void> showSettingsDialog(
    BuildContext context,
    PosController ctrl,
  ) async {
    final current = await ctrl.loadPrivatTerminalSettings();
    if (!context.mounted) return;

    final phoneCtrl = TextEditingController(text: current.cashierPhone);
    final clientTokenCtrl = TextEditingController(text: current.clientToken);
    final retailerIdCtrl = TextEditingController(text: current.retailerId);
    final clidCtrl = TextEditingController(text: current.clid);
    final secretCtrl = TextEditingController(text: current.secret);
    bool obscureSecret = true;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return Dialog(
            backgroundColor: OsnovaTheme.surfaceCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: BorderSide(
                color: OsnovaTheme.liveGreen.withValues(alpha: 0.55),
                width: 1.3,
              ),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 530),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Шапка інтеграції ПриватБанку
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  OsnovaTheme.liveGreen,
                                  Color(0xFF1F9D55),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: const Icon(
                              Icons.contactless_rounded,
                              color: OsnovaTheme.bgDark,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ОПЛАТА24 • ПРИВАТБАНК',
                                  style: TextStyle(
                                    color: OsnovaTheme.liveGreen,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16.5,
                                    letterSpacing: 0.9,
                                  ),
                                ),
                                Text(
                                  'Прийом безконтактних платежів через смартфон касира',
                                  style: TextStyle(
                                    color: OsnovaTheme.sageMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            icon: const Icon(
                              Icons.close_rounded,
                              color: OsnovaTheme.sageMuted,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF143126), Color(0xFF0A1914)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: OsnovaTheme.liveGreen.withValues(alpha: 0.35),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: OsnovaTheme.liveGreen,
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Вкажіть ключі з кабінету terminal.pb.ua та номер телефону касира, на якому запущено застосунок «Термінал» ПриватБанку.',
                                style: TextStyle(
                                  color: OsnovaTheme.creamText,
                                  fontSize: 12,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      TextField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(
                          color: OsnovaTheme.creamText,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: _fieldDecoration(
                          label: 'Телефон касира (380...)',
                          hint: '380991234567',
                          icon: Icons.phone_android_rounded,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: clientTokenCtrl,
                        style: const TextStyle(
                          color: OsnovaTheme.creamText,
                          fontSize: 13,
                        ),
                        decoration: _fieldDecoration(
                          label: 'client_token (з кабінету terminal.pb.ua)',
                          icon: Icons.vpn_key_outlined,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: retailerIdCtrl,
                        style: const TextStyle(
                          color: OsnovaTheme.creamText,
                          fontSize: 13,
                        ),
                        decoration: _fieldDecoration(
                          label: 'retailer_id (ID точки OSNOVA, за наявності)',
                          icon: Icons.storefront_outlined,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: clidCtrl,
                              style: const TextStyle(
                                color: OsnovaTheme.creamText,
                                fontSize: 13,
                              ),
                              decoration: _fieldDecoration(
                                label: 'clid (Client ID)',
                                icon: Icons.badge_outlined,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: secretCtrl,
                              obscureText: obscureSecret,
                              style: const TextStyle(
                                color: OsnovaTheme.creamText,
                                fontSize: 13,
                              ),
                              decoration: _fieldDecoration(
                                label: 'secret (Ключ)',
                                icon: Icons.lock_outline_rounded,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    obscureSecret
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    size: 18,
                                    color: OsnovaTheme.sageMuted,
                                  ),
                                  onPressed: () => setDialogState(
                                    () => obscureSecret = !obscureSecret,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text(
                              'Скасувати',
                              style: TextStyle(color: OsnovaTheme.sageMuted),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            decoration: BoxDecoration(
                              gradient: OsnovaTheme.goldGradient,
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(13),
                                onTap: () async {
                                  final settings = PrivatTerminalSettingsEntity(
                                    clid: clidCtrl.text.trim(),
                                    secret: secretCtrl.text.trim(),
                                    clientToken: clientTokenCtrl.text.trim(),
                                    retailerId: retailerIdCtrl.text.trim(),
                                    cashierPhone: phoneCtrl.text.trim(),
                                  );
                                  await ctrl
                                      .savePrivatTerminalSettings(settings);
                                  if (ctx.mounted) {
                                    Navigator.of(ctx).pop();
                                    OsnovaToast.success(
                                      context,
                                      'Параметри Оплата24 збережено',
                                      subtitle: settings.isConfigured
                                          ? 'Касир: +${settings.cashierPhone}'
                                          : 'Заповніть усі обов\'язкові ключі для запуску',
                                    );
                                  }
                                },
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 13,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.save_rounded,
                                        size: 19,
                                        color: OsnovaTheme.bgDark,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Зберегти ключі',
                                        style: TextStyle(
                                          color: OsnovaTheme.bgDark,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 13.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static Future<CheckoutResult?> showPaymentWaitingDialog(
    BuildContext context,
    PosController ctrl,
  ) {
    return showDialog<CheckoutResult?>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _Oplata24WaitingDialog(controller: ctrl),
    );
  }
}

class _Oplata24WaitingDialog extends StatefulWidget {
  final PosController controller;

  const _Oplata24WaitingDialog({required this.controller});

  @override
  State<_Oplata24WaitingDialog> createState() => _Oplata24WaitingDialogState();
}

class _Oplata24WaitingDialogState extends State<_Oplata24WaitingDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  Timer? _pollTimer;

  bool _isInitializing = true;
  bool _isPollingRequestInFlight = false;
  bool _isPaid = false;
  String? _errorMessage;
  String? _paymentToken;
  String _statusSubtitle = 'Надсилаємо суму на телефон у «Термінал»...';

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _startPaymentFlow();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _startPaymentFlow() async {
    _pollTimer?.cancel();
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
      _isPaid = false;
      _statusSubtitle = 'Надсилаємо суму на телефон у «Термінал»...';
    });

    try {
      final session = await widget.controller.startOplata24Session();
      if (!mounted) return;

      setState(() {
        _isInitializing = false;
        _paymentToken = session.paymentToken;
        _statusSubtitle =
            'Піднесіть картку або смартфон гостя до телефону касира';
      });

      _pollTimer = Timer.periodic(
        const Duration(seconds: 2),
        (_) => _checkStatus(),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _checkStatus() async {
    if (_paymentToken == null ||
        _isPollingRequestInFlight ||
        _isPaid ||
        !mounted) {
      return;
    }

    _isPollingRequestInFlight = true;
    try {
      final res =
          await widget.controller.checkOplata24Session(_paymentToken!);
      if (!mounted) return;

      if (res.state == PrivatPaymentState.paid) {
        _pollTimer?.cancel();
        HapticFeedback.heavyImpact();
        setState(() {
          _isPaid = true;
          _statusSubtitle = 'Оплату підтверджено! Формуємо чек...';
        });

        final checkoutResult = await widget.controller.checkout(
          externalTransactionId: res.rrn,
        );
        if (mounted) {
          Navigator.of(context).pop(checkoutResult);
        }
      } else if (res.state == PrivatPaymentState.failed ||
          res.state == PrivatPaymentState.cancelled) {
        _pollTimer?.cancel();
        setState(() {
          _errorMessage = res.message ?? 'Оплату не завершено';
        });
      }
    } catch (_) {
    } finally {
      _isPollingRequestInFlight = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final amountText = MoneyFormatter.format(widget.controller.cartTotal);
    final phone = widget.controller.cashierPhone ?? '';
    final statusColor =
        _errorMessage != null ? Colors.redAccent : OsnovaTheme.liveGreen;

    return Dialog(
      backgroundColor: OsnovaTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: statusColor.withValues(alpha: 0.6),
          width: 1.4,
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Верхній бейдж терміналу
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.contactless_rounded,
                          size: 15,
                          color: statusColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'ОПЛАТА24 • NFC ТЕРМІНАЛ',
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_isPaid)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        _pollTimer?.cancel();
                        Navigator.of(context).pop(null);
                      },
                      icon: const Icon(
                        Icons.close_rounded,
                        color: OsnovaTheme.sageMuted,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 18),

              // Анімований NFC-радар із хвилями
              SizedBox(
                width: 118,
                height: 118,
                child: AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (context, _) {
                    final wave = _pulseCtrl.value;
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        if (!_isPaid && _errorMessage == null)
                          Container(
                            width: 76 + 40 * wave,
                            height: 76 + 40 * wave,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: statusColor.withValues(
                                  alpha: (1.0 - wave) * 0.55,
                                ),
                                width: 2,
                              ),
                            ),
                          ),
                        Container(
                          width: 82,
                          height: 82,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                statusColor.withValues(alpha: 0.25),
                                const Color(0xFF0A1914),
                              ],
                            ),
                            border: Border.all(color: statusColor, width: 2.2),
                            boxShadow: [
                              BoxShadow(
                                color: statusColor.withValues(alpha: 0.3),
                                blurRadius: 18,
                              ),
                            ],
                          ),
                          child: Icon(
                            _isPaid
                                ? Icons.check_circle_rounded
                                : _errorMessage != null
                                    ? Icons.error_outline_rounded
                                    : Icons.contactless_rounded,
                            size: 40,
                            color: statusColor,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Картка суми до оплати
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF143126), Color(0xFF0A1914)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: OsnovaTheme.gold.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'СУМА ДО СПЛАТИ',
                      style: TextStyle(
                        color: OsnovaTheme.sageMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      amountText,
                      style: const TextStyle(
                        color: OsnovaTheme.goldBright,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (phone.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Термінал касира: +$phone',
                        style: const TextStyle(
                          color: OsnovaTheme.sageMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: OsnovaTheme.creamText,
                      fontSize: 13,
                    ),
                  ),
                )
              else ...[
                Text(
                  _statusSubtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: OsnovaTheme.creamText,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                if (_isInitializing || !_isPaid)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: const LinearProgressIndicator(
                      minHeight: 5,
                      color: OsnovaTheme.liveGreen,
                      backgroundColor: Color(0xFF0A1914),
                    ),
                  ),
              ],

              const SizedBox(height: 18),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!_isPaid)
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: OsnovaTheme.sageMuted,
                        side: BorderSide(
                          color: OsnovaTheme.gold.withValues(alpha: 0.3),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        _pollTimer?.cancel();
                        Navigator.of(context).pop(null);
                      },
                      child: const Text('Скасувати оплату'),
                    ),
                  if (_errorMessage != null) ...[
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: OsnovaTheme.gold,
                        foregroundColor: OsnovaTheme.bgDark,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _startPaymentFlow,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text(
                        'Повторити запит',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}