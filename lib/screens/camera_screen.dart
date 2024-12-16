import 'dart:io';
import 'package:flutter/material.dart';
// import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:yusha_test/widgets/hover_button.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

final GlobalKey _cameraKey = GlobalKey(); // Key to capture screenshot boundary

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

  Future<void> _setUpCamera() async {
    try {
      // Dispose of the existing CameraController
      if (_cameraController != null) {
        await _cameraController?.dispose();
      }

      // Initialize the CameraController
      _cameraController = CameraController(
        cameras![_isRearCameraSelected ? 0 : 1],
        selectedResolution,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      // Update the maximum zoom level
      maxZoomLevel = await _cameraController!.getMaxZoomLevel();

      setState(() {}); // Update the UI
    } catch (e) {
      print("Error setting up camera: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to initialize camera: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _switchCamera() async {
    try {
      // Toggle the camera index (front/rear)
      setState(() {
        _isRearCameraSelected = !_isRearCameraSelected;
      });

      // Reinitialize the camera
      await _setUpCamera();
    } catch (e) {
      print("Error switching camera: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to switch camera: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );

      // Revert the toggle if an error occurs
      setState(() {
        _isRearCameraSelected = !_isRearCameraSelected;
      });
    }
  }

  void _toggleFlash() {
    setState(() {
      _flashMode =
          _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
    });
    _cameraController?.setFlashMode(_flashMode);
  }

  void _changeResolution(ResolutionPreset newResolution) async {
    try {
      // Attempt to change resolution
      setState(() {
        selectedResolution = newResolution;
      });

      await _setUpCamera(); // Reinitialize camera with the new resolution
    } on CameraException catch (e) {
      print("CameraException while changing resolution: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text("Error changing resolution: ${e.description ?? e.code}"),
          backgroundColor: Colors.redAccent,
        ),
      );

      // Revert to the previous resolution in case of an error
      setState(() {
        selectedResolution = ResolutionPreset.high;
      });
      await _setUpCamera(); // Attempt recovery with default resolution
    } catch (e) {
      print("Unexpected error during resolution change: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("An unexpected error occurred: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );

      // Revert to the default resolution
      setState(() {
        selectedResolution = ResolutionPreset.high;
      });
      await _setUpCamera();
    }
  }

  // void _takePicture() async {
  //   try {
  //     // Check if the camera controller is initialized and not disposed
  //     if (_cameraController == null ||
  //         !_cameraController!.value.isInitialized) {
  //       print("Camera is not available or already disposed.");
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text("Camera is not ready. Please restart.")),
  //       );
  //       return;
  //     }

  //     // Request storage permissions if needed
  //     if (await Permission.storage.request().isGranted) {
  //       // Take a picture and get the file path
  //       final XFile file = await _cameraController!.takePicture();

  //       // Get the external directory for saving the image
  //       final Directory? externalDir = await getExternalStorageDirectory();
  //       if (externalDir == null) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(content: Text("Could not access external storage.")),
  //         );
  //         return;
  //       }

  //       // Create a new file path
  //       final String filePath =
  //           "${externalDir.path}/photo_${DateTime.now().millisecondsSinceEpoch}.jpg";

  //       // Move the image to the external directory
  //       final File newImage = await File(file.path).copy(filePath);

  //       // Update the state and notify the user
  //       if (mounted) {
  //         setState(() {
  //           galleryImage = newImage;
  //         });
  //       }

  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text("Photo saved to: $filePath")),
  //       );
  //     } else {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text("Storage permission denied.")),
  //       );
  //     }
  //   } catch (e) {
  //     print("Error saving image: $e");
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text("Error saving the image: $e")),
  //     );
  //   }
  // }

  // // Take Picture with GIF
  // void _takePicture() async {
  //   try {
  //     // Check if the CameraController is ready
  //     if (_cameraController == null ||
  //         !_cameraController!.value.isInitialized) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text("Camera is not ready.")),
  //       );
  //       return;
  //     }

  //     // Request storage permissions
  //     if (!await Permission.storage.request().isGranted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text("Storage permission denied.")),
  //       );
  //       return;
  //     }

  //     // Take a picture using the camera
  //     final XFile pictureFile = await _cameraController!.takePicture();

  //     // Load the captured image using the image package
  //     img.Image capturedImage =
  //         img.decodeImage(File(pictureFile.path).readAsBytesSync())!;

  //     // Check if a GIF file is selected
  //     if (selectedGif != null && File(selectedGif!.path).existsSync()) {
  //       // Load the GIF file as an image
  //       img.Image gifImage =
  //           img.decodeImage(File(selectedGif!.path).readAsBytesSync())!;

  //       // Resize the GIF to fit the overlay size
  //       gifImage = img.copyResize(gifImage,
  //           width: gifSize.toInt(), height: gifSize.toInt());

  //       // Overlay the GIF image on the captured image at the specified position
  //       img.compositeImage(
  //         capturedImage,
  //         gifImage,
  //         dstX: gifPosition.dx.toInt(), // X position of the GIF
  //         dstY: gifPosition.dy.toInt(), // Y position of the GIF
  //       );
  //     }

  //     // Get external storage directory to save the new image
  //     final Directory? externalDir = await getExternalStorageDirectory();
  //     if (externalDir == null) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text("Could not access external storage.")),
  //       );
  //       return;
  //     }

  //     // Save the final composited image
  //     final String filePath =
  //         "${externalDir.path}/photo_with_gif_${DateTime.now().millisecondsSinceEpoch}.jpg";
  //     final File newImageFile = File(filePath)
  //       ..writeAsBytesSync(img.encodeJpg(capturedImage));

  //     // Update the state with the new image
  //     setState(() {
  //       galleryImage = newImageFile;
  //     });

  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text("Photo with GIF saved to: $filePath")),
  //     );
  //   } catch (e) {
  //     print("Error taking picture with GIF overlay: $e");
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text("Error saving the photo with overlay.")),
  //     );
  //   }
  // }

  void _takePicture() async {
    try {
      // Check for permission to save the file
      if (!await Permission.storage.request().isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Storage permission denied.")),
        );
        return;
      }

      // Find the RenderObject for the boundary key
      RenderRepaintBoundary boundary = _cameraKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary;

      // Convert the boundary into an image
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);

      // Convert the image to bytes
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception("Failed to capture image.");
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // Save the screenshot to external storage
      final Directory? externalDir = await getExternalStorageDirectory();
      if (externalDir == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not access external storage.")),
        );
        return;
      }

      final String filePath =
          "${externalDir.path}/screenshot_${DateTime.now().millisecondsSinceEpoch}.png";

      final File imageFile = File(filePath);
      await imageFile.writeAsBytes(pngBytes);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Screenshot saved to: $filePath")),
      );

      setState(() {
        galleryImage = imageFile;
      });
    } catch (e) {
      print("Error taking screenshot: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error taking screenshot.")),
      );
    }
  }

  void _startVideoRecording() async {
    if (_cameraController == null || isRecording) return;

    await _cameraController!.startVideoRecording();
    setState(() {
      isRecording = true;
    });
  }

  void _stopVideoRecording() async {
    try {
      // Check if the CameraController is valid and initialized
      if (_cameraController == null ||
          !_cameraController!.value.isInitialized) {
        print("Camera is not available or already disposed.");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Camera is not ready. Please restart.")),
        );
        return;
      }

      // Check if recording is ongoing
      if (!isRecording) return;

      // Stop recording the video
      final XFile file = await _cameraController!.stopVideoRecording();

      // Check for storage permission
      if (await Permission.storage.request().isGranted) {
        // Get the external storage directory
        final Directory? externalDir = await getExternalStorageDirectory();
        if (externalDir == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Could not access external storage.")),
          );
          return;
        }

        // Create a new file path with a unique name
        final String newPath =
            "${externalDir.path}/video_${DateTime.now().millisecondsSinceEpoch}.mp4";

        // Move the video to the external directory
        final File newVideo = await File(file.path).copy(newPath);

        // Update the state only if the widget is still mounted
        if (mounted) {
          setState(() {
            galleryImage = newVideo; // Update with the new file path
            isRecording = false;
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Video saved to: $newPath")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Storage permission denied.")),
        );
      }
    } catch (e) {
      print("Error stopping video recording: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving the video: $e")),
      );
    }
  }

  Future<void> _openGallery() async {
    try {
      if (Platform.isIOS) {
        final Uri url = Uri.parse("photos-redirect://");

        if (await canLaunchUrl(url)) {
          await launchUrl(url);
        } else {
          throw 'Could not open Photos app';
        }
      } else if (Platform.isAndroid) {
        const intent = AndroidIntent(
          action: 'action_view',
          type: 'image/*',
          flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
        );
        intent.launch();
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
          leading: (showGifOverlay && !isArMode)
              ? Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: InkWell(
                    onTap: startArMode,
                    borderRadius: BorderRadius.circular(
                        50), // Ensure a circular ripple effect
                    child: Container(
                      width: 48, // Adjust the size of the circular button
                      height: 48, // Adjust the size of the circular button
                      decoration: BoxDecoration(
                        color: Colors.white, // Circle background color
                        shape: BoxShape.circle, // Makes the background circular
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12, // Adds a subtle shadow
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(
                            8.0), // Adds some spacing around the image
                        child: Image.asset(
                          'assets/images/AR_icon.png', // Path to your custom PNG icon
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
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
                      RepaintBoundary(
                        key: _cameraKey, // Global key for screenshot
                        child: Stack(
                          children: [
                            // Camera Preview
                            CameraPreview(_cameraController!),

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
                                        gifPosition.dx +
                                            details.focalPointDelta.dx,
                                        gifPosition.dy +
                                            details.focalPointDelta.dy,
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
                        ),
                      ),

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

                      // // Camera Controls
                      // Positioned(
                      //   top: 40,
                      //   right: 20,
                      //   child: Column(
                      //     children: [
                      //       // // Flash Control
                      //       // IconButton(
                      //       //   icon: Icon(
                      //       //     _flashMode == FlashMode.torch
                      //       //         ? Icons.flash_on
                      //       //         : Icons.flash_off,
                      //       //     color: Colors.white,
                      //       //   ),
                      //       //   onPressed: _toggleFlash,
                      //       // ),
                      //       // // Camera Switch
                      //       // IconButton(
                      //       //   icon: const Icon(Icons.cameraswitch,
                      //       //       color: Colors.white),
                      //       //   onPressed: _switchCamera,
                      //       // ),
                      //       // Resolution Selector
                      //       DropdownButton<ResolutionPreset>(
                      //         dropdownColor: Colors.black,
                      //         value: selectedResolution,
                      //         items: resolutions
                      //             .map((res) => DropdownMenuItem(
                      //                   value: res,
                      //                   child: Text(
                      //                     res
                      //                         .toString()
                      //                         .split('.')
                      //                         .last
                      //                         .toUpperCase(),
                      //                     style: const TextStyle(
                      //                         color: Colors.white),
                      //                   ),
                      //                 ))
                      //             .toList(),
                      //         onChanged: (value) {
                      //           if (value != null) {
                      //             _changeResolution(value);
                      //           }
                      //         },
                      //       ),
                      //     ],
                      //   ),
                      // ),

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
