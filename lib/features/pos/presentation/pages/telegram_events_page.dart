import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:osnova_pos/features/pos/data/services/osnova_telegram_services.dart';
import '../../../../core/theme/osnova_theme.dart';
import '../../data/datasources/pos_local_datasource.dart';
import '../widgets/osnova_toast.dart';

class TelegramEventsPage extends StatefulWidget {
  const TelegramEventsPage({super.key});

  @override
  State<TelegramEventsPage> createState() => _TelegramEventsPageState();
}

class _TelegramEventsPageState extends State<TelegramEventsPage> {
  final _tg = OsnovaTelegramService.instance;
  final _db = PosLocalDataSource.instance;

  final ScrollController _leftScrollCtrl = ScrollController();
  final ScrollController _subsScrollCtrl = ScrollController();

  // Налаштування бота, групи та особистого ID власника (@Dominusssss)
  late final TextEditingController _tokenCtrl;
  late final TextEditingController _ownerChatIdCtrl;
  late final TextEditingController _chatIdCtrl;
  bool _detectingChatId = false;
  bool _detectingOwnerId = false;

  // Динамічні категорії (напрямки) з прив'язкою до гілок (топіків)
  DbRowList _categories = [];
  int? _selectedCategoryId;

  // Поля конструктора анонсу
  final _eventTitleCtrl = TextEditingController();
  final _eventDateCtrl = TextEditingController(text: 'П\'ятниця • 19:00');
  final _eventPriceCtrl = TextEditingController(text: '100 грн');
  final _eventDescCtrl = TextEditingController();
  bool _publishingEvent = false;

  // База людей для тегування
  DbRowList _subscribers = [];
  final Set<int> _selectedSubscriberIds = {};
  final _subNameCtrl = TextEditingController();
  final _subUsernameCtrl = TextEditingController();
  final Set<String> _newSubTags = {};

  // Оперативні сповіщення власнику (@Dominusssss в ЛС)
  final _ownerAlertCtrl = TextEditingController();
  bool _sendingAlert = false;

  static const List<String> _quickAlerts = [
    '🥤 Закінчуються стаканчики (250 / 340 мл), треба підвезти',
    '💧 Закінчується вода Оболонь 0.5 / 2 л',
    '🍵 Закінчується чай TeaHouse / сиропи',
    '💵 Потрібен розмін дрібними купюрами в касу',
  ];

  @override
  void initState() {
    super.initState();
    _tokenCtrl = TextEditingController(text: _tg.botToken);
    _ownerChatIdCtrl = TextEditingController(text: _tg.ownerChatId);
    _chatIdCtrl = TextEditingController(text: _tg.chatId);
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final cats = await _db.getTgEventCategories();
    final subs = await _db.getTgSubscribers();
    if (!mounted) return;
    setState(() {
      _categories = cats;
      _subscribers = subs;
      if (_categories.isNotEmpty) {
        _selectedCategoryId ??= _categories.first['id'] as int;
        if (_newSubTags.isEmpty) {
          _newSubTags.add(_categories.first['name'] as String);
        }
      }
    });
    _selectSubscribersForSelectedCategory(showToast: false);
  }

