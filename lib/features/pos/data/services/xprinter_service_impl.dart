import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/pos_entities.dart';
import '../../domain/repositories/pos_repositories.dart';

class XprinterServiceImpl implements PrinterService {
  static const _keyIp = 'osnova_printer_ip';
  static const _keyPort = 'osnova_printer_port';
  static const _keyIs80mm = 'osnova_printer_80mm';
  static const _keyAutoPrint = 'osnova_printer_auto_print';

  @override
  Future<PrinterSettingsEntity> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return PrinterSettingsEntity(
      ip: prefs.getString(_keyIp) ?? '',
      port: prefs.getInt(_keyPort) ?? 9100,
      is80mm: prefs.getBool(_keyIs80mm) ?? true,
      autoPrint: prefs.getBool(_keyAutoPrint) ?? true,
    );
  }

  @override
  Future<void> saveSettings({
    required String ip,
    int port = 9100,
    required bool is80mm,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyIp, ip.trim());
    await prefs.setInt(_keyPort, port);
    await prefs.setBool(_keyIs80mm, is80mm);
  }

  @override
  Future<void> saveAutoPrint(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoPrint, enabled);
  }

  @override
  Future<void> clearSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIp);
    await prefs.remove(_keyPort);
    await prefs.setBool(_keyAutoPrint, false);
  }

  @override
  Future<List<String>> discoverNetworkPrinters({int port = 9100}) async {
    final found = <String>[];
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLinkLocal: false,
    );

    final subnets = <String>{};
    for (final iface in interfaces) {
      for (final addr in iface.addresses) {
        final parts = addr.address.split('.');
        if (parts.length == 4) {
          subnets.add('${parts[0]}.${parts[1]}.${parts[2]}');
        }
      }
    }

    for (final subnet in subnets) {
      final futures = <Future<void>>[];
      for (int host = 1; host <= 254; host++) {
        final ip = '$subnet.$host';
        futures.add(() async {
          try {
            final socket = await Socket.connect(
              ip,
              port,
              timeout: const Duration(milliseconds: 220),
            );
            socket.destroy();
            found.add(ip);
          } catch (_) {}
        }());
      }
      await Future.wait(futures);
    }

    found.sort();
    return found;
  }

  @override
  Future<Uint8List?> captureWidgetAsImage(GlobalKey boundaryKey) async {
    final boundary = boundaryKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) return null;

    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  @override
  Future<void> printImageOverWifi(Uint8List pngBytes) async {
    final settings = await loadSettings();
    if (settings.ip.isEmpty) {
      throw Exception('IP-адресу принтера Xprinter не вказано');
    }

    // 80 мм = 576 точок, 58 мм = 384 точки (стандарт ESC/POS 203 DPI)
    final int targetWidth = settings.is80mm ? 576 : 384;

    final codec = await ui.instantiateImageCodec(pngBytes);
    final frame = await codec.getNextFrame();
    final srcImage = frame.image;

    final double scale = targetWidth / srcImage.width;
    final int targetHeight = (srcImage.height * scale).round();

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final bgPaint = ui.Paint()..color = const ui.Color(0xFFFFFFFF);
    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble()),
      bgPaint,
    );

    final double scaledWidth = srcImage.width * scale;
    final double dx = ((targetWidth - scaledWidth) / 2).clamp(
      0.0,
      targetWidth.toDouble(),
    );

    canvas.drawImageRect(
      srcImage,
      ui.Rect.fromLTWH(
        0,
        0,
        srcImage.width.toDouble(),
        srcImage.height.toDouble(),
      ),
      ui.Rect.fromLTWH(
        dx,
        0,
        scaledWidth,
        targetHeight.toDouble(),
      ),
      ui.Paint()..filterQuality = ui.FilterQuality.high,
    );

    final normalizedImage = await recorder
        .endRecording()
        .toImage(targetWidth, targetHeight);
    final rgbaData = await normalizedImage.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
    if (rgbaData == null) {
      throw Exception('Не вдалося обробити растр чека');
    }

    final escPosBytes = _buildEscPosRasterCommand(
      rgba: rgbaData.buffer.asUint8List(),
      width: targetWidth,
      height: targetHeight,
    );

    final socket = await Socket.connect(
      settings.ip,
      settings.port,
      timeout: const Duration(seconds: 4),
    );
    try {
      socket.add(escPosBytes);
      await socket.flush();
      await Future.delayed(const Duration(milliseconds: 250));
    } finally {
      await socket.close();
    }
  }

  Uint8List _buildEscPosRasterCommand({
    required Uint8List rgba,
    required int width,
    required int height,
  }) {
    final bytesPerRow = (width + 7) ~/ 8;
    final builder = BytesBuilder();

    // ESC @ — Ініціалізація принтера
    builder.add([0x1B, 0x40]);
    // ESC a 1 — Вирівнювання по центру на рівні Xprinter
    builder.add([0x1B, 0x61, 0x01]);

    // GS v 0 m xL xH yL yH — Друк растрового зображення
    final xL = bytesPerRow & 0xFF;
    final xH = (bytesPerRow >> 8) & 0xFF;
    final yL = height & 0xFF;
    final yH = (height >> 8) & 0xFF;
    builder.add([0x1D, 0x76, 0x30, 0x00, xL, xH, yL, yH]);

    final raster = Uint8List(bytesPerRow * height);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final offset = (y * width + x) * 4;
        final r = rgba[offset];
        final g = rgba[offset + 1];
        final b = rgba[offset + 2];
        final a = rgba[offset + 3];

        final luminance = (0.299 * r + 0.587 * g + 0.114 * b);
        final isBlack = a > 128 && luminance < 192;

        if (isBlack) {
          final byteIndex = y * bytesPerRow + (x >> 3);
          raster[byteIndex] |= (0x80 >> (x & 7));
        }
      }
    }

    builder.add(raster);

    // Протяжка стрічки та відріз чека (GS V 66 0)
    builder.add([0x1B, 0x64, 0x04]);
    builder.add([0x1D, 0x56, 0x42, 0x00]);

    return builder.toBytes();
  }
}