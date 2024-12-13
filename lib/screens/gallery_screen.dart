import 'package:flutter/material.dart';
import 'package:yusha_test/widgets/hover_button.dart';
import 'package:carousel_slider/carousel_slider.dart';

final List<String> initImgList = [
  'https://images.unsplash.com/photo-1520342868574-5fa3804e551c?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=6ff92caffcdd63681a35134a6770ed3b&auto=format&fit=crop&w=1951&q=80',
  'https://images.unsplash.com/photo-1522205408450-add114ad53fe?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=368f45b0888aeb0b7b08e3a1084d3ede&auto=format&fit=crop&w=1950&q=80',
  'https://images.unsplash.com/photo-1519125323398-675f0ddb6308?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=94a1e718d89ca60a6337a6008341ca50&auto=format&fit=crop&w=1950&q=80',
  'https://images.unsplash.com/photo-1523205771623-e0faa4d2813d?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=89719a0d55dd05e2deae4120227e6efc&auto=format&fit=crop&w=1953&q=80',
  'https://images.unsplash.com/photo-1508704019882-f9cf40e475b4?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=8c6e5e3aba713b17aa1fe71ab4f0ae5b&auto=format&fit=crop&w=1352&q=80',
  'https://images.unsplash.com/photo-1519985176271-adb1088fa94c?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=a0c8d632e977f94e5d312d9893258f59&auto=format&fit=crop&w=1355&q=80',
];

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({Key? key}) : super(key: key);

  @override
  _GalleryScreenState createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  int currentStep = 0; // Current page index
  int imagesPerStep = 5;
  String? selectedImage; // Image selected from carousel
  List<String> imgList = List.from(initImgList)
    ..addAll(List.filled((5 - initImgList.length % 5) % 5, ''));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.grey[800],
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: HoverButton(
              icon: Icons.undo,
              defaultColor: Colors.white,
              strokeColor: Colors.grey,
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double maxWidth = constraints.maxWidth;
          double maxHeight = constraints.maxHeight;

          return Column(
            children: [
              // Top gray container with curved bottom
              Expanded(
                flex: 1,
                child: Stack(
                  children: [
                    Container(
                      color: Colors.grey[800],
                    ),
                    Positioned(
                      bottom: 0, // Position the curve at the bottom
                      child: CustomPaint(
                        size: Size(MediaQuery.of(context).size.width,
                            80), // Set curve height
                        painter: CurvePainter(),
                      ),
                    ),
                    Positioned(
                      bottom: 8, // Increase this value to move it down
                      left: MediaQuery.of(context).size.width / 2 -
                          32, // Center horizontally
                      child: CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.image_outlined,
                            color: Colors.orange,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Preview and controls section
              Expanded(
                flex: 3,
                child: Container(
                  clipBehavior: Clip.hardEdge, // Apply clipping
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: 40),
                      // Motion preview
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                        child: Container(
                          height: MediaQuery.of(context).size.height / 4, // Adjusted height for better proportions
                          width: MediaQuery.of(context).size.width * 0.9, // Fit most of the screen width
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: selectedImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(
                                    selectedImage!,
                                    fit: BoxFit.cover, // Ensure the image covers the entire area
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    "Motion preview",
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      const Spacer(),
                      // Carousel with tappable images
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight:
                              150, // Set a maximum height to avoid overflow
                        ),
                        child: CarouselSlider.builder(
                          options: CarouselOptions(
                            aspectRatio: 3.0,
                            enableInfiniteScroll: false,
                            enlargeCenterPage: false,
                            viewportFraction: 1,
                            onPageChanged: (index, reason) {
                              setState(() {
                                currentStep = index;
                              });
                            },
                            padEnds: false,
                          ),
                          itemCount: (imgList.length / imagesPerStep).ceil(),
                          itemBuilder: (context, index, realIdx) {
                            List<int> indexes = [];
                            for (int i = 0; i < imagesPerStep; i++)
                              indexes.add(currentStep * imagesPerStep + i);
                            return Row(
                              children: indexes.map((idx) {
                                if (idx >= imgList.length) return SizedBox();
                                return Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        if (imgList[idx] != '')
                                          selectedImage = imgList[idx];
                                      });
                                    },
                                    child: (imgList[idx] != '')
                                        ? Container(
                                            margin: EdgeInsets.symmetric(
                                                horizontal: 10),
                                            child: Image.network(
                                              imgList[idx],
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : SizedBox(width: 16, height: 16),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ),

                      // Dots indicator (pagination)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                            (imgList.length / imagesPerStep).ceil(), (index) {
                          return GestureDetector(
                            child: Container(
                              margin: EdgeInsets.symmetric(horizontal: 4),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: index == currentStep
                                    ? Colors.orange
                                    : Colors.grey[400],
                                shape: BoxShape.circle,
                              ),
                            ),
                          );
                        }),
                      ),
                      const Spacer(),
                      // Button row
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Left button
                            SizedBox(
                              width: MediaQuery.of(context).size.width / 2.5, // Half width for the button
                              child: ElevatedButton(
                                onPressed: () {
                                  // Add functionality
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.pink[100],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 16), // Adjust padding
                                ),
                                child: Text(
                                  "Load",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            // Spacing between buttons
                            const SizedBox(width: 16),
                            // Right button
                            SizedBox(
                              width: MediaQuery.of(context).size.width / 2.5, // Half width for the button
                              child: ElevatedButton(
                                onPressed: () {
                                  // Add functionality
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 16), // Adjust padding
                                ),
                                child: Text(
                                  "Complete",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
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
      // Draw the first quarter-circle (1/4 circle) with a radius of 10

      ..arcTo(
        Rect.fromCircle(center: Offset(rad, size.height - rad), radius: rad),
        PI, // Start angle: π (left side)
        1.57, // Sweep angle: π/2 (90 degrees)
        false, // Force move-to-line connection
      )
      // Draw a straight line to the center of the canvas
      ..lineTo(size.width / 2 - rad * 2, size.height - rad * 2)
      ..arcTo(
        Rect.fromCircle(
            center: Offset(size.width / 2 - 2.25 * rad,
                size.height - 2 * rad + 0.25 * rad),
            radius: rad / 4),
        -1.57, // Start angle: π (left side of half-circle)
        PI / 2, // Sweep angle: -π (180 degrees inward)
        false,
      )
      // Draw a half-circle (centered inward curve) with a radius of rad * 2
      ..arcTo(
        Rect.fromCircle(
            center: Offset(size.width / 2, size.height - rad * 2),
            radius: rad * 2),
        PI * 0.9, // Start angle: π (left side of half-circle)
        -PI * 0.8, // Sweep angle: -π (180 degrees inward)
        false,
      )
      ..arcTo(
        Rect.fromCircle(
            center: Offset(size.width / 2 + 2.25 * rad,
                size.height - 2 * rad + 0.25 * rad),
            radius: rad / 4),
        PI, // Start angle: π (left side of half-circle)
        PI / 2, // Sweep angle: -π (180 degrees inward)
        false,
      )
      // Draw a straight line to the top-right corner (ending the arc)
      ..lineTo(size.width - rad, size.height - rad * 2)
      // Draw the last quarter-circle (1/4 circle) with a radius of rad
      ..arcTo(
        Rect.fromCircle(
            center: Offset(size.width - rad, size.height - rad), radius: rad),
        -1.57, // Start angle: π/2 (bottom)
        1.57, // Sweep angle: π/2 (90 degrees)
        false,
      )
      ..lineTo(size.width, size.height + offsetY) // Close the path
      ..lineTo(0, size.height + offsetY) // Top-left corner
      ..close(); // Connect back to the start to complete the shape

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
