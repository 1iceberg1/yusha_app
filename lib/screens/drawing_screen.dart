import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:yusha_test/widgets/hover_button.dart';
import 'package:yusha_test/widgets/block_picker.dart';
import 'dart:ui' as ui;
import 'dart:collection';
import 'dart:async';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class DrawingScreen extends StatefulWidget {
  @override
  _DrawingScreenState createState() => _DrawingScreenState();
}

enum Tool { Pen, Eraser, Bucket }

enum DrawnPathType { Paint, Fill }

class _DrawingScreenState extends State<DrawingScreen> {
  double _strokeWidth = 10.0;
  double _eraseWidth = 50.0;
  bool _sliderActivated = false;
  Color _selectedColor = Colors.orange;
  Tool _selectedTool = Tool.Pen;

  // Drawing state
  List<DrawnPath> _paths = [];
  List<DrawnPath> _redoPaths = [];
  DrawnPath? _currentPath;

  final GlobalKey _canvasKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    // Add a white background to the canvas
    _paths.add(DrawnPath(
      path: Path()
        ..addRect(
            Rect.fromLTWH(0, 0, 2000, 1000)), // Adjust dimensions as needed
      type: DrawnPathType.Fill,
      color: Colors.white,
      strokeWidth: 0,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        toolbarHeight: 80,
        actions: [
          // Padding(
          //   padding: const EdgeInsets.only(top: 20.0, right: 10),
          //   child: HoverButton(
          //     icon: Icons.undo,
          //     onPressed: _undo,
          //   ),
          // ),
          // Padding(
          //   padding: const EdgeInsets.only(top: 20.0, right: 10),
          //   child: HoverButton(
          //     icon: Icons.redo,
          //     onPressed: _redo,
          //   ),
          // ),
          Padding(
            padding: const EdgeInsets.only(top: 20.0, right: 10),
            child: HoverButton(
              icon: Icons.delete,
              onPressed: _clearCanvas,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 20.0, right: 10),
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Exit",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () async {
          if (_sliderActivated) {
            setState(() {
              _sliderActivated = false; // Deactivate the slider
            });
          }
        },
        onTapDown: (details) async {
          if (_selectedTool == Tool.Bucket && !_sliderActivated) {
            final stopwatch = Stopwatch()..start();
            await _bucketFill(details.localPosition); // Fill the canvas
            stopwatch.stop();

            print(
                'Bucket fill function executed in ${stopwatch.elapsedMilliseconds} ms');
          }
        },
        child: Stack(
          children: [
            // Drawing Canvas
            RepaintBoundary(
              key: _canvasKey,
              child: GestureDetector(
                onPanStart: (details) {
                  if (!_sliderActivated && _selectedTool == Tool.Pen) {
                    _startDrawing(details);
                  } else if (!_sliderActivated &&
                      _selectedTool == Tool.Eraser) {
                    _erase(details);
                  }
                },
                onPanUpdate: (details) {
                  if (!_sliderActivated && _selectedTool == Tool.Pen) {
                    _updateDrawing(details);
                  } else if (!_sliderActivated &&
                      _selectedTool == Tool.Eraser) {
                    _updateEraser(details);
                  }
                },
                onPanEnd: (details) {
                  if (!_sliderActivated && _selectedTool == Tool.Pen) {
                    _endDrawing(details);
                  } else if (!_sliderActivated &&
                      _selectedTool == Tool.Eraser) {
                    _endEraser(details);
                  }
                },
                child: CustomPaint(
                  painter: DrawingPainter(
                    paths: _paths,
                    currentPath: _currentPath,
                  ),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
            // Slider

            // Stroke Size Indicator
            if (_sliderActivated)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.5), // Dim the background
                  child: Center(
                    child: Container(
                      width: _selectedTool == Tool.Pen
                          ? _strokeWidth
                          : _eraseWidth,
                      height: _selectedTool == Tool.Pen
                          ? _strokeWidth
                          : _eraseWidth,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.orange, width: 2),
                        shape: BoxShape.circle,
                        color: Colors.white, // Background of the circle
                      ),
                    ),
                  ),
                ),
              ),
            _buildSlider(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomToolbar(),
    );
  }

  Widget _buildSlider() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300), // Animation duration
      curve: Curves.easeInOut, // Animation curve
      left: _sliderActivated ? 16 : -16, // Conditional left padding
      top: MediaQuery.of(context).size.height / 2 - 150 - 100, // Conditional top alignment
      child: GestureDetector(
        onTap: () => setState(() {
          if (_selectedTool != Tool.Bucket) _sliderActivated = true;
        }),
        child: Stack(
          alignment: Alignment.center,
          children: [
            RotatedBox(
              quarterTurns: -1,
              child: SizedBox(
                width: 300, // This controls the vertical length of the slider
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 20, // Slightly wider track
                    thumbShape: CustomRoundedRectThumb(
                      thumbWidth: 16, // Width of the thumb
                      thumbHeight: 32, // Height of the thumb
                      thumbRadius: 4, // Corner radius of the thumb
                    ),
                    activeTrackColor: Colors.orange,
                    inactiveTrackColor: Colors.grey[300],
                  ),
                  child: Slider(
                    value:
                        _selectedTool == Tool.Pen ? _strokeWidth : _eraseWidth,
                    min: _selectedTool == Tool.Pen ? 3.0 : 5.0,
                    max: _selectedTool == Tool.Pen ? 30.0 : 50.0,
                    onChanged: _sliderActivated
                        ? (value) {
                            setState(() {
                              if (_selectedTool == Tool.Pen)
                                _strokeWidth = value;
                              if (_selectedTool == Tool.Eraser)
                                _eraseWidth = value;
                            });
                          }
                        : null,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Padding(
            padding:
                const EdgeInsets.only(left: 40.0), // Left padding for alignment
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildToolButton(
                    Icons.format_color_fill, "Bucket", Tool.Bucket),
                SizedBox(width: 10), // Space between buttons
                _buildToolButton(
                    FontAwesomeIcons.eraser, "Eraser", Tool.Eraser),
                SizedBox(width: 10), // Space between buttons
                _buildToolButton(Icons.edit, "Pen", Tool.Pen),
              ],
            ),
          ),
          Spacer(), // Push the color picker to the far right
          Padding(
            padding: const EdgeInsets.only(right: 40.0),
            child: GestureDetector(
              onTap: () => _showColorPicker(context),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _selectedColor,
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton(IconData icon, String label, Tool tool) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon,
              size: 60,
              color: _selectedTool == tool ? Colors.orange : Colors.grey),
          onPressed: () {
            setState(() {
              _selectedTool = tool;
            });
          },
        ),
      ],
    );
  }

  void _showColorPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: BlockPicker(
            pickerColor: _selectedColor,
            onColorChanged: (color) {
              setState(() {
                _selectedColor = color;
              });
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  Future<void> _bucketFill(Offset position) async {
    RenderRepaintBoundary boundary =
        _canvasKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final boundaryWatch = Stopwatch()..start();
    ui.Image image = await boundary.toImage();
    boundaryWatch.stop();
    print(
        "Boundary toImage function executed in ${boundaryWatch.elapsedMilliseconds} ms");

    final byteConvertWatch = Stopwatch()..start();
    ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    byteConvertWatch.stop();
    print(
        "toByteData function executed in ${byteConvertWatch.elapsedMilliseconds} ms");

    if (byteData == null) return;

    Uint8List pixels = byteData.buffer.asUint8List();
    int width = image.width;
    int height = image.height;

    int startX = position.dx.toInt();
    int startY = position.dy.toInt();

    if (startX < 0 || startX >= width || startY < 0 || startY >= height) return;

    int startIndex = (startY * width + startX) * 4;
    int targetR = pixels[startIndex];
    int targetG = pixels[startIndex + 1];
    int targetB = pixels[startIndex + 2];
    int targetA = pixels[startIndex + 3];

    if (targetR == _selectedColor.red &&
        targetG == _selectedColor.green &&
        targetB == _selectedColor.blue &&
        targetA == _selectedColor.alpha) return;

    Queue<Map<String, int>> queue = Queue<Map<String, int>>();
    queue.add({'x': startX, 'y': startY});

    int filledArea = 0;

    List<int> dx = [-1, 0, 1, -1, 1, -1, 0, 1];
    List<int> dy = [1, 1, 1, 0, 0, -1, -1, -1];

    Set<String> visited = {}; // To track visited pixels

    final bfsWatch = Stopwatch()..start();

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      int currentX = current['x']!;
      int currentY = current['y']!;

      // Create a unique key for the current pixel
      String currentKey = '$currentX,$currentY';

      if (visited.contains(currentKey)) {
        continue; // Skip if the pixel is already processed
      }

      visited.add(currentKey); // Mark the pixel as visited

      int currentIndex = (currentY * width + currentX) * 4;
      int threshold = 5;

      // Fill the pixel with the selected color
      pixels[currentIndex] = _selectedColor.red;
      pixels[currentIndex + 1] = _selectedColor.green;
      pixels[currentIndex + 2] = _selectedColor.blue;
      pixels[currentIndex + 3] = _selectedColor.alpha;
      filledArea++;

      // Explore neighbors
      for (int i = 0; i < 8; i++) {
        int nx = currentX + dx[i];
        int ny = currentY + dy[i];

        // Check bounds
        if (nx < 0 || nx >= width || ny < 0 || ny >= height) continue;

        String neighborKey = '$nx,$ny';

        if (visited.contains(neighborKey)) {
          continue; // Skip already visited neighbors
        }

        int nIndex = (ny * width + nx) * 4;

        if ((pixels[nIndex] - targetR).abs() < threshold &&
            (pixels[nIndex + 1] - targetG).abs() < threshold &&
            (pixels[nIndex + 2] - targetB).abs() < threshold &&
            (pixels[nIndex + 3] - targetA).abs() < threshold) {
          queue.add({'x': nx, 'y': ny});
        }
      }
    }
    bfsWatch.stop();
    print("BFS executed in ${bfsWatch.elapsedMilliseconds} ms");

    print("Filled Area");
    print(filledArea);

    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromPixels(
      pixels,
      width,
      height,
      ui.PixelFormat.rgba8888,
      (img) {
        completer.complete(img);
      },
    );
    final completerWatch = Stopwatch()..start();
    final img = await completer.future;
    completerWatch.stop();
    print(
        "Completer function executed in ${completerWatch.elapsedMilliseconds} ms");

    print("IMAGE WIDTH & HEIGHT");
    print(img.width);
    print(img.height);

    setState(() {
      _paths.clear();
      _paths.add(DrawnPath(
        path: Path()
          ..addRect(Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble())),
        type: DrawnPathType.Fill,
        color: _selectedColor,
        image: img, // Pass the updated image
      ));
      // _redoPaths.clear();
    });
  }

  void _startDrawing(DragStartDetails details) {
    setState(() {
      _currentPath = DrawnPath(
        path: Path()
          ..moveTo(details.localPosition.dx, details.localPosition.dy),
        type: DrawnPathType.Paint,
        color: _selectedColor,
        strokeWidth: _strokeWidth,
      );
      _redoPaths.clear();
    });
  }

  void _updateDrawing(DragUpdateDetails details) {
    setState(() {
      _currentPath?.path
          .lineTo(details.localPosition.dx, details.localPosition.dy);
    });
  }

  void _endDrawing(DragEndDetails details) {
    if (_currentPath != null) {
      setState(() {
        _paths.add(_currentPath!);
        _currentPath = null;
      });
    }
  }

  // void _erase(DragStartDetails details) {
  //   setState(() {
  //     _paths.removeWhere(
  //         (path) => path.path.getBounds().contains(details.localPosition));
  //   });
  // }

  void _erase(DragStartDetails details) {
    setState(() {
      _currentPath = DrawnPath(
        path: Path()
          ..moveTo(details.localPosition.dx, details.localPosition.dy),
        type: DrawnPathType.Paint,
        color: const Color.fromARGB(255, 255, 255, 255), // Transparent color
        strokeWidth: _eraseWidth,
      );
    });
  }

  void _updateEraser(DragUpdateDetails details) {
    setState(() {
      _currentPath?.path
          .lineTo(details.localPosition.dx, details.localPosition.dy);
    });
  }

  void _endEraser(DragEndDetails details) {
    if (_currentPath != null) {
      setState(() {
        _paths.add(_currentPath!);
        _currentPath = null;
      });
    }
  }

  void _undo() {
    if (_paths.isNotEmpty) {
      setState(() {
        _redoPaths.add(_paths.removeLast());
      });
    }
  }

  void _redo() {
    if (_redoPaths.isNotEmpty) {
      setState(() {
        _paths.add(_redoPaths.removeLast());
      });
    }
  }

  void _clearCanvas() {
    setState(() {
      _paths.clear();
      _redoPaths.clear();
      _paths.add(DrawnPath(
        path: Path()
          ..addRect(
              Rect.fromLTWH(0, 0, 2000, 1000)), // Adjust dimensions as needed
        type: DrawnPathType.Fill,
        color: Colors.white,
        strokeWidth: 0,
      ));
    });
  }
}

class DrawingPainter extends CustomPainter {
  final List<DrawnPath> paths;
  final DrawnPath? currentPath;

