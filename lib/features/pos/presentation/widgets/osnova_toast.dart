import 'package:flutter/material.dart';
import 'package:osnova_pos/core/theme/osnova_theme.dart';

enum OsnovaToastType { success, warning, error }

class OsnovaToast {
  static OverlayEntry? _currentEntry;

  static void success(BuildContext context, String message, {String? subtitle}) {
    _show(
      context,
      message: message,
      subtitle: subtitle,
      type: OsnovaToastType.success,
    );
  }

  static void warning(BuildContext context, String message, {String? subtitle}) {
    _show(
      context,
      message: message,
      subtitle: subtitle,
      type: OsnovaToastType.warning,
    );
  }

  static void error(BuildContext context, String message, {String? subtitle}) {
    _show(
      context,
      message: message,
      subtitle: subtitle,
      type: OsnovaToastType.error,
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    String? subtitle,
    required OsnovaToastType type,
    Duration duration = const Duration(milliseconds: 2800),
  }) {
    _currentEntry?.remove();
    _currentEntry = null;

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _OsnovaToastWidget(
        message: message,
        subtitle: subtitle,
        type: type,
        duration: duration,
        onDismissed: () {
          if (_currentEntry == entry) {
            _currentEntry = null;
          }
          entry.remove();
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }
}

class _OsnovaToastWidget extends StatefulWidget {
  final String message;
  final String? subtitle;
  final OsnovaToastType type;
  final Duration duration;
  final VoidCallback onDismissed;

  const _OsnovaToastWidget({
    required this.message,
    this.subtitle,
    required this.type,
    required this.duration,
    required this.onDismissed,
  });

  @override
  State<_OsnovaToastWidget> createState() => _OsnovaToastWidgetState();
}

class _OsnovaToastWidgetState extends State<_OsnovaToastWidget>
    with TickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final AnimationController _timerCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _scaleAnim;

  bool _isClosing = false;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
      reverseDuration: const Duration(milliseconds: 260),
    );

    _timerCtrl = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _fadeAnim = CurvedAnimation(
      parent: _entryCtrl,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.45),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    _scaleAnim = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: Curves.easeOutCubic,
      ),
    );

    _entryCtrl.forward();
    _timerCtrl.forward().whenComplete(_dismiss);
  }

  Future<void> _dismiss() async {
    if (_isClosing || !mounted) return;
    _isClosing = true;
    await _entryCtrl.reverse();
    if (mounted) widget.onDismissed();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _timerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color borderColor;
    final Color accentColor;
    final List<Color> bgColors;
    final IconData iconData;

    switch (widget.type) {
      case OsnovaToastType.success:
        borderColor = OsnovaTheme.gold.withValues(alpha: 0.75);
        accentColor = OsnovaTheme.liveGreen;
        bgColors = const [Color(0xFF16382B), Color(0xFF0E231B)];
        iconData = Icons.check_circle_rounded;
        break;
      case OsnovaToastType.warning:
        borderColor = OsnovaTheme.goldBright.withValues(alpha: 0.8);
        accentColor = OsnovaTheme.goldBright;
        bgColors = const [Color(0xFF1F3B2E), Color(0xFF11241C)];
        iconData = Icons.info_outline_rounded;
        break;
      case OsnovaToastType.error:
        borderColor = Colors.redAccent.withValues(alpha: 0.75);
        accentColor = Colors.redAccent;
        bgColors = const [Color(0xFF38181C), Color(0xFF210E11)];
        iconData = Icons.error_outline_rounded;
        break;
    }

    return Positioned(
      left: 22,
      bottom: 22,
      child: SafeArea(
        child: Material(
          color: Colors.transparent,
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: GestureDetector(
                  onTap: _dismiss,
                  onVerticalDragEnd: (_) => _dismiss(),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 430, minWidth: 280),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: bgColors,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor, width: 1.4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.48),
                          blurRadius: 22,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.14),
                          blurRadius: 14,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: accentColor.withValues(alpha: 0.16),
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                  child: Icon(iconData, color: accentColor, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        widget.message,
                                        style: const TextStyle(
                                          color: OsnovaTheme.creamText,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          height: 1.25,
                                        ),
                                      ),
                                      if (widget.subtitle != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          widget.subtitle!,
                                          style: const TextStyle(
                                            color: OsnovaTheme.sageMuted,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AnimatedBuilder(
                            animation: _timerCtrl,
                            builder: (context, _) {
                              return Align(
                                alignment: Alignment.centerLeft,
                                child: FractionallySizedBox(
                                  widthFactor: 1.0 - _timerCtrl.value,
                                  child: Container(
                                    height: 2.5,
                                    color: accentColor.withValues(alpha: 0.75),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}