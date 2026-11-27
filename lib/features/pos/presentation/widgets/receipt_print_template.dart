import 'package:flutter/material.dart';

class ReceiptPrintItem {
  final String name;
  final int qty;
  final String unitPriceText;
  final String totalPriceText;

  const ReceiptPrintItem({
    required this.name,
    required this.qty,
    required this.unitPriceText,
    required this.totalPriceText,
  });
}

class ReceiptSummaryRow {
  final String label;
  final String value;
  final bool isBold;

  const ReceiptSummaryRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });
}

class ReceiptPrintData {
  final String documentTitle;
  final String? receiptCode;
  final String? shiftReceiptLabel;
  final String dateTimeText;
  final List<ReceiptPrintItem> items;
  final List<ReceiptSummaryRow> summaryRows;
  final String? grandTotalLabel;
  final String? grandTotalValue;
  final String? paymentMethodText;
  final String? fortuneTitle;
  final String? fortuneText;
  final String? footerNote;
  final bool showSocials;

  const ReceiptPrintData({
    required this.documentTitle,
    this.receiptCode,
    this.shiftReceiptLabel,
    required this.dateTimeText,
    this.items = const [],
    this.summaryRows = const [],
    this.grandTotalLabel,
    this.grandTotalValue,
    this.paymentMethodText,
    this.fortuneTitle,
    this.fortuneText,
    this.footerNote,
    this.showSocials = true,
  });
}

/// Єдиний візуальний макет чека для передперегляду та реального друку на Xprinter
class ReceiptPaperContent extends StatelessWidget {
  final ReceiptPrintData data;
  final bool is80mm;

  const ReceiptPaperContent({
    super.key,
    required this.data,
    this.is80mm = true,
  });

