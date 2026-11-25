import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/osnova_theme.dart';

class PinLockDialog extends StatefulWidget {
  final String requiredPin;

  const PinLockDialog({
    super.key,
    this.requiredPin = '9375',
  });

  static Future<bool> show(
    BuildContext context, {
    String requiredPin = '9375',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.82),
      builder: (_) => PinLockDialog(requiredPin: requiredPin),
    );
    return result ?? false;
  }

  @override
  State<PinLockDialog> createState() => _PinLockDialogState();
}

class _PinLockDialogState extends State<PinLockDialog>
    with TickerProviderStateMixin {
  final FocusNode _focusNode = FocusNode();
  late final AnimationController _shakeCtrl;
  late final AnimationController _pulseCtrl;

  String _enteredPin = '';
  String? _keyboardActiveKey;
  Timer? _keyHighlightTimer;
  bool _isError = false;
  bool _isSuccess = false;

  static const Map<String, String> _subLabels = {
    '1': '• • •',
    '2': 'А Б В Г',
    '3': 'Д Е Є Ж',
    '4': 'З И І Ї',
    '5': 'Й К Л М',
    '6': 'Н О П Р',
    '7': 'С Т У Ф',
    '8': 'Х Ц Ч Ш',
    '9': 'Щ Ь Ю Я',
    '0': 'OSNOVA',
  };

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _keyHighlightTimer?.cancel();
    _focusNode.dispose();
    _shakeCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _flashKeyboardKey(String key) {
    _keyHighlightTimer?.cancel();
    setState(() => _keyboardActiveKey = key);
    _keyHighlightTimer = Timer(const Duration(milliseconds: 140), () {
      if (mounted) setState(() => _keyboardActiveKey = null);
    });
  }

  Future<void> _onDigitPressed(String digit, {bool fromKeyboard = false}) async {
    if (_isSuccess || _enteredPin.length >= 4) return;

    if (fromKeyboard) _flashKeyboardKey(digit);
    HapticFeedback.selectionClick();

    setState(() {
      _isError = false;
      _enteredPin += digit;
    });

    if (_enteredPin.length == 4) {
      if (_enteredPin == widget.requiredPin) {
        HapticFeedback.mediumImpact();
        setState(() => _isSuccess = true);
        await Future.delayed(const Duration(milliseconds: 280));
        if (mounted) Navigator.of(context).pop(true);
      } else {
        HapticFeedback.heavyImpact();
        setState(() => _isError = true);
        _shakeCtrl.forward(from: 0);
        await Future.delayed(const Duration(milliseconds: 480));
        if (mounted) {
          setState(() {
            _enteredPin = '';
            _isError = false;
          });
        }
      }
    }
  }

  void _onBackspace({bool fromKeyboard = false}) {
    if (_enteredPin.isEmpty || _isSuccess) return;
    if (fromKeyboard) _flashKeyboardKey('BACK');
    HapticFeedback.selectionClick();
    setState(() {
      _isError = false;
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
    });
  }

  void _onClear() {
    if (_enteredPin.isEmpty || _isSuccess) return;
    HapticFeedback.selectionClick();
    setState(() {
      _isError = false;
      _enteredPin = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _isError
        ? Colors.redAccent
        : _isSuccess
            ? OsnovaTheme.liveGreen
            : OsnovaTheme.goldBright;

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is! KeyDownEvent) return;
        final label = event.logicalKey.keyLabel;
        if (label.length == 1 && '0123456789'.contains(label)) {
          _onDigitPressed(label, fromKeyboard: true);
        } else if (event.logicalKey == LogicalKeyboardKey.backspace) {
          _onBackspace(fromKeyboard: true);
        } else if (event.logicalKey == LogicalKeyboardKey.escape) {
          Navigator.of(context).pop(false);
        }
      },
      child: AnimatedBuilder(
        animation: _shakeCtrl,
        builder: (context, child) {
          final offset = math.sin(_shakeCtrl.value * math.pi * 4) *
              12 *
              (1 - _shakeCtrl.value);
          return Transform.translate(
            offset: Offset(offset, 0),
            child: child,
          );
        },
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: 376,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF132C23),
                  Color(0xFF0B1C16),
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: statusColor.withValues(alpha: 0.65),
                width: 1.6,
              ),
              boxShadow: [
                BoxShadow(
                  color: statusColor.withValues(alpha: 0.18),
                  blurRadius: 32,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.65),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26.5),
              child: CustomPaint(
                painter: _VaultCornerPainter(color: statusColor),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Верхній рядок: статусний бейдж + кнопка закриття
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF081410),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: OsnovaTheme.gold.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            statusColor.withValues(alpha: 0.8),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'OSNOVA • ACCESS',
                                  style: TextStyle(
                                    color: OsnovaTheme.sageMuted,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: Icon(
                              Icons.close_rounded,
                              color: OsnovaTheme.sageMuted,
                              size: 20,
                            ),
                            onPressed: () => Navigator.of(context).pop(false),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // Емблема замка з пульсуючим ореолом
                      AnimatedBuilder(
                        animation: _pulseCtrl,
                        builder: (context, _) {
                          final glow = 0.14 + 0.12 * _pulseCtrl.value;
                          return Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  statusColor.withValues(alpha: glow + 0.12),
                                  const Color(0xFF081410),
                                ],
                              ),
                              border: Border.all(
                                color: statusColor.withValues(alpha: 0.7),
                                width: 1.6,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: statusColor.withValues(alpha: glow),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              transitionBuilder: (child, anim) =>
                                  ScaleTransition(scale: anim, child: child),
                              child: Icon(
                                _isSuccess
                                    ? Icons.lock_open_rounded
                                    : _isError
                                        ? Icons.gpp_bad_rounded
                                        : Icons.lock_rounded,
                                key: ValueKey('$_isSuccess-$_isError'),
                                color: statusColor,
                                size: 28,
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 12),

                      Text(
                        'ВХІД ДО КАСИ OSNOVA',
                        style: TextStyle(
                          color: OsnovaTheme.creamText,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: Text(
                          _isSuccess
                              ? 'Доступ дозволено • Відкриваємо зміну...'
                              : _isError
                                  ? 'Невірний PIN-код. Спробуйте ще раз'
                                  : 'Введіть 4-значний код працівника',
                          key: ValueKey('sub-$_isSuccess-$_isError'),
                          style: TextStyle(
                            color: _isError
                                ? Colors.redAccent
                                : _isSuccess
                                    ? OsnovaTheme.liveGreen
                                    : OsnovaTheme.sageMuted,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Капсула з 4 індивідуальними слотами PIN-коду
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF07130F),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.32),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.45),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(4, (index) {
                            final filled = index < _enteredPin.length;
                            final isCurrent = index == _enteredPin.length &&
                                !_isError &&
                                !_isSuccess;

                            final slotGradient = !filled
                                ? const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF0B1A15),
                                      Color(0xFF0B1A15),
                                    ],
                                  )
                                : _isError
                                    ? LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Colors.redAccent
                                              .withValues(alpha: 0.25),
                                          const Color(0xFF1E0D0D),
                                        ],
                                      )
                                    : _isSuccess
                                        ? LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              OsnovaTheme.liveGreen
                                                  .withValues(alpha: 0.25),
                                              const Color(0xFF0D2418),
                                            ],
                                          )
                                        : const LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Color(0xFF1A3C2F),
                                              Color(0xFF0E231B),
                                            ],
                                          );

                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeOutCubic,
                              width: 52,
                              height: 54,
                              decoration: BoxDecoration(
                                gradient: slotGradient,
                                borderRadius: BorderRadius.circular(13),
                                border: Border.all(
                                  color: filled
                                      ? statusColor
                                      : isCurrent
                                          ? OsnovaTheme.gold
                                              .withValues(alpha: 0.6)
                                          : OsnovaTheme.gold
                                              .withValues(alpha: 0.16),
                                  width: filled || isCurrent ? 1.5 : 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: filled
                                        ? statusColor.withValues(alpha: 0.28)
                                        : Colors.transparent,
                                    blurRadius: filled ? 10 : 0,
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: AnimatedScale(
                                scale: filled ? 1.0 : 0.65,
                                duration: const Duration(milliseconds: 160),
                                curve: Curves.easeOutBack,
                                child: filled
                                    ? Container(
                                        width: 15,
                                        height: 15,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: (!_isError && !_isSuccess)
                                              ? OsnovaTheme.goldGradient
                                              : null,
                                          color: _isError
                                              ? Colors.redAccent
                                              : _isSuccess
                                                  ? OsnovaTheme.liveGreen
                                                  : null,
                                          boxShadow: [
                                            BoxShadow(
                                              color: statusColor.withValues(
                                                alpha: 0.75,
                                              ),
                                              blurRadius: 8,
                                            ),
                                          ],
                                        ),
                                      )
                                    : Container(
                                        width: 10,
                                        height: 2.5,
                                        decoration: BoxDecoration(
                                          color: isCurrent
                                              ? OsnovaTheme.goldBright
                                                  .withValues(alpha: 0.7)
                                              : OsnovaTheme.sageMuted
                                                  .withValues(alpha: 0.25),
                                          borderRadius:
                                              BorderRadius.circular(2),
                                        ),
                                      ),
                              ),
                            );
                          }),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Тактильна цифрова клавіатура
                      _buildKeypadRow(['1', '2', '3']),
                      const SizedBox(height: 10),
                      _buildKeypadRow(['4', '5', '6']),
                      const SizedBox(height: 10),
                      _buildKeypadRow(['7', '8', '9']),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _VaultKeypadButton(
                              label: 'C',
                              subLabel: 'СКИД',
                              isAction: true,
                              isDangerAction: true,
                              onTap: _onClear,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _VaultKeypadButton(
                              label: '0',
                              subLabel: _subLabels['0'],
                              forcePressed: _keyboardActiveKey == '0',
                              onTap: () => _onDigitPressed('0'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _VaultKeypadButton(
                              icon: Icons.backspace_outlined,
                              subLabel: 'СТЕРТИ',
                              isAction: true,
                              forcePressed: _keyboardActiveKey == 'BACK',
                              onTap: _onBackspace,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypadRow(List<String> digits) {
    return Row(
      children: [
        for (int i = 0; i < digits.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: _VaultKeypadButton(
              label: digits[i],
              subLabel: _subLabels[digits[i]],
              forcePressed: _keyboardActiveKey == digits[i],
              onTap: () => _onDigitPressed(digits[i]),
            ),
          ),
        ],
      ],
    );
  }
}

class _VaultKeypadButton extends StatefulWidget {
  final String? label;
  final String? subLabel;
  final IconData? icon;
  final bool isAction;
  final bool isDangerAction;
  final bool forcePressed;
  final VoidCallback onTap;

  const _VaultKeypadButton({
    this.label,
    this.subLabel,
    this.icon,
    this.isAction = false,
    this.isDangerAction = false,
    this.forcePressed = false,
    required this.onTap,
  });

  @override
  State<_VaultKeypadButton> createState() => _VaultKeypadButtonState();
}

class _VaultKeypadButtonState extends State<_VaultKeypadButton> {
  bool _isPressed = false;

  bool get _active => _isPressed || widget.forcePressed;

  @override
  Widget build(BuildContext context) {
    final activeBorder = widget.isDangerAction
        ? Colors.redAccent.withValues(alpha: 0.7)
        : OsnovaTheme.goldBright;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _active ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOutCubic,
          height: 60,
          decoration: BoxDecoration(
            gradient: _active
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: widget.isDangerAction
                        ? [
                            Colors.redAccent.withValues(alpha: 0.25),
                            const Color(0xFF1C0E0E),
                          ]
                        : [
                            const Color(0xFF1F4738),
                            const Color(0xFF122B21),
                          ],
                  )
                : LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: widget.isAction
                        ? [
                            const Color(0xFF0D1F18),
                            const Color(0xFF081410),
                          ]
                        : [
                            const Color(0xFF163529),
                            const Color(0xFF0E231B),
                          ],
                  ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _active
                  ? activeBorder
                  : OsnovaTheme.gold.withValues(
                      alpha: widget.isAction ? 0.18 : 0.34,
                    ),
              width: _active ? 1.5 : 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: _active
                    ? activeBorder.withValues(alpha: 0.25)
                    : Colors.black.withValues(alpha: 0.35),
                blurRadius: _active ? 12 : 6,
                offset: _active ? Offset.zero : const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null)
                Icon(
                  widget.icon,
                  color: _active
                      ? OsnovaTheme.goldBright
                      : OsnovaTheme.creamText.withValues(alpha: 0.85),
                  size: 22,
                )
              else
                Text(
                  widget.label ?? '',
                  style: TextStyle(
                    height: 1.05,
                    color: _active
                        ? (widget.isDangerAction
                            ? Colors.redAccent
                            : OsnovaTheme.goldBright)
                        : widget.isDangerAction
                            ? Colors.redAccent.withValues(alpha: 0.85)
                            : OsnovaTheme.creamText,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              if (widget.subLabel != null) ...[
                const SizedBox(height: 2),
                Text(
                  widget.subLabel!,
                  style: TextStyle(
                    color: _active
                        ? OsnovaTheme.goldBright.withValues(alpha: 0.85)
                        : OsnovaTheme.sageMuted.withValues(alpha: 0.65),
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _VaultCornerPainter extends CustomPainter {
  final Color color;

  const _VaultCornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    const m = 10.0;
    const len = 16.0;

    // Верхній лівий кут
    canvas.drawPath(
      Path()
        ..moveTo(m, m + len)
        ..lineTo(m, m)
        ..lineTo(m + len, m),
      paint,
    );
    // Верхній правий кут
    canvas.drawPath(
      Path()
        ..moveTo(size.width - m - len, m)
        ..lineTo(size.width - m, m)
        ..lineTo(size.width - m, m + len),
      paint,
    );
    // Нижній лівий кут
    canvas.drawPath(
      Path()
        ..moveTo(m, size.height - m - len)
        ..lineTo(m, size.height - m)
        ..lineTo(m + len, size.height - m),
      paint,
    );
    // Нижній правий кут
    canvas.drawPath(
      Path()
        ..moveTo(size.width - m - len, size.height - m)
        ..lineTo(size.width - m, size.height - m)
        ..lineTo(size.width - m, size.height - m - len),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _VaultCornerPainter oldDelegate) =>
      oldDelegate.color != color;
}