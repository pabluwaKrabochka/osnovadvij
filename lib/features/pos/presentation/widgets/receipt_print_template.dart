import 'package:flutter/material.dart';

class ReceiptPrintTemplate extends StatelessWidget {
  final GlobalKey boundaryKey;
  final String title;
  final List<String> lines;

  const ReceiptPrintTemplate({
    super.key,
    required this.boundaryKey,
    required this.title,
    required this.lines,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: -1000,
      top: 0,
      child: RepaintBoundary(
        key: boundaryKey,
        child: Container(
          width: 384,
          color: Colors.white,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              ...lines.map(
                (line) => Text(
                  line,
                  style: const TextStyle(fontSize: 15, color: Colors.black, height: 1.3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}