  @override
  Widget build(BuildContext context) {
    final double logicalWidth = is80mm ? 288.0 : 192.0;
    final double scale = is80mm ? 1.0 : 0.72;

    return Container(
      width: logicalWidth,
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
        6 * scale,
        6 * scale,
        6 * scale,
        8 * scale,
      ),
      child: DefaultTextStyle(
        style: TextStyle(
          color: Colors.black,
          fontFamily: 'Roboto',
          fontSize: 9.0 * scale,
          fontWeight: FontWeight.w700,
          height: 1.18,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Компактна шапка закладу
            Center(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 12 * scale,
                  vertical: 3 * scale,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 1.5),
                  borderRadius: BorderRadius.circular(3.5),
                ),
                child: Text(
                  'O S N O V A',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5 * scale,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            SizedBox(height: 3 * scale),
            Text(
              'ПРОСТІР ІГОР ТА КАВИ • КРОПИВНИЦЬКИЙ\nвул. А. Тарковського, 76/3',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 7.2 * scale,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
                color: Colors.black,
              ),
            ),

            SizedBox(height: 4 * scale),
            const _ReceiptDoubleDivider(),
            SizedBox(height: 4 * scale),

            // 2. Тип документа та код чека
            Text(
              data.documentTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.5 * scale,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
              ),
            ),

            if (data.receiptCode != null && data.receiptCode!.isNotEmpty) ...[
              SizedBox(height: 3.5 * scale),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 6 * scale,
                  vertical: 3 * scale,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(3.5),
                  border: Border.all(color: Colors.black, width: 1.0),
                ),
                child: Column(
                  children: [
                    Text(
                      'КОД ЧЕКА',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 6.5 * scale,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.9,
                      ),
                    ),
                    SizedBox(height: 1 * scale),
                    Text(
                      data.receiptCode!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9.2 * scale,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: 4 * scale),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (data.shiftReceiptLabel != null)
                  Text(
                    data.shiftReceiptLabel!,
                    style: TextStyle(
                      fontSize: 8.0 * scale,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                else
                  const SizedBox.shrink(),
                Text(
                  data.dateTimeText,
                  style: TextStyle(
                    fontSize: 8.0 * scale,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),

            SizedBox(height: 4 * scale),
            const _ReceiptDashedDivider(),
            SizedBox(height: 4 * scale),

            // 3. Позиції замовлення
            if (data.items.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'НАЙМЕНУВАННЯ',
                    style: TextStyle(
                      fontSize: 7.0 * scale,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'СУМА',
                    style: TextStyle(
                      fontSize: 7.0 * scale,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 3.5 * scale),
              ...data.items.map(
                (item) => Padding(
                  padding: EdgeInsets.only(bottom: 3.5 * scale),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 9.2 * scale,
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                        ),
                      ),
                      SizedBox(height: 1 * scale),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '  ${item.qty} × ${item.unitPriceText}',
                            style: TextStyle(
                              fontSize: 8.2 * scale,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            item.totalPriceText,
                            style: TextStyle(
                              fontSize: 9.2 * scale,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 1.5 * scale),
              const _ReceiptDashedDivider(),
              SizedBox(height: 4 * scale),
            ],

            // 4. Рядки зведення (X/Z-звіт, RRN або тест друку)
            if (data.summaryRows.isNotEmpty) ...[
              ...data.summaryRows.map(
                (row) => Padding(
                  padding: EdgeInsets.only(bottom: 3 * scale),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          row.label,
                          style: TextStyle(
                            fontSize: (row.isBold ? 8.8 : 8.2) * scale,
                            fontWeight:
                                row.isBold ? FontWeight.w900 : FontWeight.w700,
                          ),
                        ),
                      ),
                      SizedBox(width: 6 * scale),
                      Text(
                        row.value,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: (row.isBold ? 9.0 : 8.4) * scale,
                          fontWeight:
                              row.isBold ? FontWeight.w900 : FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 2 * scale),
              const _ReceiptDashedDivider(),
              SizedBox(height: 4 * scale),
            ],

            // 5. Підсумок та оплата
            if (data.grandTotalLabel != null &&
                data.grandTotalValue != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Text(
                      data.grandTotalLabel!,
                      style: TextStyle(
                        fontSize: 10.0 * scale,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  SizedBox(width: 6 * scale),
                  Text(
                    data.grandTotalValue!,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 12.0 * scale,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              if (data.paymentMethodText != null) ...[
                SizedBox(height: 2.5 * scale),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Оплата:',
                      style: TextStyle(
                        fontSize: 8.5 * scale,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        data.paymentMethodText!,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 8.8 * scale,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              SizedBox(height: 4.5 * scale),
              const _ReceiptDoubleDivider(),
              SizedBox(height: 4.5 * scale),
            ],

            // 6. Щасливе побажання / передбачення
            if (data.fortuneText != null &&
                data.fortuneText!.trim().isNotEmpty) ...[
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 6 * scale,
                  vertical: 4.5 * scale,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F2),
                  border: Border.all(color: Colors.black, width: 1.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  children: [
                    Text(
                      data.fortuneTitle ?? '★ ЩАСЛИВЕ ПОБАЖАННЯ ★',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 7.4 * scale,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 2 * scale),
                    Text(
                      data.fortuneText!.trim(),
                      textAlign: TextAlign.center,
                      softWrap: true,
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 8.3 * scale,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 4.5 * scale),
            ],

            // 7. Подяка та компактний блок соцмереж
            if (data.footerNote != null && data.footerNote!.isNotEmpty) ...[
              Text(
                data.footerNote!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 8.8 * scale,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 4 * scale),
            ],

            if (data.showSocials) ...[
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 6 * scale,
                  vertical: 4 * scale,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 1.0),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  children: [
                    Text(
                      'МИ В СОЦМЕРЕЖАХ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 7.0 * scale,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                    SizedBox(height: 2.5 * scale),
                    _SocialReceiptLine(
                      icon: Icons.play_circle_filled_rounded,
                      platform: 'YouTube:',
                      handle: 'Osnova76.3',
                      scale: scale,
                    ),
                    SizedBox(height: 1.5 * scale),
                    _SocialReceiptLine(
                      icon: Icons.send_rounded,
                      platform: 'Telegram:',
                      handle: 'Osnova76_3',
                      scale: scale,
                    ),
                    SizedBox(height: 1.5 * scale),
                    _SocialReceiptLine(
                      icon: Icons.camera_alt_rounded,
                      platform: 'Instagram:',
                      handle: 'Osnova_76.3',
                      scale: scale,
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: 4 * scale),
            Text(
              '★ ★ ★',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 8.0 * scale,
                fontWeight: FontWeight.w900,
                letterSpacing: 3.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReceiptPrintTemplate extends StatelessWidget {
  final GlobalKey boundaryKey;
  final ReceiptPrintData data;
  final bool is80mm;

  const ReceiptPrintTemplate({
    super.key,
    required this.boundaryKey,
    required this.data,
    this.is80mm = true,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: -3000,
      top: 0,
      child: RepaintBoundary(
        key: boundaryKey,
        child: ReceiptPaperContent(
          data: data,
          is80mm: is80mm,
        ),
      ),
    );
  }
}

class _SocialReceiptLine extends StatelessWidget {
  final IconData icon;
  final String platform;
  final String handle;
  final double scale;

  const _SocialReceiptLine({
    required this.icon,
    required this.platform,
    required this.handle,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 9.5 * scale, color: Colors.black),
        SizedBox(width: 3.5 * scale),
        Text(
          '$platform ',
          style: TextStyle(
            fontSize: 7.8 * scale,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          handle,
          style: TextStyle(
            fontSize: 8.1 * scale,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _ReceiptDashedDivider extends StatelessWidget {
  const _ReceiptDashedDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 4.5;
        const dashSpace = 3.0;
        final dashCount =
            (constraints.maxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: 1.0,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.black),
              ),
            );
          }),
        );
      },
    );
  }
}

class _ReceiptDoubleDivider extends StatelessWidget {
  const _ReceiptDoubleDivider();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Divider(height: 1.3, thickness: 1.3, color: Colors.black),
        SizedBox(height: 1.5),
        Divider(height: 0.9, thickness: 0.9, color: Colors.black),
      ],
    );
  }
}