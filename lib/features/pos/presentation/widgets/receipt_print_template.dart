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
    this.footerNote,
    this.showSocials = true,
  });
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
    // 288 логічних px * pixelRatio 2.0 = 576 px (повна ширина 80 мм Xprinter)
    // 192 логічних px * pixelRatio 2.0 = 384 px (повна ширина 58 мм Xprinter)
    final double logicalWidth = is80mm ? 288.0 : 192.0;
    final double scale = is80mm ? 1.0 : 0.78;

    return Positioned(
      left: -3000,
      top: 0,
      child: RepaintBoundary(
        key: boundaryKey,
        child: Container(
          width: logicalWidth,
          color: Colors.white,
          padding: EdgeInsets.fromLTRB(
            8 * scale,
            14 * scale,
            8 * scale,
            22 * scale,
          ),
          child: DefaultTextStyle(
            style: TextStyle(
              color: Colors.black,
              fontFamily: 'Roboto',
              fontSize: 16 * scale,
              fontWeight: FontWeight.w700,
              height: 1.28,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Шапка закладу по центру
                Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20 * scale,
                      vertical: 6 * scale,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 2.4),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      'O S N O V A',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 25 * scale,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.5,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 5 * scale),
                Text(
                  'ПРОСТІР ТА КАВ\'ЯРНЯ • КРОПИВНИЦЬКИЙ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12 * scale,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: Colors.black,
                  ),
                ),

                SizedBox(height: 8 * scale),
                const _ReceiptDoubleDivider(),
                SizedBox(height: 8 * scale),

                // 2. Тип документа та унікальний код чека
                Text(
                  data.documentTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 19 * scale,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),

                if (data.receiptCode != null && data.receiptCode!.isNotEmpty) ...[
                  SizedBox(height: 6 * scale),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8 * scale,
                      vertical: 6 * scale,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F2),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: Colors.black, width: 1.5),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'КОД ЧЕКА',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11 * scale,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(height: 2 * scale),
                        Text(
                          data.receiptCode!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16.5 * scale,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.9,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                SizedBox(height: 7 * scale),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (data.shiftReceiptLabel != null)
                      Text(
                        data.shiftReceiptLabel!,
                        style: TextStyle(
                          fontSize: 14 * scale,
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    else
                      const SizedBox.shrink(),
                    Text(
                      data.dateTimeText,
                      style: TextStyle(
                        fontSize: 14 * scale,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 7 * scale),
                const _ReceiptDashedDivider(),
                SizedBox(height: 7 * scale),

                // 3. Позиції замовлення на всю ширину стрічки
                if (data.items.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'НАЙМЕНУВАННЯ',
                        style: TextStyle(
                          fontSize: 12 * scale,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                        ),
                      ),
                      Text(
                        'СУМА',
                        style: TextStyle(
                          fontSize: 12 * scale,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6 * scale),
                  ...data.items.map(
                    (item) => Padding(
                      padding: EdgeInsets.only(bottom: 7 * scale),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            item.name,
                            style: TextStyle(
                              fontSize: 16.5 * scale,
                              fontWeight: FontWeight.w900,
                              height: 1.2,
                            ),
                          ),
                          SizedBox(height: 2 * scale),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '  ${item.qty} × ${item.unitPriceText}',
                                style: TextStyle(
                                  fontSize: 14.5 * scale,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                item.totalPriceText,
                                style: TextStyle(
                                  fontSize: 16.5 * scale,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 2 * scale),
                  const _ReceiptDashedDivider(),
                  SizedBox(height: 7 * scale),
                ],

                // 4. Рядки зведення (X-звіт, Z-звіт, RRN або тест друку)
                if (data.summaryRows.isNotEmpty) ...[
                  ...data.summaryRows.map(
                    (row) => Padding(
                      padding: EdgeInsets.only(bottom: 6 * scale),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              row.label,
                              style: TextStyle(
                                fontSize: (row.isBold ? 15.5 : 14.5) * scale,
                                fontWeight: row.isBold
                                    ? FontWeight.w900
                                    : FontWeight.w700,
                              ),
                            ),
                          ),
                          SizedBox(width: 8 * scale),
                          Text(
                            row.value,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: (row.isBold ? 16 : 15) * scale,
                              fontWeight: row.isBold
                                  ? FontWeight.w900
                                  : FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 4 * scale),
                  const _ReceiptDashedDivider(),
                  SizedBox(height: 7 * scale),
                ],

                // 5. Підсумкова сума та спосіб оплати
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
                            fontSize: 17 * scale,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      SizedBox(width: 8 * scale),
                      Text(
                        data.grandTotalValue!,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 21 * scale,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  if (data.paymentMethodText != null) ...[
                    SizedBox(height: 5 * scale),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Оплата:',
                          style: TextStyle(
                            fontSize: 15 * scale,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            data.paymentMethodText!,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 15.5 * scale,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  SizedBox(height: 8 * scale),
                  const _ReceiptDoubleDivider(),
                  SizedBox(height: 8 * scale),
                ],

                // 6. Подяка та соціальні мережі в самому низу по центру
                if (data.footerNote != null && data.footerNote!.isNotEmpty) ...[
                  Text(
                    data.footerNote!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16 * scale,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 8 * scale),
                ],

                if (data.showSocials) ...[
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8 * scale,
                      vertical: 8 * scale,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 1.6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'МИ В СОЦМЕРЕЖАХ',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.5 * scale,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                          ),
                        ),
                        SizedBox(height: 6 * scale),
                        _SocialReceiptLine(
                          icon: Icons.play_circle_filled_rounded,
                          platform: 'YouTube:',
                          handle: 'Osnova76.3',
                          scale: scale,
                        ),
                        SizedBox(height: 4 * scale),
                        _SocialReceiptLine(
                          icon: Icons.send_rounded,
                          platform: 'Telegram:',
                          handle: 'Osnova76_3',
                          scale: scale,
                        ),
                        SizedBox(height: 4 * scale),
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

                SizedBox(height: 8 * scale),
                Text(
                  '★ ★ ★',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 5,
                  ),
                ),
              ],
            ),
          ),
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
        Icon(icon, size: 17 * scale, color: Colors.black),
        SizedBox(width: 6 * scale),
        Text(
          '$platform ',
          style: TextStyle(
            fontSize: 14 * scale,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          handle,
          style: TextStyle(
            fontSize: 14.5 * scale,
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
        const dashWidth = 6.0;
        const dashSpace = 4.0;
        final dashCount =
            (constraints.maxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: 1.6,
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
        Divider(height: 2.2, thickness: 2.2, color: Colors.black),
        SizedBox(height: 2.5),
        Divider(height: 1.4, thickness: 1.4, color: Colors.black),
      ],
    );
  }
}