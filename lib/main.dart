import 'package:flutter/material.dart';
import 'package:osnova_pos/features/pos/data/services/report_export_impl.dart';
import 'package:osnova_pos/features/pos/domain/repositories/pos_repository_impl.dart';
import 'core/theme/osnova_theme.dart';
import 'features/pos/data/datasources/pos_local_datasource.dart';
import 'features/pos/data/services/xprinter_service_impl.dart';
import 'features/pos/presentation/controllers/pos_controller.dart';
import 'features/pos/presentation/pages/splash_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await OsnovaTheme.loadSavedTheme();
  await OsnovaTheme.applySystemUiStyle();

  final posController = PosController(
    repository: PosRepositoryImpl(PosLocalDataSource.instance),
    printerService: XprinterServiceImpl(),
    exportService: ReportExportServiceImpl(),
  );

  runApp(OsnovaPosApp(controller: posController));
}

class OsnovaPosApp extends StatelessWidget {
  final PosController controller;

  const OsnovaPosApp({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<OsnovaThemeId>(
      valueListenable: OsnovaTheme.themeNotifier,
      builder: (context, themeId, _) {
        return MaterialApp(
          title: 'OSNOVA POS',
          debugShowCheckedModeBanner: false,
          theme: OsnovaTheme.buildTheme(themeId),
          home: SplashPage(controller: controller),
        );
      },
    );
  }
}