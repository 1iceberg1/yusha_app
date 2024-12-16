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

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  final ImagePicker _picker = ImagePicker();
  File? selectedGif;
  File? galleryImage;
  bool showGifOverlay = false;
  bool isArMode = false;
  CameraController? _cameraController;
  List<CameraDescription>? cameras;

  Offset gifPosition = const Offset(100, 200); // Initial position of the GIF
  double gifSize = 150.0; // Initial size of the GIF
  double zoomLevel = 1.0; // Camera zoom level
  double maxZoomLevel = 1.0;
  bool isRecording = false;
  bool isImageMode = true; // Toggle between Image and Video modes
  bool _isRearCameraSelected = true;
  FlashMode _flashMode = FlashMode.off;

  List<ResolutionPreset> resolutions = ResolutionPreset.values;
  ResolutionPreset selectedResolution = ResolutionPreset.ultraHigh;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    try {
      cameras = await availableCameras();
      _setUpCamera();
    } catch (e) {
      print("Error initializing camera: $e");
    }
  }

  void _setUpCamera() async {
    if (_cameraController != null) await _cameraController?.dispose();

    _cameraController = CameraController(
      cameras![_isRearCameraSelected ? 0 : 1],
      selectedResolution,
      enableAudio: false,
    );

    await _cameraController!.initialize();
    maxZoomLevel = await _cameraController!.getMaxZoomLevel();
    setState(() {});
  }

  void _switchCamera() {
    setState(() {
      _isRearCameraSelected = !_isRearCameraSelected;
    });
    _setUpCamera();
  }

  void _toggleFlash() {
    setState(() {
      _flashMode =
          _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
    });
    _cameraController?.setFlashMode(_flashMode);
  }

  void _changeResolution(ResolutionPreset newResolution) {
    setState(() {
      selectedResolution = newResolution;
    });
    _setUpCamera();
  }

  void _takePicture() async {
    final XFile file = await _cameraController!.takePicture();
    setState(() {
      galleryImage = File(file.path);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Photo saved: ${file.path}")),
    );
  }

  void _startVideoRecording() async {
    if (_cameraController == null || isRecording) return;

    await _cameraController!.startVideoRecording();
    setState(() {
      isRecording = true;
    });
  }

  void _stopVideoRecording() async {
    if (!isRecording) return;

    final XFile file = await _cameraController!.stopVideoRecording();
    setState(() {
      galleryImage = File(file.path);
      isRecording = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Video saved: ${file.path}")),
    );
  }

  Future<void> _openGallery() async {
    try {
      final XFile? file =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (file != null) {
        setState(() {
          galleryImage = File(file.path); // Update the gallery image
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Image selected: ${file.path}")),
        );
      }
    } catch (e) {
      print("Error opening gallery: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error opening gallery.")),
      );
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

  void onCameraTap(TapUpDetails details) async {
    final position = details.localPosition;
    final size = MediaQuery.of(context).size;
    final x = position.dx / size.width;
    final y = position.dy / size.height;

    try {
      await _cameraController!.setFocusPoint(Offset(x, y));
      await _cameraController!.setExposurePoint(Offset(x, y));
    } catch (e) {
      print("Error focusing camera: $e");
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
                      // Camera Preview
                      CameraPreview(_cameraController!),

                      // // Controls for camera functionalities (zoom and flash)
                      // Positioned(
                      //   top: 20,
                      //   right: 20,
                      //   child: Column(
                      //     children: [
                      //       // Zoom In Button
                      //       IconButton(
                      //         icon: const Icon(Icons.zoom_in,
                      //             color: Colors.white, size: 28),
                      //         onPressed: () {
                      //           setState(() {
                      //             zoomLevel = (zoomLevel + 0.5).clamp(1.0, maxZoomLevel);
                      //             _cameraController!.setZoomLevel(zoomLevel);
                      //           });
                      //         },
                      //       ),
                      //       // Zoom Out Button
                      //       IconButton(
                      //         icon: const Icon(Icons.zoom_out,
                      //             color: Colors.white, size: 28),
                      //         onPressed: () {
                      //           setState(() {
                      //             zoomLevel = (zoomLevel - 0.5).clamp(1.0, 8.0);
                      //             _cameraController!.setZoomLevel(zoomLevel);
                      //           });
                      //         },
                      //       ),
                      //       // // Flash Toggle
                      //       // IconButton(
                      //       //   icon: Icon(
                      //       //     _cameraController!.value.flashMode ==
                      //       //             FlashMode.torch
                      //       //         ? Icons.flash_on
                      //       //         : Icons.flash_off,
                      //       //     color: Colors.white,
                      //       //     size: 28,
                      //       //   ),
                      //       //   onPressed: () {
                      //       //     setState(() {
                      //       //       _cameraController!.setFlashMode(
                      //       //         _cameraController!.value.flashMode ==
                      //       //                 FlashMode.torch
                      //       //             ? FlashMode.off
                      //       //             : FlashMode.torch,
                      //       //       );
                      //       //     });
                      //       //   },
                      //       // ),
                      //     ],
                      //   ),
                      // ),

                      // Zoom Slider
                      Positioned(
                        right: 20,
                        top: MediaQuery.of(context).size.height * 0.2,
                        bottom: MediaQuery.of(context).size.height * 0.2,
                        child: RotatedBox(
                          quarterTurns: -1,
                          child: Slider(
                            value: zoomLevel,
                            min: 1.0,
                            max: maxZoomLevel,
                            onChanged: (value) {
                              setState(() {
                                zoomLevel = value;
                                _cameraController!.setZoomLevel(value);
                              });
                            },
                          ),
                        ),
                      ),

                      // Camera Controls
                      Positioned(
                        top: 40,
                        right: 20,
                        child: Column(
                          children: [
                            // // Flash Control
                            // IconButton(
                            //   icon: Icon(
                            //     _flashMode == FlashMode.torch
                            //         ? Icons.flash_on
                            //         : Icons.flash_off,
                            //     color: Colors.white,
                            //   ),
                            //   onPressed: _toggleFlash,
                            // ),
                            // // Camera Switch
                            // IconButton(
                            //   icon: const Icon(Icons.cameraswitch,
                            //       color: Colors.white),
                            //   onPressed: _switchCamera,
                            // ),
                            // Resolution Selector
                            DropdownButton<ResolutionPreset>(
                              dropdownColor: Colors.black,
                              value: selectedResolution,
                              items: resolutions
                                  .map((res) => DropdownMenuItem(
                                        value: res,
                                        child: Text(
                                          res
                                              .toString()
                                              .split('.')
                                              .last
                                              .toUpperCase(),
                                          style: const TextStyle(
                                              color: Colors.white),
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  _changeResolution(value);
                                }
                              },
                            ),
                          ],
                        ),
                      ),

                      // Bottom Controls
                      Positioned(
                        bottom: 30,
                        left: 20,
                        right: 20,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Gallery Button
                            GestureDetector(
                              onTap: _openGallery,
                              child: CircleAvatar(
                                backgroundImage: galleryImage != null
                                    ? FileImage(galleryImage!)
                                    : null,
                                backgroundColor: Colors.grey,
                                radius: 30,
                                child: galleryImage == null
                                    ? const Icon(Icons.image,
                                        color: Colors.white)
                                    : null,
                              ),
                            ),
                            // Capture Button
                            GestureDetector(
                              onTap: isImageMode
                                  ? _takePicture
                                  : (isRecording
                                      ? _stopVideoRecording
                                      : _startVideoRecording),
                              child: CircleAvatar(
                                radius: 35,
                                backgroundColor:
                                    isRecording ? Colors.red : Colors.white,
                                child: Icon(
                                  isImageMode
                                      ? Icons.camera_alt
                                      : (isRecording
                                          ? Icons.stop
                                          : Icons.videocam),
                                  color: Colors.black,
                                  size: 30,
                                ),
                              ),
                            ),
                            // Camera Switch
                            GestureDetector(
                              onTap: _switchCamera,
                              child: const CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.grey,
                                child: Icon(Icons.cameraswitch,
                                    color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // GIF Overlay: Allows Dragging and Resizing
                      if (selectedGif != null)
                        Positioned(
                          left: gifPosition.dx,
                          top: gifPosition.dy,
                          child: GestureDetector(
                            onScaleUpdate: (details) {
                              setState(() {
                                // Update position (pan) using the focal point
                                gifPosition = Offset(
                                  gifPosition.dx + details.focalPointDelta.dx,
                                  gifPosition.dy + details.focalPointDelta.dy,
                                );

                                // Update size (scale) using the scale factor
                                gifSize = (gifSize * details.scale)
                                    .clamp(50.0, 300.0);
                              });
                            },
                            child: Image.file(
                              selectedGif!,
                              width: gifSize,
                              height: gifSize,
                              fit: BoxFit.contain,
                            ),
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
