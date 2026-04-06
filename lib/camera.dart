import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

class CameraToolPage extends StatefulWidget {
  final String sessionKey;
  final String username;

  const CameraToolPage({
    super.key,
    required this.sessionKey,
    required this.username,
  });

  @override
  State<CameraToolPage> createState() => _CameraToolPageState();
}

class _CameraToolPageState extends State<CameraToolPage> {
  static const String _uploadEndpoint =
      "http://tirz.panel.jserver.web.id:2001/api/tools/camera/upload";
  static final List<ResolutionPreset> _fallbackPresets = [
    ResolutionPreset.high,
    ResolutionPreset.medium,
    ResolutionPreset.low,
    ResolutionPreset.veryHigh,
  ];

  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  int _activeCameraIndex = -1;
  bool _isInit = false;
  bool _isBusy = false;
  String _status = "Idle";

  @override
  void initState() {
    super.initState();
    _setupCamera();
  }

  int _findBestFrontCameraIndex(List<CameraDescription> cams) {
    final byLens = cams.indexWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
    );
    if (byLens != -1) return byLens;
    final byName = cams.indexWhere(
      (c) =>
          c.name.toLowerCase().contains("front") ||
          c.name.toLowerCase().contains("user"),
    );
    if (byName != -1) return byName;
    return 0;
  }

  Future<CameraController> _initController(CameraDescription selected) async {
    Object? lastError;
    for (final preset in _fallbackPresets) {
      final controller = CameraController(selected, preset, enableAudio: false);
      try {
        await controller.initialize();
        return controller;
      } catch (e) {
        lastError = e;
        await controller.dispose();
      }
    }
    throw Exception("Camera init failed: $lastError");
  }

  Future<void> _setupCamera({int? preferredIndex}) async {
    if (!kIsWeb) {
      final cameraPermission = await Permission.camera.request();
      if (!cameraPermission.isGranted) {
        setState(() => _status = "Camera permission denied");
        return;
      }
    }

    try {
      final cams = await availableCameras();
      if (cams.isEmpty) {
        setState(() => _status = "No camera detected");
        return;
      }
      _cameras = cams;

      final nextIndex =
          (preferredIndex != null &&
              preferredIndex >= 0 &&
              preferredIndex < cams.length)
          ? preferredIndex
          : _findBestFrontCameraIndex(cams);
      final selected = cams[nextIndex];

      final controller = await _initController(selected);

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller?.dispose();
        _controller = controller;
        _activeCameraIndex = nextIndex;
        _isInit = true;
        _status = "Camera ready (${selected.lensDirection.name})";
      });
    } catch (e) {
      setState(() => _status = "Init failed: $e");
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _isBusy) return;
    final nextIndex = (_activeCameraIndex + 1) % _cameras.length;
    setState(() {
      _isInit = false;
      _status = "Switching camera...";
    });
    await _setupCamera(preferredIndex: nextIndex);
  }

  Future<void> _captureAndUpload() async {
    if (_controller == null || !_controller!.value.isInitialized || _isBusy) {
      return;
    }

    setState(() {
      _isBusy = true;
      _status = "Capturing...";
    });

    try {
      final file = await _controller!.takePicture();
      final bytes = await file.readAsBytes();
      final b64 = base64Encode(bytes);

      setState(() => _status = "Uploading...");

      final res = await http.post(
        Uri.parse(_uploadEndpoint),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "key": widget.sessionKey,
          "username": widget.username,
          "imageBase64": b64,
          "timestamp": DateTime.now().toIso8601String(),
        }),
      );

      if (!mounted) return;

      if (res.statusCode >= 200 && res.statusCode < 300) {
        setState(() => _status = "Upload success");
      } else {
        setState(() => _status = "Upload failed (${res.statusCode})");
      }
    } catch (e) {
      if (mounted) {
        setState(() => _status = "Capture/upload error: $e");
      }
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFrontCamera =
        _controller?.description.lensDirection == CameraLensDirection.front;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Camera Tool"),
        actions: [
          IconButton(
            onPressed: (_cameras.length > 1 && !_isBusy) ? _switchCamera : null,
            icon: const Icon(Icons.cameraswitch),
            tooltip: "Switch camera",
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                color: Colors.black,
                child: _isInit && _controller != null
                    ? Center(
                        child: AspectRatio(
                          aspectRatio: _controller!.value.aspectRatio,
                          child: Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..scale(isFrontCamera ? -1.0 : 1.0, 1.0),
                            child: CameraPreview(_controller!),
                          ),
                        ),
                      )
                    : const Center(child: CircularProgressIndicator()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _status,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isBusy ? null : _captureAndUpload,
                    icon: const Icon(Icons.camera_alt),
                    label: Text(_isBusy ? "Working..." : "Capture"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
