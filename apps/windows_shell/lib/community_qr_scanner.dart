import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:zxing2/qrcode.dart';

Future<String?> scanCommunityQr(BuildContext context) {
  return Navigator.of(context).push<String>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => const _WindowsCommunityQrScannerPage(),
    ),
  );
}

class _WindowsCommunityQrScannerPage extends StatefulWidget {
  const _WindowsCommunityQrScannerPage();

  @override
  State<_WindowsCommunityQrScannerPage> createState() =>
      _WindowsCommunityQrScannerPageState();
}

class _WindowsCommunityQrScannerPageState
    extends State<_WindowsCommunityQrScannerPage> {
  CameraController? _controller;
  String _status = 'Opening camera...';
  bool _busy = true;

  @override
  void initState() {
    super.initState();
    _openCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _openCamera() async {
    try {
      final cameras = await availableCameras();
      if (!mounted) {
        return;
      }
      if (cameras.isEmpty) {
        setState(() {
          _busy = false;
          _status = 'No camera was found.';
        });
        return;
      }
      final controller = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _busy = false;
        _status = 'Frame the QR code and capture once.';
      });
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _status = 'No camera was found.';
      });
    }
  }

  Future<void> _captureAndDecode() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _busy) {
      return;
    }
    setState(() {
      _busy = true;
      _status = 'Reading QR code...';
    });
    try {
      final file = await controller.takePicture();
      final bytes = await file.readAsBytes();
      final value = _decodeQr(bytes);
      if (!mounted) {
        return;
      }
      if (value == null || value.trim().isEmpty) {
        setState(() {
          _busy = false;
          _status = 'No QR code was found in this frame.';
        });
        return;
      }
      Navigator.of(context).pop(value.trim());
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _status = 'No QR code was found in this frame.';
      });
    }
  }

  String? _decodeQr(Uint8List bytes) {
    final image = img.decodeImage(bytes);
    if (image == null) {
      return null;
    }
    final source = RGBLuminanceSource(
      image.width,
      image.height,
      image
          .convert(numChannels: 4)
          .getBytes(order: img.ChannelOrder.rgba)
          .buffer
          .asInt32List(),
    );
    final bitmap = BinaryBitmap(HybridBinarizer(source));
    return QRCodeReader().decode(bitmap).text;
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR code'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: controller == null || !controller.value.isInitialized
                      ? Center(
                          child: Text(
                            _status,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white),
                          ),
                        )
                      : CameraPreview(controller),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _status,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _busy ? null : _captureAndDecode,
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: const Text('Capture QR'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Keys and subscription URLs stay on this device.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