  DrawingPainter({
    required this.paths,
    required this.currentPath,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var path in paths) {
      if (path.image != null) {
        // Draw the updated image if it exists
        // canvas.drawImage(path.image!, Offset.zero, Paint());
        canvas.drawImageRect(
          path.image!,
          Rect.fromLTWH(0, 0, path.image!.width.toDouble(),
              path.image!.height.toDouble()), // Source
          Rect.fromLTWH(0, 0, size.width, size.height), // Destination
          Paint(),
        );
      } else {
        final paint = Paint()
          ..color = path.color
          ..strokeWidth = path.strokeWidth
          ..style = path.type == DrawnPathType.Paint
              ? PaintingStyle.stroke
              : PaintingStyle.fill
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.miter
          ..isAntiAlias = false;
        canvas.drawPath(path.path, paint);
      }
    }

    if (currentPath != null) {
      if (currentPath?.type == PaintingStyle.fill &&
          currentPath?.image != null) {
        print("Current Path");
        print(currentPath?.image?.width);
        print(currentPath?.image?.height);

        canvas.drawImage((currentPath?.image)!, Offset.zero, Paint());
      } else {
        final paint = Paint()
          ..color = currentPath!.color
          ..strokeWidth = currentPath!.strokeWidth
          ..style = currentPath!.type == DrawnPathType.Paint
              ? PaintingStyle.stroke
              : PaintingStyle.fill
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.miter
          ..isAntiAlias = false;
        canvas.drawPath(currentPath!.path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class DrawnPath {
  Path path;
  DrawnPathType type;
  Color color;
  double strokeWidth;
  ui.Image? image; // New field for the image

  DrawnPath({
    required this.path,
    required this.type,
    required this.color,
    this.strokeWidth = 0,
    this.image,
  });
}

class CustomRoundedRectThumb extends SliderComponentShape {
  final double thumbWidth;
  final double thumbHeight;
  final double thumbRadius;

  CustomRoundedRectThumb({
    required this.thumbWidth,
    required this.thumbHeight,
    required this.thumbRadius,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size(thumbWidth, thumbHeight);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center,
        width: thumbWidth,
        height: thumbHeight,
      ),
      Radius.circular(thumbRadius),
    );

    context.canvas.drawRRect(rect, paint);
  }
}
