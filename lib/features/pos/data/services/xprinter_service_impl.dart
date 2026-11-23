import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/pos_entities.dart';
import '../../domain/repositories/pos_repositories.dart';

class XprinterServiceImpl implements PrinterService {
  static const _keyIp = 'printer_ip';
  static const _keyPort = 'printer_port';
  static const _keyIs80mm = 'printer_is_80mm';
  static const _keyAutoPrint = 'printer_auto_print';

  bool _isEmulatorOrLoopbackIp(String ip) {
    return ip.startsWith('10.0.2.') || ip.startsWith('127.');
  }

@override
  Future<PrinterSettingsEntity> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIp = prefs.getString(_keyIp) ?? '';
    final autoPrint = prefs.getBool(_keyAutoPrint) ?? true;

    if (_isEmulatorOrLoopbackIp(savedIp)) {
      await clearSettings();
      return PrinterSettingsEntity(
        ip: '',
        port: 9100,
        is80mm: false,
        autoPrint: autoPrint,
      );
    }

   return PrinterSettingsEntity(
      ip: savedIp,
      port: prefs.getInt(_keyPort) ?? 9100,
      is80mm: prefs.getBool(_keyIs80mm) ?? false,
      autoPrint: autoPrint,
    );
  }
  @override
  Future<void> saveAutoPrint(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoPrint, enabled);
  }
  @override
  Future<void> saveSettings({
    required String ip,
    int port = 9100,
    required bool is80mm,
  }) async {
    final cleanIp = ip.trim();
    if (_isEmulatorOrLoopbackIp(cleanIp)) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyIp, cleanIp);
    await prefs.setInt(_keyPort, port);
    await prefs.setBool(_keyIs80mm, is80mm);
  }

  @override
  Future<void> clearSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIp);
    await prefs.remove(_keyPort);
    await prefs.remove(_keyIs80mm);
  }

  Future<String?> _getLocalSubnet() async {
    final interfaces = await NetworkInterface.list(
      includeLoopback: false,
      type: InternetAddressType.IPv4,
    );

    for (final interface in interfaces) {
      for (final addr in interface.addresses) {
        final ip = addr.address;
        // Ігноруємо віртуальну NAT-мережу Android-емулятора (10.0.2.x)
        if (_isEmulatorOrLoopbackIp(ip)) continue;

        if (ip.startsWith('192.168.') || ip.startsWith('10.') || ip.startsWith('172.')) {
          final parts = ip.split('.');
          if (parts.length == 4) {
            return '${parts[0]}.${parts[1]}.${parts[2]}';
          }
        }
      }
    }
    return null;
  }

  @override
  Future<List<String>> discoverNetworkPrinters({int port = 9100}) async {
    final subnet = await _getLocalSubnet();
    if (subnet == null) return [];

    final List<String> foundPrinters = [];
    const batchSize = 64;

    for (int start = 1; start <= 254; start += batchSize) {
      final end = (start + batchSize - 1).clamp(1, 254);
      final futures = <Future<void>>[];

      for (int i = start; i <= end; i++) {
        final targetIp = '$subnet.$i';
        futures.add(() async {
          try {
            final socket = await Socket.connect(
              targetIp,
              port,
              timeout: const Duration(milliseconds: 350),
            );
            socket.destroy();
            foundPrinters.add(targetIp);
          } catch (_) {}
        }());
      }
      await Future.wait(futures);
    }

    return foundPrinters;
  }

  @override
  Future<Uint8List?> captureWidgetAsImage(GlobalKey boundaryKey) async {
    final boundary =
        boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;

    final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  @override
  Future<void> printImageOverWifi(Uint8List pngBytes) async {
    final settings = await loadSettings();
    if (settings.ip.isEmpty) {
      throw Exception('Принтер не обрано. Підключіть Xprinter у налаштуваннях (⚙).');
    }

    final paperSize = settings.is80mm ? PaperSize.mm80 : PaperSize.mm58;
    final targetWidth = settings.is80mm ? 576 : 384;

    final profile = await CapabilityProfile.load();
    final generator = Generator(paperSize, profile);
    final List<int> bytes = [];

    final decodedImage = img.decodeImage(pngBytes);
    if (decodedImage != null) {
      final resized = img.copyResize(decodedImage, width: targetWidth);
      bytes.addAll(generator.imageRaster(resized));
    }

    bytes.addAll(generator.feed(2));
    bytes.addAll(generator.cut());

    final socket = await Socket.connect(
      settings.ip,
      settings.port,
      timeout: const Duration(seconds: 3),
    );
    socket.add(bytes);
    await socket.flush();
    await socket.close();
  }
  
}