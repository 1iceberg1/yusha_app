import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:yusha_test/widgets/hover_button.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  final ImagePicker _picker = ImagePicker();
  File? selectedGif;
  bool showGifOverlay = false;
  bool isArMode = false;
  CameraController? _cameraController;
  List<CameraDescription>? cameras;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    try {
      cameras = await availableCameras();
      if (cameras != null && cameras!.isNotEmpty) {
        _cameraController = CameraController(
          cameras!.first,
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        setState(() {});
      }
    } catch (e) {
      print("Error initializing camera: $e");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.paused) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      initializeCamera(); // Reinitialize the camera when resuming
    }
  }

  Future<void> fetchGIFs() async {
    try {
      final List<XFile>? files = await _picker.pickMultiImage();
      if (files != null) {
        final List<File> gifs = files
            .map((file) => File(file.path))
            .where((file) => file.path.toLowerCase().endsWith('.gif'))
            .toList();

        if (gifs.isNotEmpty) {
          setState(() {
            selectedGif = gifs.first; // Keep only the first GIF as selected
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error while fetching GIFs: $e')),
      );
    }
  }

  void startArMode() {
    if (selectedGif == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a GIF first.")),
      );
      return;
    }

    setState(() {
      isArMode = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56.0), // Standard AppBar height
        child: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.grey[800],
          elevation: 0,
          leading: showGifOverlay
              ? Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: HoverButton(
                    icon: Icons.vrpano,
                    defaultColor: Colors.white,
                    strokeColor: Colors.grey,
                    onPressed: startArMode,
                  ),
                )
              : null,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: HoverButton(
                icon: Icons.undo,
                defaultColor: Colors.white,
                strokeColor: Colors.grey,
                onPressed: () {
                  if (!showGifOverlay && !isArMode) {
                    Navigator.pop(context);
                  } else {
                    if (selectedGif != null) {
                      setState(() {
                        if (isArMode)
                          isArMode = false;
                        else if (showGifOverlay) showGifOverlay = false;
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Please select a GIF before exiting."),
                        ),
                      );
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          if (isArMode)
            _cameraController != null && _cameraController!.value.isInitialized
                ? Stack(
                    children: [
                      CameraPreview(_cameraController!),
                      if (selectedGif != null)
                        Positioned(
                          left: MediaQuery.of(context).size.width * 0.25,
                          top: MediaQuery.of(context).size.height * 0.35,
                          child: Image.file(
                            selectedGif!,
                            width: 150,
                            height: 150,
                            fit: BoxFit.contain,
                          ),
                        ),
                    ],
                  )
                : const Center(child: CircularProgressIndicator())
          else if (showGifOverlay && selectedGif != null)
            Positioned.fill(
              child: Stack(
                children: [
                  Container(color: Colors.black.withOpacity(0.5)),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.file(
                          selectedGif!,
                          fit: BoxFit.contain,
                          width: MediaQuery.of(context).size.width * 0.6,
                          height: MediaQuery.of(context).size.height * 0.4,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("GIF Saved!"),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 24),
                          ),
                          child: SizedBox(
                            width: 150, // Set desired width here
                            child: Center(
                              child: Text(
                                "Save",
                                style: TextStyle(color: Colors.orange),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                Expanded(
                  flex: 2,
                  child: Stack(
                    children: [
                      Container(color: Colors.grey[800]),
                      Positioned(
                        bottom: 0,
                        child: CustomPaint(
                          size: Size(MediaQuery.of(context).size.width, 80),
                          painter: CurvePainter(),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        left: MediaQuery.of(context).size.width / 2 - 32,
                        child: CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.camera_alt,
                              color: Colors.orange,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Container(
                    height: MediaQuery.of(context).size.height /
                        4, // Adjusted height for better proportions
                    width: MediaQuery.of(context).size.width,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text(
                            "Camera Preview",
                            style: TextStyle(color: Colors.black, fontSize: 20),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width / 2.5,
                          child: ElevatedButton(
                            onPressed: fetchGIFs,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pink[100],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              "Upload",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width / 2.5,
                          child: ElevatedButton(
                            onPressed: () {
                              if (selectedGif != null) {
                                setState(() {
                                  showGifOverlay = true;
                                });
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        "Please select a GIF before exiting."),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              "Exit",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class CurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final double rad = 20.0;
    final double PI = 3.141592;
    final double offsetY = 10;

    final path = Path()
      ..moveTo(0, size.height + offsetY)
      ..arcTo(
        Rect.fromCircle(center: Offset(rad, size.height - rad), radius: rad),
        PI,
        1.57,
        false,
      )
      ..lineTo(size.width / 2 - rad * 2, size.height - rad * 2)
      ..arcTo(
        Rect.fromCircle(
          center: Offset(
              size.width / 2 - 2.25 * rad, size.height - 2 * rad + 0.25 * rad),
          radius: rad / 4,
        ),
        -1.57,
        PI / 2,
        false,
      )
      ..arcTo(
        Rect.fromCircle(
          center: Offset(size.width / 2, size.height - rad * 2),
          radius: rad * 2,
        ),
        PI * 0.9,
        -PI * 0.8,
        false,
      )
      ..arcTo(
        Rect.fromCircle(
          center: Offset(
              size.width / 2 + 2.25 * rad, size.height - 2 * rad + 0.25 * rad),
          radius: rad / 4,
        ),
        PI,
        PI / 2,
        false,
      )
      ..lineTo(size.width - rad, size.height - rad * 2)
      ..arcTo(
        Rect.fromCircle(
          center: Offset(size.width - rad, size.height - rad),
          radius: rad,
        ),
        -1.57,
        1.57,
        false,
      )
      ..lineTo(size.width, size.height + offsetY)
      ..lineTo(0, size.height + offsetY)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