  @override
  void dispose() {
    _leftScrollCtrl.dispose();
    _subsScrollCtrl.dispose();
    _tokenCtrl.dispose();
    _ownerChatIdCtrl.dispose();
    _chatIdCtrl.dispose();
    _eventTitleCtrl.dispose();
    _eventDateCtrl.dispose();
    _eventPriceCtrl.dispose();
    _eventDescCtrl.dispose();
    _subNameCtrl.dispose();
    _subUsernameCtrl.dispose();
    _ownerAlertCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic>? get _activeCategory {
    if (_categories.isEmpty) return null;
    for (final c in _categories) {
      if (c['id'] == _selectedCategoryId) return c;
    }
    return _categories.first;
  }

  String get _activeCategoryName =>
      (_activeCategory?['name'] as String?) ?? 'Подія OSNOVA';

  int? get _activeCategoryTopicId {
    final raw = _activeCategory?['topic_id'];
    if (raw is int && raw > 1) return raw;
    return null;
  }

  List<String> get _allAvailableTags {
    final set = <String>{};
    for (final c in _categories) {
      final name = (c['name'] as String? ?? '').trim();
      if (name.isNotEmpty) set.add(name);
    }
    for (final s in _subscribers) {
      final raw = (s['tags'] as String? ?? '').split(',');
      for (final t in raw) {
        if (t.trim().isNotEmpty) set.add(t.trim());
      }
    }
    return set.toList();
  }

  static ({String? chatId, int? topicId}) _parseAnyTopicLink(String raw) {
    final trimmed = raw.trim();
    final match = RegExp(
      r't\.me/c/(\d+)(?:/(\d+))?(?:/(\d+))?',
      caseSensitive: false,
    ).firstMatch(trimmed);

    if (match == null) {
      final directNum = int.tryParse(trimmed);
      return (
        chatId: null,
        topicId: (directNum != null && directNum > 1) ? directNum : null,
      );
    }

    final chatDigits = match.group(1);
    final second = int.tryParse(match.group(2) ?? '');
    return (
      chatId: chatDigits != null ? '-100$chatDigits' : null,
      topicId: (second != null && second > 1) ? second : null,
    );
  }

  void _saveBotConfig({bool showToast = true}) {
    _tg.configure(
      token: _tokenCtrl.text,
      targetChatId: _chatIdCtrl.text,
      targetOwnerChatId: _ownerChatIdCtrl.text,
    );
    if (showToast) {
      OsnovaToast.success(
        context,
        'Налаштування Telegram збережено',
        subtitle: 'Ключі групи та особистий ID (@Dominusssss) оновлено',
      );
    }
  }

  void _selectSubscribersForSelectedCategory({bool showToast = true}) {
    final rawCatName = _activeCategoryName.trim();
    final catName = rawCatName.toLowerCase();
    if (catName.isEmpty) return;

    int matchedCount = 0;
    setState(() {
      _selectedSubscriberIds.clear();
      for (final row in _subscribers) {
        final id = row['id'] as int;
        final tags = (row['tags'] as String? ?? '')
            .split(',')
            .map((e) => e.trim().toLowerCase())
            .where((e) => e.isNotEmpty)
            .toList();

        final matched = tags.any(
          (t) =>
              t == catName ||
              t.contains(catName) ||
              catName.contains(t) ||
              (catName.contains('маф') && t.contains('маф')) ||
              (catName.contains('наст') && t.contains('наст')) ||
              (catName.contains('квіз') && t.contains('квіз')) ||
              (catName.contains('кіно') && t.contains('кіно')) ||
              (catName.contains('псих') &&
                  (t.contains('псих') || t.contains('стендюнг'))),
        );

        if (matched) {
          _selectedSubscriberIds.add(id);
          matchedCount++;
        }
      }
    });

    if (!showToast || !mounted) return;
    if (_subscribers.isEmpty) {
      OsnovaToast.warning(
        context,
        'База учасників порожня',
        subtitle: 'Додайте людей праворуч та позначте їхні напрямки',
      );
    } else if (matchedCount == 0) {
      OsnovaToast.warning(
        context,
        'За напрямком «$rawCatName» нікого не знайдено',
        subtitle: 'Призначте цей тег учасникам або додайте нових',
      );
    } else {
      OsnovaToast.success(
        context,
        'Обрано $matchedCount чол. за напрямком «$rawCatName»',
      );
    }
  }

  List<String> get _selectedUsernames {
    return _subscribers
        .where((s) => _selectedSubscriberIds.contains(s['id'] as int))
        .map((s) => s['username'] as String)
        .toList();
  }

  /// Діалог редагування тегів (напрямків) для вже доданого учасника
  Future<void> _openSubscriberTagsDialog(Map<String, dynamic> sub) async {
    final id = sub['id'] as int;
    final subName = sub['name'] as String? ?? '';
    final initialTags = (sub['tags'] as String? ?? '')
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet();
    final editedTags = Set<String>.from(initialTags);
    final allTags = _allAvailableTags;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: OsnovaTheme.surfaceCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color: OsnovaTheme.gold.withValues(alpha: 0.45),
                ),
              ),
              title: Text(
                'НАПРЯМКИ ДЛЯ $subName',
                style: TextStyle(
                  color: OsnovaTheme.goldBright,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Оберіть хоча б один напрямок, за яким тегати учасника:',
                      style: TextStyle(
                        color: OsnovaTheme.sageMuted,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: allTags.map((tag) {
                        final active = editedTags.contains(tag);
                        return FilterChip(
                          label: Text(tag, style: const TextStyle(fontSize: 12)),
                          selected: active,
                          selectedColor: OsnovaTheme.gold,
                          backgroundColor: OsnovaTheme.bgDark,
                          labelStyle: TextStyle(
                            color: active
                                ? OsnovaTheme.bgDark
                                : OsnovaTheme.creamText,
                            fontWeight: FontWeight.w700,
                          ),
                          onSelected: (val) {
                            setDialogState(() {
                              if (val) {
                                editedTags.add(tag);
                              } else {
                                editedTags.remove(tag);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Скасувати'),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: editedTags.isEmpty
                        ? OsnovaTheme.surfaceElevated
                        : OsnovaTheme.gold,
                    foregroundColor: editedTags.isEmpty
                        ? OsnovaTheme.sageMuted
                        : OsnovaTheme.bgDark,
                  ),
                  onPressed: () async {
                    if (editedTags.isEmpty) {
                      OsnovaToast.warning(
                        context,
                        'Оберіть хоча б один напрямок',
                      );
                      return;
                    }
                    await _db.updateTgSubscriberTags(
                      id: id,
                      tags: editedTags.toList(),
                    );
                    final subs = await _db.getTgSubscribers();
                    if (!mounted) return;
                    setState(() => _subscribers = subs);
                    _selectSubscribersForSelectedCategory(showToast: false);
                    if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                    OsnovaToast.success(context, 'Напрямки учасника оновлено');
                  },
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text(
                    'Зберегти',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Діалог створення або редагування категорії (напрямку) та її гілки (топіку)
  Future<void> _openCategoryEditorDialog({Map<String, dynamic>? existing}) async {
    final nameCtrl = TextEditingController(
      text: existing != null ? (existing['name'] as String? ?? '') : '',
    );
    final existingTopic = existing?['topic_id'] as int?;
    final topicCtrl = TextEditingController(
      text: (existingTopic != null && existingTopic > 1)
          ? '$existingTopic'
          : '',
    );
    bool detectingTopic = false;
    String? detectedHint;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: OsnovaTheme.surfaceCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color: OsnovaTheme.gold.withValues(alpha: 0.45),
                ),
              ),
              title: Text(
                existing != null
                    ? 'РЕДАГУВАННЯ НАПРЯМКУ ТА ГІЛКИ'
                    : 'НОВИЙ НАПРЯМОК ПОДІЙ',
                style: TextStyle(
                  color: OsnovaTheme.goldBright,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
              content: SizedBox(
                width: 460,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      style: TextStyle(
                        color: OsnovaTheme.creamText,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Назва напрямку (як на кнопці)',
                        hintText:
                            'Напр. Мафія, Літературний клуб, Speaking club...',
                        filled: true,
                        fillColor: OsnovaTheme.bgDark,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: topicCtrl,
                            onChanged: (val) {
                              final parsed = _parseAnyTopicLink(val);
                              if (parsed.chatId != null &&
                                  _chatIdCtrl.text.trim().isEmpty) {
                                _chatIdCtrl.text = parsed.chatId!;
                              }
                              if (parsed.topicId != null &&
                                  val.contains('t.me/')) {
                                topicCtrl.text = '${parsed.topicId}';
                                topicCtrl.selection = TextSelection.collapsed(
                                  offset: topicCtrl.text.length,
                                );
                                setDialogState(() {
                                  detectedHint =
                                      'Розпізнано ID гілки: #${parsed.topicId}';
                                });
                              }
                            },
                            style: TextStyle(
                              color: OsnovaTheme.creamText,
                              fontSize: 13,
                            ),
                            decoration: InputDecoration(
                              labelText: 'ID гілки або посилання t.me/c/...',
                              hintText: 'Пусто = # General',
                              filled: true,
                              fillColor: OsnovaTheme.bgDark,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: detectingTopic
                              ? null
                              : () async {
                                  setDialogState(() => detectingTopic = true);
                                  final res = await _tg.detectChatIdFromUpdates(
                                    _tokenCtrl.text,
                                  );
                                  if (!ctx.mounted) return;
                                  setDialogState(() {
                                    detectingTopic = false;
                                    if (res.ok) {
                                      if (res.chatId != null &&
                                          _chatIdCtrl.text.trim().isEmpty) {
                                        _chatIdCtrl.text = res.chatId!;
                                      }
                                      if (res.topicId != null) {
                                        topicCtrl.text = '${res.topicId}';
                                        detectedHint =
                                            'Зловлено: ${res.topicName ?? 'Гілка'} (#${res.topicId})';
                                      } else {
                                        topicCtrl.clear();
                                        detectedHint =
                                            'Останнє повідомлення було в # General';
                                      }
                                    } else {
                                      detectedHint = res.error;
                                    }
                                  });
                                },
                          icon: const Icon(Icons.radar_rounded, size: 18),
                          label: Text(detectingTopic ? '...' : 'Зловити з ТГ'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      detectedHint ??
                          'Як прив\'язати гілку: зайдіть у потрібну гілку в «OSNOVA ЧАТ», скопіюйте посилання на гілку/повідомлення і вставте сюди (або напишіть там /start і натисніть «Зловити з ТГ»).',
                      style: TextStyle(
                        color: detectedHint != null
                            ? OsnovaTheme.goldBright
                            : OsnovaTheme.sageMuted,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                if (existing != null)
                  TextButton.icon(
                    onPressed: () async {
                      final id = existing['id'] as int;
                      await _db.deleteTgEventCategory(id);
                      final updated = await _db.getTgEventCategories();
                      if (!mounted) return;
                      setState(() {
                        _categories = updated;
                        if (_selectedCategoryId == id) {
                          _selectedCategoryId = _categories.isNotEmpty
                              ? _categories.first['id'] as int
                              : null;
                        }
                      });
                      if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                      OsnovaToast.success(context, 'Напрямок видалено');
                    },
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                      size: 18,
                    ),
                    label: const Text(
                      'Видалити',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Скасувати'),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: OsnovaTheme.gold,
                    foregroundColor: OsnovaTheme.bgDark,
                  ),
                  onPressed: () async {
                    final newName = nameCtrl.text.trim();
                    if (newName.isEmpty) return;

                    final parsed = _parseAnyTopicLink(topicCtrl.text);
                    final savedId = await _db.saveTgEventCategory(
                      id: existing?['id'] as int?,
                      name: newName,
                      topicId: parsed.topicId,
                    );

                    final updated = await _db.getTgEventCategories();
                    if (!mounted) return;
                    setState(() {
                      _categories = updated;
                      _selectedCategoryId = savedId;
                    });
                    _selectSubscribersForSelectedCategory(showToast: false);

                    if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                    OsnovaToast.success(
                      context,
                      existing != null
                          ? 'Напрямок оновлено'
                          : 'Новий напрямок додано',
                      subtitle: parsed.topicId != null
                          ? '$newName → гілка #${parsed.topicId}'
                          : '$newName → # General',
                    );
                  },
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text(
                    'Зберегти',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _detectOwnerId() async {
    setState(() => _detectingOwnerId = true);
    final res = await _tg.detectOwnerChatIdFromUpdates(
      _tokenCtrl.text,
      preferredUsername: 'Dominusssss',
    );
    if (!mounted) return;
    setState(() => _detectingOwnerId = false);

    if (res.ok && res.ownerId != null) {
      setState(() => _ownerChatIdCtrl.text = res.ownerId!);
      _saveBotConfig(showToast: false);
      OsnovaToast.success(
        context,
        'Особистий ID власника знайдено (${res.username})',
        subtitle: 'ID ${res.ownerId} збережено для оперативних сповіщень',
      );
    } else {
      OsnovaToast.warning(
        context,
        'Особистий чат не знайдено',
        subtitle: res.error,
      );
    }
  }

  Future<void> _detectChatId() async {
    setState(() => _detectingChatId = true);
    final res = await _tg.detectChatIdFromUpdates(_tokenCtrl.text);
    if (!mounted) return;
    setState(() => _detectingChatId = false);

    if (res.ok && res.chatId != null) {
      setState(() => _chatIdCtrl.text = res.chatId!);
      _saveBotConfig(showToast: false);
      OsnovaToast.success(
        context,
        'Групу знайдено: ${res.chatTitle}',
        subtitle: 'Chat ID ${res.chatId} збережено',
      );
    } else {
      OsnovaToast.warning(
        context,
        'Не вдалося визначити Chat ID групи',
        subtitle: res.error,
      );
    }
  }

  Future<void> _addSubscriber() async {
    final name = _subNameCtrl.text.trim();
    final username = _subUsernameCtrl.text.trim();
    if (name.isEmpty || username.isEmpty) {
      OsnovaToast.warning(
        context,
        'Заповніть ім\'я та @username',
        subtitle: 'Наприклад: Ваня та @one1Vanya',
      );
      return;
    }

    if (_newSubTags.isEmpty) {
      OsnovaToast.warning(
        context,
        'Оберіть хоча б один напрямок',
        subtitle: 'Позначте інтереси людини (Мафія, Настільні ігри тощо)',
      );
      return;
    }

    await _db.addTgSubscriber(
      name: name,
      username: username,
      tags: _newSubTags.toList(),
    );
    _subNameCtrl.clear();
    _subUsernameCtrl.clear();
    final subs = await _db.getTgSubscribers();
    if (!mounted) return;
    setState(() => _subscribers = subs);
    _selectSubscribersForSelectedCategory(showToast: false);

    OsnovaToast.success(context, 'Учасника додано в базу тегів');
  }

  Future<void> _publishEvent() async {
    _saveBotConfig(showToast: false);
    if (!_tg.isConfigured) {
      OsnovaToast.warning(
        context,
        'Налаштуйте Telegram-бота та групу',
        subtitle: 'Вкажіть API Token з @BotFather та Chat ID групи',
      );
      return;
    }
    if (_eventTitleCtrl.text.trim().isEmpty) {
      OsnovaToast.warning(
        context,
        'Введіть назву події',
        subtitle: 'Наприклад: Турнір зі Спортивної Мафії',
      );
      return;
    }

    final taggedUsers = _selectedUsernames;
    final topicId = _activeCategoryTopicId;

    setState(() => _publishingEvent = true);
    final ok = await _tg.publishEventAnnouncement(
      category: _activeCategoryName,
      title: _eventTitleCtrl.text.trim(),
      dateTimeText: _eventDateCtrl.text.trim(),
      priceText: _eventPriceCtrl.text.trim(),
      description: _eventDescCtrl.text.trim(),
      taggedUsernames: taggedUsers,
      topicId: topicId,
    );
    if (!mounted) return;
    setState(() => _publishingEvent = false);

    if (ok) {
      final branchText = topicId != null
          ? 'у гілку «$_activeCategoryName» (#$topicId)'
          : 'у # General';
      OsnovaToast.success(
        context,
        'Анонс опубліковано $branchText!',
        subtitle: taggedUsers.isNotEmpty
            ? 'Тегнуто учасників: ${taggedUsers.length}'
            : 'Опубліковано без тегів',
      );
    } else {
      OsnovaToast.error(
        context,
        'Помилка відправки в Telegram',
        subtitle: 'Перевірте Token, Chat ID групи та правильність ID гілки',
      );
    }
  }

  Future<void> _sendOwnerAlert() async {
    _saveBotConfig(showToast: false);
    final text = _ownerAlertCtrl.text.trim();
    if (!_tg.isOwnerConfigured) {
      OsnovaToast.warning(
        context,
        'Не вказано особистий ID власника (@Dominusssss)',
        subtitle:
            'Напишіть боту /start у приватні повідомлення і натисніть «Знайти мій ID»',
      );
      return;
    }
    if (text.isEmpty) {
      OsnovaToast.warning(context, 'Введіть текст оповіщення для власника');
      return;
    }

    setState(() => _sendingAlert = true);
    final ok = await _tg.notifyOwnerAlert(text);
    if (!mounted) return;
    setState(() => _sendingAlert = false);

    if (ok) {
      _ownerAlertCtrl.clear();
      OsnovaToast.success(
        context,
        'Оповіщення надіслано власнику (@Dominusssss) в ЛС',
      );
    } else {
      OsnovaToast.error(
        context,
        'Не вдалося надіслати в ЛС власнику',
        subtitle: 'Перевірте API Token та особистий ID власника',
      );
    }
  }

  Widget _buildLivePostPreview() {
    final topicId = _activeCategoryTopicId;
    final targetBranchLabel = topicId != null
        ? 'Гілка «$_activeCategoryName» (#$topicId)'
        : 'Гілка # General';

    final titleText = _eventTitleCtrl.text.trim();
    final dateText = _eventDateCtrl.text.trim();
    final priceText = _eventPriceCtrl.text.trim();
    final descText = _eventDescCtrl.text.trim();
    final mentions = _selectedUsernames
        .map((u) => u.trim())
        .where((u) => u.isNotEmpty)
        .map((u) => u.startsWith('@') ? u : '@$u')
        .toSet()
        .toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1914),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF2AABEE).withValues(alpha: 0.42),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.visibility_outlined,
                size: 15,
                color: Color(0xFF2AABEE),
              ),
              const SizedBox(width: 6),
              const Text(
                'ПОПЕРЕДНІЙ ПЕРЕГЛЯД ПОСТА',
                style: TextStyle(
                  color: Color(0xFF2AABEE),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.7,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: OsnovaTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: OsnovaTheme.gold.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  targetBranchLabel,
                  style: TextStyle(
                    color: OsnovaTheme.goldBright,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Скопіювати текст поста',
                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                padding: EdgeInsets.zero,
                icon: Icon(
                  Icons.copy_rounded,
                  size: 16,
                  color: OsnovaTheme.goldBright,
                ),
                onPressed: () {
                  final plain = _tg.buildEventPlainText(
                    category: _activeCategoryName,
                    title: titleText,
                    dateTimeText: dateText,
                    priceText: priceText,
                    description: descText,
                    taggedUsernames: mentions,
                  );
                  Clipboard.setData(ClipboardData(text: plain));
                  OsnovaToast.success(context, 'Текст поста скопійовано');
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF11261F),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
                bottomRight: Radius.circular(14),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(
                color: OsnovaTheme.gold.withValues(alpha: 0.2),
              ),
            ),
            child: SelectableText.rich(
              TextSpan(
                style: TextStyle(
                  color: OsnovaTheme.creamText,
                  fontSize: 12.5,
                  height: 1.42,
                ),
                children: [
                  TextSpan(
                    text:
                        '🔥 АНОНС ПОДІЇ В OSNOVA • ${_activeCategoryName.toUpperCase()}\n',
                    style: TextStyle(
                      color: OsnovaTheme.goldBright,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  TextSpan(
                    text:
                        '🎯 ${titleText.isEmpty ? 'Введіть назву заходу...' : titleText}\n\n',
                    style: TextStyle(
                      color: titleText.isEmpty
                          ? OsnovaTheme.sageMuted
                          : OsnovaTheme.creamText,
                      fontWeight: FontWeight.w900,
                      fontSize: 13.5,
                    ),
                  ),
                  if (dateText.isNotEmpty) ...[
                    const TextSpan(
                      text: '🗓 Коли: ',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    TextSpan(text: '$dateText\n'),
                  ],
                  if (priceText.isNotEmpty) ...[
                    const TextSpan(
                      text: '🎟 Вхід / Умови: ',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    TextSpan(text: '$priceText\n'),
                  ],
                  const TextSpan(
                    text: '📍 Локація: ',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const TextSpan(text: 'вул. Арсенія Тарковського, 76А'),
                  if (descText.isNotEmpty) TextSpan(text: '\n\n$descText'),
                  if (mentions.isNotEmpty) ...[
                    const TextSpan(
                      text: '\n\n👀 Кличемо в гру: ',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    TextSpan(
                      text: mentions.join(' '),
                      style: const TextStyle(
                        color: Color(0xFF4FC3F7),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Єдиний стилізований золотий боковий індикатор скролу
  Widget _buildSideScrollbar({
    required ScrollController controller,
    required Widget child,
  }) {
    return RawScrollbar(
      controller: controller,
      thumbVisibility: true,
      trackVisibility: true,
      interactive: true,
      thickness: 6,
      radius: const Radius.circular(8),
      thumbColor: OsnovaTheme.gold.withValues(alpha: 0.72),
      trackColor: const Color(0xFF07130F),
      trackBorderColor: OsnovaTheme.gold.withValues(alpha: 0.22),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableTags = _allAvailableTags;
    final hasNewSubTags = _newSubTags.isNotEmpty;

    return Scaffold(
      backgroundColor: OsnovaTheme.bgDark,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1D15),
        title: Text(
          'TELEGRAM • ПОДІЇ, ГІЛКИ ТА СПОВІЩЕННЯ ВЛАСНИКУ',
          style: TextStyle(
            color: OsnovaTheme.goldBright,
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 0.9,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: OsnovaTheme.gold,
                foregroundColor: OsnovaTheme.bgDark,
              ),
              onPressed: () => _saveBotConfig(),
              icon: const Icon(Icons.save_rounded, size: 18),
              label: const Text(
                'Зберегти ключі',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ЛІВА КОЛОНКА з видимим скролбаром
            Expanded(
              flex: 57,
              child: _buildSideScrollbar(
                controller: _leftScrollCtrl,
                child: SingleChildScrollView(
                  controller: _leftScrollCtrl,
                  padding: const EdgeInsets.only(right: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Картка 1: Підключення бота, власника (@Dominusssss) та групи OSNOVA ЧАТ
                      _sectionCard(
                        title:
                            '1. ПІДКЛЮЧЕННЯ БОТА, ВЛАСНИКА (@Dominusssss) ТА ГРУПИ',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  flex: 6,
                                  child: TextField(
                                    controller: _tokenCtrl,
                                    style: TextStyle(
                                      color: OsnovaTheme.creamText,
                                      fontSize: 13,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'HTTP API Token (@BotFather)',
                                      hintText: '781234:AAH...',
                                      filled: true,
                                      fillColor: OsnovaTheme.bgDark,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 4,
                                  child: TextField(
                                    controller: _ownerChatIdCtrl,
                                    keyboardType: TextInputType.number,
                                    style: TextStyle(
                                      color: OsnovaTheme.creamText,
                                      fontSize: 13,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'Особистий ID (@Dominusssss)',
                                      hintText: 'Цифровий ID для ЛС',
                                      filled: true,
                                      fillColor: OsnovaTheme.bgDark,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  onPressed: _detectingOwnerId
                                      ? null
                                      : _detectOwnerId,
                                  icon: const Icon(
                                    Icons.person_search_rounded,
                                    size: 18,
                                  ),
                                  label: Text(
                                    _detectingOwnerId ? '...' : 'Мій ID',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _chatIdCtrl,
                                    onChanged: (val) {
                                      final parsed = _parseAnyTopicLink(val);
                                      if (parsed.chatId != null) {
                                        _chatIdCtrl.text = parsed.chatId!;
                                        _chatIdCtrl.selection =
                                            TextSelection.collapsed(
                                          offset: _chatIdCtrl.text.length,
                                        );
                                      }
                                      setState(() {});
                                    },
                                    style: TextStyle(
                                      color: OsnovaTheme.creamText,
                                      fontSize: 13,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'Chat ID групи «OSNOVA ЧАТ»',
                                      hintText:
                                          '-100... (або вставте посилання t.me/c/...)',
                                      filled: true,
                                      fillColor: OsnovaTheme.bgDark,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  onPressed:
                                      _detectingChatId ? null : _detectChatId,
                                  icon: const Icon(
                                    Icons.search_rounded,
                                    size: 18,
                                  ),
                                  label: Text(
                                    _detectingChatId ? '...' : 'ID групи',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Картка 2: Напрямок (редаговані кнопки + прив'язка гілок) та анонс
                      _sectionCard(
                        title: '2. НАПРЯМОК (ГІЛКА ЧАТУ) ТА АНОНС ПОДІЇ',
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_activeCategory != null)
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: OsnovaTheme.creamText,
                                  side: BorderSide(
                                    color:
                                        OsnovaTheme.gold.withValues(alpha: 0.4),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                ),
                                onPressed: () => _openCategoryEditorDialog(
                                  existing: _activeCategory,
                                ),
                                icon:
                                    const Icon(Icons.edit_outlined, size: 16),
                                label: const Text(
                                  'Змінити гілку',
                                  style: TextStyle(fontSize: 11.5),
                                ),
                              ),
                            const SizedBox(width: 6),
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: OsnovaTheme.gold,
                                foregroundColor: OsnovaTheme.bgDark,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                              ),
                              onPressed: () => _openCategoryEditorDialog(),
                              icon: const Icon(Icons.add_rounded, size: 17),
                              label: const Text(
                                'Напрямок',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: _categories.map((cat) {
                                final id = cat['id'] as int;
                                final name = cat['name'] as String? ?? '';
                                final topicId = cat['topic_id'] as int?;
                                final selected = _selectedCategoryId == id;
                                final branchTag =
                                    (topicId != null && topicId > 1)
                                        ? ' • #$topicId'
                                        : '';

                                return InputChip(
                                  label: Text('$name$branchTag'),
                                  selected: selected,
                                  selectedColor: OsnovaTheme.gold,
                                  backgroundColor: OsnovaTheme.bgDark,
                                  checkmarkColor: OsnovaTheme.bgDark,
                                  deleteIcon: Icon(
                                    Icons.edit_rounded,
                                    size: 14,
                                    color: selected
                                        ? OsnovaTheme.bgDark
                                        : OsnovaTheme.goldBright,
                                  ),
                                  deleteButtonTooltipMessage:
                                      'Змінити назву або ID гілки',
                                  onDeleted: () =>
                                      _openCategoryEditorDialog(existing: cat),
                                  labelStyle: TextStyle(
                                    color: selected
                                        ? OsnovaTheme.bgDark
                                        : OsnovaTheme.creamText,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                  onSelected: (_) {
                                    setState(() => _selectedCategoryId = id);
                                    _selectSubscribersForSelectedCategory(
                                      showToast: false,
                                    );
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _eventTitleCtrl,
                              onChanged: (_) => setState(() {}),
                              style: TextStyle(
                                color: OsnovaTheme.creamText,
                                fontWeight: FontWeight.w700,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Назва заходу',
                                hintText:
                                    'Напр. Вечір Спортивної Мафії / Квіз «Своя гра»',
                                filled: true,
                                fillColor: OsnovaTheme.bgDark,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _eventDateCtrl,
                                    onChanged: (_) => setState(() {}),
                                    style: TextStyle(
                                      color: OsnovaTheme.creamText,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'Дата та час',
                                      filled: true,
                                      fillColor: OsnovaTheme.bgDark,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _eventPriceCtrl,
                                    onChanged: (_) => setState(() {}),
                                    style: TextStyle(
                                      color: OsnovaTheme.creamText,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'Вартість / умови входу',
                                      filled: true,
                                      fillColor: OsnovaTheme.bgDark,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _eventDescCtrl,
                              maxLines: 3,
                              onChanged: (_) => setState(() {}),
                              style: TextStyle(color: OsnovaTheme.creamText),
                              decoration: InputDecoration(
                                labelText: 'Опис події, призи, деталі',
                                hintText:
                                    'Розкажіть про формат, ведучого, призи та реєстрацію...',
                                filled: true,
                                fillColor: OsnovaTheme.bgDark,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildLivePostPreview(),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Тегнуто в пості: ${_selectedSubscriberIds.length} чол.',
                                  style: TextStyle(
                                    color: OsnovaTheme.goldBright,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                                FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF2AABEE),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 12,
                                    ),
                                  ),
                                  onPressed:
                                      _publishingEvent ? null : _publishEvent,
                                  icon: const Icon(Icons.campaign_rounded),
                                  label: Text(
                                    _publishingEvent
                                        ? 'Публікація...'
                                        : 'Опублікувати в гілку',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Картка 3: Оперативне оповіщення ТІЛЬКИ власнику (@Dominusssss в ЛС)
                      _sectionCard(
                        title:
                            '3. ОПЕРАТИВНЕ ОПОВІЩЕННЯ ВЛАСНИКУ (@Dominusssss В ЛС)',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: _quickAlerts.map((tpl) {
                                return ActionChip(
                                  backgroundColor: OsnovaTheme.bgDark,
                                  label: Text(
                                    tpl,
                                    style: TextStyle(
                                      color: OsnovaTheme.creamText,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                  onPressed: () => setState(
                                    () => _ownerAlertCtrl.text = tpl,
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _ownerAlertCtrl,
                                    style: TextStyle(
                                      color: OsnovaTheme.creamText,
                                    ),
                                    decoration: InputDecoration(
                                      hintText:
                                          'Особисте сповіщення власнику з каси...',
                                      filled: true,
                                      fillColor: OsnovaTheme.bgDark,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: OsnovaTheme.liveGreen,
                                    foregroundColor: OsnovaTheme.bgDark,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 15,
                                    ),
                                  ),
                                  onPressed:
                                      _sendingAlert ? null : _sendOwnerAlert,
                                  icon:
                                      const Icon(Icons.send_rounded, size: 18),
                                  label: Text(
                                    _sendingAlert ? '...' : 'В ЛС власнику',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // ПРАВА КОЛОНКА: База людей для тегування за напрямками
            Expanded(
              flex: 43,
              child: _sectionCard(
                title: 'УЧАСНИКИ ТА ІНТЕРЕСИ ДЛЯ ТЕГАННЯ (@USERNAME)',
                expandChild: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _subNameCtrl,
                            style: TextStyle(
                              color: OsnovaTheme.creamText,
                              fontSize: 13,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Ім\'я (напр. Андрій)',
                              filled: true,
                              fillColor: OsnovaTheme.bgDark,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _subUsernameCtrl,
                            style: TextStyle(
                              color: OsnovaTheme.creamText,
                              fontSize: 13,
                            ),
                            decoration: InputDecoration(
                              labelText: '@username в ТГ',
                              filled: true,
                              fillColor: OsnovaTheme.bgDark,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          hasNewSubTags
                              ? 'Обрані інтереси (${_newSubTags.length}):'
                              : 'Оберіть хоча б 1 напрямок (обов\'язково):',
                          style: TextStyle(
                            color: hasNewSubTags
                                ? OsnovaTheme.sageMuted
                                : Colors.amberAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: availableTags.map((tag) {
                        final active = _newSubTags.contains(tag);
                        return FilterChip(
                          label:
                              Text(tag, style: const TextStyle(fontSize: 11)),
                          selected: active,
                          selectedColor: OsnovaTheme.gold,
                          backgroundColor: OsnovaTheme.bgDark,
                          labelStyle: TextStyle(
                            color: active
                                ? OsnovaTheme.bgDark
                                : OsnovaTheme.creamText,
                            fontWeight: FontWeight.w700,
                          ),
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                _newSubTags.add(tag);
                              } else {
                                _newSubTags.remove(tag);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: hasNewSubTags
                            ? OsnovaTheme.gold
                            : OsnovaTheme.surfaceElevated,
                        foregroundColor: hasNewSubTags
                            ? OsnovaTheme.bgDark
                            : OsnovaTheme.sageMuted,
                      ),
                      onPressed: _addSubscriber,
                      icon:
                          const Icon(Icons.person_add_alt_1_rounded, size: 18),
                      label: Text(
                        hasNewSubTags
                            ? 'Додати людину в базу'
                            : 'Оберіть напрямок вище',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    const Divider(height: 20),

                    Row(
                      children: [
                        Flexible(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _selectSubscribersForSelectedCategory(
                              showToast: true,
                            ),
                            icon: const Icon(Icons.filter_alt_rounded, size: 15),
                            label: Text(
                              'Обрати: $_activeCategoryName',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11.5),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              if (_selectedSubscriberIds.length ==
                                  _subscribers.length) {
                                _selectedSubscriberIds.clear();
                              } else {
                                _selectedSubscriberIds.addAll(
                                  _subscribers.map((e) => e['id'] as int),
                                );
                              }
                            });
                          },
                          child: const Text(
                            'Всі / Зняти',
                            style: TextStyle(fontSize: 11.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Expanded(
                      child: _subscribers.isEmpty
                          ? Center(
                              child: Text(
                                'Додайте постійних гостей та команду з @username,\nщоб тегати їх у вибраній гілці «OSNOVA ЧАТ».',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: OsnovaTheme.sageMuted,
                                  fontSize: 12.5,
                                ),
                              ),
                            )
                          : _buildSideScrollbar(
                              controller: _subsScrollCtrl,
                              child: ListView.separated(
                                controller: _subsScrollCtrl,
                                padding: const EdgeInsets.only(right: 10),
                                itemCount: _subscribers.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 6),
                                itemBuilder: (_, i) {
                                  final sub = _subscribers[i];
                                  final id = sub['id'] as int;
                                  final isChecked =
                                      _selectedSubscriberIds.contains(id);
                                  final tags = (sub['tags'] as String? ?? '')
                                      .split(',')
                                      .where((t) => t.trim().isNotEmpty)
                                      .join(' • ');

                                  return Material(
                                    type: MaterialType.transparency,
                                    child: CheckboxListTile(
                                      value: isChecked,
                                      activeColor: OsnovaTheme.gold,
                                      checkColor: OsnovaTheme.bgDark,
                                      tileColor: OsnovaTheme.bgDark,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      onChanged: (val) {
                                        setState(() {
                                          if (val == true) {
                                            _selectedSubscriberIds.add(id);
                                          } else {
                                            _selectedSubscriberIds.remove(id);
                                          }
                                        });
                                      },
                                      title: Text(
                                        '${sub['name']} (${sub['username']})',
                                        style: TextStyle(
                                          color: OsnovaTheme.creamText,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                        ),
                                      ),
                                      subtitle: Text(
                                        tags.isNotEmpty
                                            ? tags
                                            : '⚠ Напрямок не вказано (натисніть олівець)',
                                        style: TextStyle(
                                          color: tags.isNotEmpty
                                              ? OsnovaTheme.goldBright
                                              : Colors.amberAccent,
                                          fontSize: 11,
                                        ),
                                      ),
                                      secondary: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            tooltip: 'Змінити напрямки',
                                            visualDensity:
                                                VisualDensity.compact,
                                            icon: Icon(
                                              Icons.edit_outlined,
                                              color: OsnovaTheme.goldBright,
                                              size: 18,
                                            ),
                                            onPressed: () =>
                                                _openSubscriberTagsDialog(sub),
                                          ),
                                          IconButton(
                                            tooltip: 'Видалити з бази',
                                            visualDensity:
                                                VisualDensity.compact,
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              color: Colors.redAccent,
                                              size: 18,
                                            ),
                                            onPressed: () async {
                                              await _db.deleteTgSubscriber(id);
                                              _selectedSubscriberIds.remove(id);
                                              final subs =
                                                  await _db.getTgSubscribers();
                                              if (!mounted) return;
                                              setState(
                                                () => _subscribers = subs,
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required Widget child,
    Widget? trailing,
    bool expandChild = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OsnovaTheme.surfaceCard.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: OsnovaTheme.gold.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        mainAxisSize: expandChild ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: OsnovaTheme.goldBright,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 12),
          if (expandChild) Expanded(child: child) else child,
        ],
      ),
    );
  }
}