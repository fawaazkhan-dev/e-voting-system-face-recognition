import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'api_service.dart';
import 'login_screen.dart';

class FacePainter extends CustomPainter {
  final List<Face> faces;
  final String recognizedUserName;
  final double rotationAngle;
  final double originalImageWidth;
  final double originalImageHeight;

  FacePainter({
    required this.faces,
    required this.recognizedUserName,
    required this.rotationAngle,
    required this.originalImageWidth,
    required this.originalImageHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double scaleX = size.width / originalImageWidth;
    final double scaleY = size.height / originalImageHeight;

    final Paint paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    for (final face in faces) {
      final rect = face.boundingBox;
      final transformedRect = Rect.fromLTRB(
        rect.left * scaleX,
        rect.top * scaleY,
        rect.right * scaleX,
        rect.bottom * scaleY,
      );

      canvas.save();
      canvas.translate(transformedRect.center.dx, transformedRect.center.dy);
      canvas.rotate(rotationAngle);
      canvas.translate(-transformedRect.center.dx, -transformedRect.center.dy);

      canvas.drawRect(transformedRect, paint);

      if (recognizedUserName.isNotEmpty) {
        final TextSpan span = TextSpan(
          style: TextStyle(color: Colors.white, fontSize: 20.0),
          text: recognizedUserName,
        );
        final TextPainter tp = TextPainter(
          text: span,
          textAlign: TextAlign.left,
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(canvas, Offset(transformedRect.left, transformedRect.bottom + 5));
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}


class FaceRecognitionScreen extends StatefulWidget {
  @override
  _FaceRecognitionScreenState createState() => _FaceRecognitionScreenState();
}

class _FaceRecognitionScreenState extends State<FaceRecognitionScreen> {
  CameraController? _cameraController;
  FaceDetector? _faceDetector;
  bool _isDetecting = false;
  List<Face> _faces = [];
  String _recognizedUserName = "";
  final _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _faceDetector = GoogleMlKit.vision.faceDetector(
      FaceDetectorOptions(
        enableContours: true,
        enableClassification: true,
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector?.close();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    _cameraController = CameraController(cameras[1], ResolutionPreset.high);
    await _cameraController?.initialize();
    if (!mounted) return;
    setState(() {});
    _cameraController?.startImageStream((CameraImage image) {
      _processCameraImage(image);
    });
  }

  void _processCameraImage(CameraImage image) async {
    if (_isDetecting) return;

    setState(() {
      _isDetecting = true;
    });

    final WriteBuffer allBytes = WriteBuffer();
    for (Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final InputImage inputImage = InputImage.fromBytes(
      bytes: bytes,
      inputImageData: InputImageData(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        imageRotation: InputImageRotation.Rotation_0deg,
        inputImageFormat: InputImageFormatMethods.fromRawValue(image.format.raw) ?? InputImageFormat.NV21,
        planeData: image.planes.map(
              (Plane plane) {
            return InputImagePlaneMetadata(
              bytesPerRow: plane.bytesPerRow,
              height: plane.height,
              width: plane.width,
            );
          },
        ).toList(),
      ),
    );

    final faces = await _faceDetector!.processImage(inputImage);

    if (faces.isNotEmpty) {
      setState(() {
        _faces = faces;
      });

      bool livenessDetected = _performLivenessDetection(faces);

      if (!livenessDetected) {
        Fluttertoast.showToast(
          msg: "Liveness detection failed",
          toastLength: Toast.LENGTH_LONG,
        );
        setState(() {
          _isDetecting = false;
        });
        return;
      } else {
        Fluttertoast.showToast(
          msg: "Liveness detection ok",
          toastLength: Toast.LENGTH_LONG,
        );
      }

      final XFile imageFile = await _cameraController!.takePicture();
      final String capturedImagePath = imageFile.path;

      print("Captured Image Path: $capturedImagePath");

      final response = await _apiService.recognizeFace(capturedImagePath);

      final directory = await getExternalStorageDirectory();
      final targetPath = '${directory!.path}/Windows/Project';

      final targetDir = Directory(targetPath);
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      final newImagePath = '$targetPath/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final imageFileToCopy = File(capturedImagePath);
      final newImageFile = File(newImagePath);
      await imageFileToCopy.copy(newImageFile.path);

      print("Image copied to: $newImagePath");

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        Fluttertoast.showToast(
          msg: "Authorized: ${result['user']}",
          toastLength: Toast.LENGTH_LONG,
        );

        Future.delayed(Duration(seconds: 5), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen(isFaceRecognized: true, recognizedEmail: result['user'])),
          );
        });
      } else {
        Fluttertoast.showToast(
          msg: "Face recognition failed",
          toastLength: Toast.LENGTH_LONG,
        );
      }
      _stopCameraStream();
    } else {
      setState(() {
        _faces = [];
        _recognizedUserName = "";
      });
    }

    setState(() {
      _isDetecting = false;
    });
  }

  bool _performLivenessDetection(List<Face> faces) {
    if (faces.isEmpty) return false;

    Face face = faces[0];
    double? leftEyeOpenProbability = face.leftEyeOpenProbability;
    double? rightEyeOpenProbability = face.rightEyeOpenProbability;

    const double eyeOpenThreshold = 0.5;

    if (leftEyeOpenProbability != null && rightEyeOpenProbability != null) {
      if (leftEyeOpenProbability > eyeOpenThreshold && rightEyeOpenProbability > eyeOpenThreshold) {
        return true;
      }
    }

    return false;
  }

  void _stopCameraStream() {
    _cameraController?.stopImageStream();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Face Recognition')),
      body: Stack(
        children: [
          if (_cameraController != null && _cameraController!.value.isInitialized)
            Center(
              child: Transform.rotate(
                angle: -180 * pi / 180, // Rotate by 90 degrees
                // angle: 0 * pi / 180, // Rotate by 0 degrees
                child: Container(
                  width: 600, // Set the desired width
                  height: 800, // Set the desired height
                  child: AspectRatio(
                    aspectRatio: _cameraController!.value.aspectRatio,
                    child: CameraPreview(_cameraController!),
                  ),
                ),
              ),
            ),//MOD
          CustomPaint(
            painter: FacePainter(
              faces: _faces,
              recognizedUserName: _recognizedUserName,
              originalImageWidth: _cameraController!.value.previewSize!.width,
              originalImageHeight: _cameraController!.value.previewSize!.height,
              // rotationAngle: -pi / 2, // 90 degrees in radians
              rotationAngle: -pi,
              // rotationAngle: 0 / 2, // 0 degrees in radians
            ),
            child: Container(),
          ),
        ],
      ),
    );
  }
}
