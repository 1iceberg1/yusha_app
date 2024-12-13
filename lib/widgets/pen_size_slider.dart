import 'package:flutter/material.dart';

class PenSizeSlider extends StatelessWidget {
  final double strokeWidth;
  final Function(double) onChanged;

  const PenSizeSlider({
    Key? key,
    required this.strokeWidth,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RotatedBox(
      quarterTurns: -1,
      child: Slider(
        value: strokeWidth,
        min: 1.0,
        max: 50.0,
        activeColor: Colors.orange,
        inactiveColor: Colors.grey[300],
        onChanged: (value) => onChanged(value),
      ),
    );
  }
}
