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

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.phone_android_rounded, color: OsnovaTheme.liveGreen),
              SizedBox(width: 10),
              Text('Оплата24 • Термінал ПриватБанку'),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: OsnovaTheme.bgDark.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: OsnovaTheme.liveGreen.withValues(alpha: 0.35),
                      ),
                    ),
                    child: const Text(
                      'Вкажіть параметри інтеграції з кабінету terminal.pb.ua та номер телефону касира, на якому встановлено застосунок «Термінал» ПриватБанку.',
                      style: TextStyle(
                        color: OsnovaTheme.sageMuted,
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Телефон касира (380...)',
                      hintText: '380991234567',
                      prefixIcon: Icon(Icons.phone_rounded),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: clientTokenCtrl,
                    decoration: const InputDecoration(
                      labelText: 'client_token (з кабінету terminal.pb.ua)',
                      prefixIcon: Icon(Icons.vpn_key_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: retailerIdCtrl,
                    decoration: const InputDecoration(
                      labelText: 'retailer_id (ID точки OSNOVA, за наявності)',
                      prefixIcon: Icon(Icons.storefront_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: clidCtrl,
                          decoration: const InputDecoration(
                            labelText: 'clid (Client ID)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: secretCtrl,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'secret (Ключ)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Скасувати'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: OsnovaTheme.gold,
                foregroundColor: OsnovaTheme.bgDark,
              ),
              onPressed: () async {
                final settings = PrivatTerminalSettingsEntity(
                  clid: clidCtrl.text.trim(),
                  secret: secretCtrl.text.trim(),
                  clientToken: clientTokenCtrl.text.trim(),
                  retailerId: retailerIdCtrl.text.trim(),
                  cashierPhone: phoneCtrl.text.trim(),
                );
                await ctrl.savePrivatTerminalSettings(settings);
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
              icon: const Icon(Icons.save_rounded, size: 18),
              label: const Text(
                'Зберегти',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        );
      },
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
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

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
            'Піднесіть картку або смартфон клієнта до телефону касира';
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

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.contactless_rounded, color: OsnovaTheme.liveGreen),
          SizedBox(width: 10),
          Text('Оплата24 • ПриватБанк'),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (context, child) {
                final scale = _isPaid ? 1.05 : 0.94 + 0.1 * _pulseCtrl.value;
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (_errorMessage != null
                              ? Colors.redAccent
                              : OsnovaTheme.liveGreen)
                          .withValues(alpha: 0.15),
                      border: Border.all(
                        color: _errorMessage != null
                            ? Colors.redAccent
                            : OsnovaTheme.liveGreen,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      _isPaid
                          ? Icons.check_circle_rounded
                          : _errorMessage != null
                              ? Icons.error_outline_rounded
                              : Icons.phone_android_rounded,
                      size: 38,
                      color: _errorMessage != null
                          ? Colors.redAccent
                          : OsnovaTheme.liveGreen,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              amountText,
              style: const TextStyle(
                color: OsnovaTheme.goldBright,
                fontSize: 30,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (phone.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Телефон касира: +$phone',
                style: const TextStyle(
                  color: OsnovaTheme.sageMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
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
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              if (_isInitializing || !_isPaid)
                const LinearProgressIndicator(
                  color: OsnovaTheme.liveGreen,
                  backgroundColor: OsnovaTheme.bgDark,
                ),
            ],
          ],
        ),
      ),
      actions: [
        if (!_isPaid)
          TextButton(
            onPressed: () {
              _pollTimer?.cancel();
              Navigator.of(context).pop(null);
            },
            child: const Text('Скасувати'),
          ),
        if (_errorMessage != null)
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: OsnovaTheme.gold,
              foregroundColor: OsnovaTheme.bgDark,
            ),
            onPressed: _startPaymentFlow,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text(
              'Повторити запит',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
      ],
    );
  }
}