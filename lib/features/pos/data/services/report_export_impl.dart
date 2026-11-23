import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../domain/entities/pos_entities.dart';
import '../../domain/repositories/pos_repositories.dart';

class ReportExportServiceImpl implements ReportExportService {
  @override
  Future<void> shareReportFile(ShiftReportEntity report) async {
    final reportType = report.isZReport ? 'Z-ЗВІТ (ЗАКРИТТЯ ЗМІНИ)' : 'X-ЗВІТ (ПРОМІЖНИЙ)';
    final openedFormatted = DateFormat('dd.MM.yyyy HH:mm').format(DateTime.parse(report.openedAt));
    final generatedFormatted = DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now());

    final buffer = StringBuffer()
      ..writeln('========================================')
      ..writeln('         OSNOVA • КРОПИВНИЦЬКИЙ         ')
      ..writeln('         $reportType')
      ..writeln('========================================')
      ..writeln('Зміна від:  $openedFormatted')
      ..writeln('Сформовано: $generatedFormatted')
      ..writeln('----------------------------------------')
      ..writeln('ПРОДАЖІ:')
      ..writeln('Кількість чеків:     ${report.ordersCount}')
      ..writeln('Виручка готівкою:    ${MoneyFormatter.format(report.cashSales)}')
      ..writeln('Виручка карткою:     ${MoneyFormatter.format(report.cardSales)}')
      ..writeln('ЗАГАЛЬНА ВИРУЧКА:    ${MoneyFormatter.format(report.totalRevenue)}')
      ..writeln('----------------------------------------')
      ..writeln('РУХ ГОТІВКИ В КАСІ:')
      ..writeln('Розмін на старті:    ${MoneyFormatter.format(report.openingCash)}')
      ..writeln('Витрати з каси:     -${MoneyFormatter.format(report.cashDrawerExpenses)}')
      ..writeln('Інші витрати (карта):${MoneyFormatter.format(report.externalExpenses)}')
      ..writeln('ГОТІВКИ В ШУХЛЯДІ:   ${MoneyFormatter.format(report.expectedCashInDrawer)}')
      ..writeln('----------------------------------------');

    if (report.expensesList.isNotEmpty) {
      buffer.writeln('ДЕТАЛІЗАЦІЯ ВИТРАТ:');
      for (final exp in report.expensesList) {
        final time = DateFormat('HH:mm').format(DateTime.parse(exp.createdAt));
        final src = exp.source == 'cash_drawer' ? 'каса' : 'картка';
        buffer.writeln('• [$time] ${exp.title} — ${MoneyFormatter.format(exp.amount)} ($src)');
      }
      buffer.writeln('----------------------------------------');
    }

   Directory dir;
    try {
      dir = await getTemporaryDirectory();
    } catch (_) {
      dir = Directory.systemTemp;
    }

    final dateTag = DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now());
    final prefix = report.isZReport ? 'Z_zvit' : 'X_zvit';
    final fileName = 'OSNOVA_${prefix}_$dateTag.txt';
    final file = File(join(dir.path, fileName));
    await file.writeAsString(buffer.toString());
    
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'OSNOVA $reportType • Зміна №${report.shiftId}',
      text: 'OSNOVA • $reportType (Зміна №${report.shiftId}) | Виручка: ${MoneyFormatter.format(report.totalRevenue)}',
    );
  }
}