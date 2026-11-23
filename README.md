# osnovadvij
lib/
├── main.dart                                           # Точка входу та ініціалізація залежностей
├── core/
│   ├── theme/
│   │   └── osnova_theme.dart                           # Кольори OSNOVA, тема Material 3, іконки категорій
│   └── utils/
│       └── money_formatter.dart                        # Конвертація копійок у формат "80.00 грн"
└── features/
    └── pos/
        ├── domain/
        │   ├── entities/
        │   │   └── pos_entities.dart                   # Чисті моделі: Shift, Product, CartItem, ShiftReport
        │   └── repositories/
        │       └── pos_repositories.dart               # Інтерфейси БД, принтера та експорту звітів
        ├── data/
        │   ├── datasources/
        │   │   └── pos_local_datasource.dart           # SQLite (shifts, products, orders, expenses)
        │   ├── repositories/
        │   │   └── pos_repository_impl.dart            # Реалізація репозиторію каси
        │   └── services/
        │       ├── xprinter_service_impl.dart          # Автопошук у Wi-Fi та ESC/POS друк
        │       └── report_export_service_impl.dart     # Генерація файлу звіту та Share у Telegram
        └── presentation/
            ├── controllers/
            │   └── pos_controller.dart                 # Стан та бізнес-логіка (ChangeNotifier)
            ├── pages/
            │   └── pos_page.dart                       # Головний екран каси
            └── widgets/
                ├── osnova_brand_logo.dart              # Логотип OSNOVA, пульс зміни та кнопка суми в касі
                ├── animated_product_card.dart          # Картка позиції з hover та періодичною анімацією іконки
                ├── cart_panel.dart                     # Права панель замовлення та оплати
                ├── receipt_print_template.dart         # Прихований макет чека для рендеру в PNG
                └── pos_dialogs.dart                    # Діалоги: редагування каси, звітів, витрат, Wi-Fi принтера