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

  static Future<bool> show(BuildContext context, {String requiredPin = '9375'}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.78),
      builder: (_) => PinLockDialog(requiredPin: requiredPin),
    );
    return result ?? false;
  }

  @override
  State<PinLockDialog> createState() => _PinLockDialogState();
}

class _PinLockDialogState extends State<PinLockDialog>
    with SingleTickerProviderStateMixin {
  final FocusNode _focusNode = FocusNode();
  late final AnimationController _shakeCtrl;

  String _enteredPin = '';
  bool _isError = false;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  Future<void> _onDigitPressed(String digit) async {
    if (_isSuccess || _enteredPin.length >= 4) return;

    HapticFeedback.selectionClick();
    setState(() {
      _isError = false;
      _enteredPin += digit;
    });

    if (_enteredPin.length == 4) {
      if (_enteredPin == widget.requiredPin) {
        HapticFeedback.lightImpact();
        setState(() => _isSuccess = true);
        await Future.delayed(const Duration(milliseconds: 220));
        if (mounted) Navigator.of(context).pop(true);
      } else {
        HapticFeedback.heavyImpact();
        setState(() => _isError = true);
        _shakeCtrl.forward(from: 0);
        await Future.delayed(const Duration(milliseconds: 450));
        if (mounted) {
          setState(() {
            _enteredPin = '';
            _isError = false;
          });
        }
      }
    }
  }

  void _onBackspace() {
    if (_enteredPin.isEmpty || _isSuccess) return;
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
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is! KeyDownEvent) return;
        final label = event.logicalKey.keyLabel;
        if (label.length == 1 && '0123456789'.contains(label)) {
          _onDigitPressed(label);
        } else if (event.logicalKey == LogicalKeyboardKey.backspace) {
          _onBackspace();
        } else if (event.logicalKey == LogicalKeyboardKey.escape) {
          Navigator.of(context).pop(false);
        }
      },
      child: AnimatedBuilder(
        animation: _shakeCtrl,
        builder: (context, child) {
          final offset = math.sin(_shakeCtrl.value * math.pi * 4) * 12 * (1 - _shakeCtrl.value);
          return Transform.translate(
            offset: Offset(offset, 0),
            child: child,
          );
        },
        child: Dialog(
          backgroundColor: OsnovaTheme.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: _isError
                  ? Colors.redAccent
                  : _isSuccess
                      ? OsnovaTheme.liveGreen
                      : OsnovaTheme.gold.withValues(alpha: 0.5),
              width: 1.6,
            ),
          ),
          child: Container(
            width: 340,
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 32),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: OsnovaTheme.gold.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isSuccess ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                        color: _isSuccess ? OsnovaTheme.liveGreen : OsnovaTheme.goldBright,
                        size: 24,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: OsnovaTheme.sageMuted, size: 20),
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'ВХІД ДО КАСИ OSNOVA',
                  style: TextStyle(
                    color: OsnovaTheme.creamText,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isError ? 'Невірний пароль' : 'Введіть PIN-код працівника',
                  style: TextStyle(
                    color: _isError ? Colors.redAccent : OsnovaTheme.sageMuted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),

                // 4 індикатори введених цифр
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    final filled = index < _enteredPin.length;
                    Color dotColor = OsnovaTheme.gold.withValues(alpha: 0.25);
                    if (_isError) {
                      dotColor = Colors.redAccent;
                    } else if (_isSuccess) {
                      dotColor = OsnovaTheme.liveGreen;
                    } else if (filled) {
                      dotColor = OsnovaTheme.goldBright;
                    }

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      width: filled ? 18 : 15,
                      height: filled ? 18 : 15,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: filled ? dotColor : Colors.transparent,
                        border: Border.all(color: dotColor, width: 2),
                        boxShadow: filled
                            ? [
                                BoxShadow(
                                  color: dotColor.withValues(alpha: 0.45),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),

                // Цифрова клавіатура 1-9, C, 0, Backspace
                _buildKeypadRow(['1', '2', '3']),
                const SizedBox(height: 10),
                _buildKeypadRow(['4', '5', '6']),
                const SizedBox(height: 10),
                _buildKeypadRow(['7', '8', '9']),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _KeypadButton(
                      label: 'C',
                      isAction: true,
                      onTap: _onClear,
                    ),
                    _KeypadButton(
                      label: '0',
                      onTap: () => _onDigitPressed('0'),
                    ),
                    _KeypadButton(
                      icon: Icons.backspace_outlined,
                      isAction: true,
                      onTap: _onBackspace,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypadRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits
          .map(
            (d) => _KeypadButton(
              label: d,
              onTap: () => _onDigitPressed(d),
            ),
          )
          .toList(),
    );
  }
}

class _KeypadButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final bool isAction;
  final VoidCallback onTap;

  const _KeypadButton({
    this.label,
    this.icon,
    this.isAction = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isAction ? OsnovaTheme.bgDark.withValues(alpha: 0.6) : OsnovaTheme.surfaceElevated,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: OsnovaTheme.gold.withValues(alpha: 0.25),
        child: Container(
          width: 76,
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: OsnovaTheme.gold.withValues(alpha: isAction ? 0.15 : 0.3),
            ),
          ),
          alignment: Alignment.center,
          child: icon != null
              ? Icon(icon, color: OsnovaTheme.sageMuted, size: 22)
              : Text(
                  label ?? '',
                  style: TextStyle(
                    color: isAction ? OsnovaTheme.sageMuted : OsnovaTheme.creamText,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}