import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import '../../../../core/theme/osnova_theme.dart';

class YoutubeChannelPage extends StatefulWidget {
  final String channelUrl;

   YoutubeChannelPage({
    super.key,
    this.channelUrl = 'https://www.youtube.com/@OSNOVA76.3',
  });

  @override
  State<YoutubeChannelPage> createState() => _YoutubeChannelPageState();
}

class _YoutubeChannelPageState extends State<YoutubeChannelPage> {
  late final WebViewController _webController;
  double _loadingProgress = 0.0;
  bool _isInitialLoading = true;
  bool _canGoBack = false;
  bool _canGoForward = false;
  bool _isTheaterMode = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(OsnovaTheme.bgDark)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (!mounted) return;
            setState(() {
              _loadingProgress = progress / 100.0;
              if (progress >= 80) {
                _isInitialLoading = false;
              }
            });
          },
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() => _loadingProgress = 0.08);
          },
          onPageFinished: (_) async {
            await _updateNavigationState();
            if (!mounted) return;
            setState(() {
              _loadingProgress = 1.0;
              _isInitialLoading = false;
            });
          },
          onNavigationRequest: (request) {
            final url = request.url;
            // Не даємо Android викидати користувача у зовнішній додаток YouTube
            if (!url.startsWith('http://') && !url.startsWith('https://')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.channelUrl));

    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(false);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    _webController = controller;
  }

  Future<void> _updateNavigationState() async {
    final back = await _webController.canGoBack();
    final forward = await _webController.canGoForward();
    if (!mounted) return;
    setState(() {
      _canGoBack = back;
      _canGoForward = forward;
    });
  }

  void _toggleTheaterMode() {
    HapticFeedback.selectionClick();
    setState(() => _isTheaterMode = !_isTheaterMode);
    if (_isTheaterMode) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_isTheaterMode) {
          _toggleTheaterMode();
          return;
        }
        if (await _webController.canGoBack()) {
          await _webController.goBack();
          await _updateNavigationState();
        } else if (context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: OsnovaTheme.bgDark,
        appBar: _isTheaterMode
            ? null
            : AppBar(
                backgroundColor: OsnovaTheme.bgDark,
                automaticallyImplyLeading: false,
                titleSpacing: 12,
                title: Row(
                  children: [
                    // Кнопка повернення до каси (поточний чек зберігається)
                    FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        backgroundColor: OsnovaTheme.surfaceElevated,
                        foregroundColor: OsnovaTheme.creamText,
                        padding:  EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      icon:  Icon(
                        Icons.point_of_sale_rounded,
                        size: 18,
                        color: OsnovaTheme.gold,
                      ),
                      label:  Text(
                        'До каси',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                     SizedBox(width: 14),

                    // Фірмовий бейдж каналу OSNOVA YouTube
                    Container(
                      padding:  EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: OsnovaTheme.gold.withValues(alpha: 0.45),
                        ),
                      ),
                      child:  Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.play_circle_fill_rounded,
                            color: Color(0xFFFF0033),
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'OSNOVA76.3',
                            style: TextStyle(
                              color: OsnovaTheme.creamText,
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  // Навігація вбудованого браузера
                  _BrowserNavButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    tooltip: 'Назад по сторінці',
                    enabled: _canGoBack,
                    onTap: () async {
                      await _webController.goBack();
                      await _updateNavigationState();
                    },
                  ),
                   SizedBox(width: 6),
                  _BrowserNavButton(
                    icon: Icons.arrow_forward_ios_rounded,
                    tooltip: 'Вперед',
                    enabled: _canGoForward,
                    onTap: () async {
                      await _webController.goForward();
                      await _updateNavigationState();
                    },
                  ),
                   SizedBox(width: 6),
                  _BrowserNavButton(
                    icon: Icons.home_rounded,
                    tooltip: 'На головну каналу @OSNOVA76.3',
                    enabled: true,
                    onTap: () => _webController.loadRequest(Uri.parse(widget.channelUrl)),
                  ),
                   SizedBox(width: 6),
                  _BrowserNavButton(
                    icon: Icons.refresh_rounded,
                    tooltip: 'Оновити сторінку',
                    enabled: true,
                    onTap: () => _webController.reload(),
                  ),
                   SizedBox(width: 10),

                  // Режим "Кінозал" для перегляду відео на весь екран
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: OsnovaTheme.goldBright,
                      side: BorderSide(color: OsnovaTheme.gold.withValues(alpha: 0.6)),
                      padding:  EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    onPressed: _toggleTheaterMode,
                    icon:  Icon(Icons.fullscreen_rounded, size: 20),
                    label:  Text(
                      'Кінозал',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                   SizedBox(width: 12),
                ],
                bottom: PreferredSize(
                  preferredSize:  Size.fromHeight(3),
                  child: _loadingProgress < 1.0
                      ? LinearProgressIndicator(
                          value: _loadingProgress,
                          minHeight: 3,
                          backgroundColor: OsnovaTheme.surfaceCard,
                          valueColor:  AlwaysStoppedAnimation<Color>(
                            OsnovaTheme.goldBright,
                          ),
                        )
                      : Container(
                          height: 1,
                          color: OsnovaTheme.gold.withValues(alpha: 0.22),
                        ),
                ),
              ),
        body: Stack(
          children: [
            WebViewWidget(controller: _webController),

            // Плавна брендова заставка, поки підвантажується плеєр
            if (_isInitialLoading)
              Container(
                color: OsnovaTheme.bgDark,
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding:  EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: OsnovaTheme.surfaceCard,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: OsnovaTheme.gold.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: OsnovaTheme.gold.withValues(alpha: 0.18),
                            blurRadius: 24,
                          ),
                        ],
                      ),
                      child:  Icon(
                        Icons.play_arrow_rounded,
                        color: Color(0xFFFF0033),
                        size: 42,
                      ),
                    ),
                     SizedBox(height: 16),
                     Text(
                      'Завантаження каналу OSNOVA...',
                      style: TextStyle(
                        color: OsnovaTheme.goldBright,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                     SizedBox(height: 6),
                     Text(
                      'youtube.com/@OSNOVA76.3',
                      style: TextStyle(
                        color: OsnovaTheme.sageMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

            // Плаваюча кнопка виходу з повноекранного режиму "Кінозал"
            if (_isTheaterMode)
              Positioned(
                top: 14,
                right: 16,
                child: SafeArea(
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: _toggleTheaterMode,
                      child: Container(
                        padding:  EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: OsnovaTheme.gold.withValues(alpha: 0.6),
                          ),
                        ),
                        child:  Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.fullscreen_exit_rounded,
                              color: OsnovaTheme.goldBright,
                              size: 20,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Вийти з кінозалу',
                              style: TextStyle(
                                color: OsnovaTheme.creamText,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BrowserNavButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onTap;

   _BrowserNavButton({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: OsnovaTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: enabled ? onTap : null,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: enabled
                    ? OsnovaTheme.gold.withValues(alpha: 0.35)
                    : OsnovaTheme.sageMuted.withValues(alpha: 0.12),
              ),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 17,
              color: enabled
                  ? OsnovaTheme.creamText
                  : OsnovaTheme.sageMuted.withValues(alpha: 0.35),
            ),
          ),
        ),
      ),
    );
  }
}