import 'package:flutter/material.dart';

class Toolbar extends StatelessWidget {
  final Function onBucketTap;
  final Function onBrushTap;
  final Function onImageTap;
  final Function onCameraTap;

  const Toolbar({
    Key? key,
    required this.onBucketTap,
    required this.onBrushTap,
    required this.onImageTap,
    required this.onCameraTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: const Icon(Icons.format_paint, color: Colors.grey),
            onPressed: () => onBucketTap(),
          ),
          IconButton(
            icon: const Icon(Icons.brush, color: Colors.grey),
            onPressed: () => onBrushTap(),
          ),
          IconButton(
            icon: const Icon(Icons.image, color: Colors.grey),
            onPressed: () => onImageTap(),
          ),
          IconButton(
            icon: const Icon(Icons.camera_alt, color: Colors.grey),
            onPressed: () => onCameraTap(),
          ),
        ],
      ),
    );
  }
}
