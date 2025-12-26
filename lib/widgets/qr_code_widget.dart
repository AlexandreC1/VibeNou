import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// QR Code widget for displaying 2FA setup codes
class QRCodeWidget extends StatelessWidget {
  final String data;
  final double size;
  final Color? foregroundColor;
  final Color? backgroundColor;

  const QRCodeWidget({
    super.key,
    required this.data,
    this.size = 200,
    this.foregroundColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: QrImageView(
        data: data,
        version: QrVersions.auto,
        size: size,
        eyeStyle: QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: foregroundColor ?? Colors.black,
        ),
        dataModuleStyle: QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: foregroundColor ?? Colors.black,
        ),
        backgroundColor: backgroundColor ?? Colors.white,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
      ),
    );
  }
}
