import 'package:flutter/material.dart';

class BlockPicker extends StatefulWidget {
  final Color pickerColor;
  final ValueChanged<Color> onColorChanged;

  const BlockPicker({
    required this.pickerColor,
    required this.onColorChanged,
    Key? key,
  }) : super(key: key);

  @override
  _BlockPickerState createState() => _BlockPickerState();
}

class _BlockPickerState extends State<BlockPicker> {
  late double hue;
  late double brightness;
  late double saturation;

  @override
  void initState() {
    super.initState();
    final hsvColor = HSVColor.fromColor(widget.pickerColor);
    hue = hsvColor.hue;
    saturation = hsvColor.saturation;
    brightness = hsvColor.value;
  }

  void _updateColor() {
    final newColor =
        HSVColor.fromAHSV(1, hue, saturation, brightness).toColor();
    widget.onColorChanged(newColor);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Color Selection Rectangle
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: GestureDetector(
            onPanUpdate: (details) {
              final renderBox = context.findRenderObject() as RenderBox;
              final localOffset =
                  renderBox.globalToLocal(details.globalPosition);
              setState(() {
                saturation =
                    (localOffset.dx / renderBox.size.width).clamp(0.0, 1.0);
                brightness = (1 - localOffset.dy / renderBox.size.height)
                    .clamp(0.0, 1.0);
                _updateColor();
              });
            },
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black,
                    HSVColor.fromAHSV(1, hue, 1, 1).toColor(),
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white,
                          Colors.transparent,
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment(
                      saturation * 2 - 1,
                      (1 - brightness) * 2 - 1,
                    ),
                    child: Icon(Icons.circle, size: 20, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Hue Slider (Rainbow Gradient)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Row(
            children: [
              const Icon(Icons.palette, color: Colors.grey),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Container(
                        height: 12,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: const LinearGradient(
                            colors: [
                              Colors.red,
                              Colors.orange,
                              Colors.yellow,
                              Colors.green,
                              Colors.cyan,
                              Colors.blue,
                              Colors.purple,
                            ],
                            stops: [
                              0.0,
                              2 / 13,
                              4 / 15,
                              3 / 7,
                              4 / 6,
                              5 / 6,
                              1.0
                            ],
                          ),
                        ),
                      ),
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 12,
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 10),
                        thumbColor:
                            HSVColor.fromAHSV(1, hue, saturation, 1).toColor(),
                        overlayShape:
                            const RoundSliderOverlayShape(overlayRadius: 20),
                        activeTrackColor: Colors.transparent,
                        inactiveTrackColor: Colors.transparent,
                      ),
                      child: Slider(
                        value: hue.clamp(0.0, 275.0), // Clamp the value
                        min: 0,
                        max: 275,
                        onChanged: (value) {
                          setState(() {
                            hue = value.clamp(0.0, 275.0); // Clamp the value
                            saturation =
                                1.0; // Ensure full saturation on hue changes
                            _updateColor();
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Brightness Slider (Black to Selected Hue)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Row(
            children: [
              const Icon(Icons.wb_sunny, color: Colors.grey),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Container(
                        height: 12,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: LinearGradient(
                            colors: [Colors.black, Colors.white],
                            stops: [0.0, 1.0],
                          ),
                        ),
                      ),
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 12,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 10,
                        ),
                        thumbColor: Colors.white, // Constant white color
                        overlayShape:
                            const RoundSliderOverlayShape(overlayRadius: 20),
                        activeTrackColor: Colors.transparent,
                        inactiveTrackColor: Colors.transparent,
                      ),
                      child: Slider(
                        value: brightness,
                        min: 0,
                        max: 1,
                        onChanged: (value) {
                          setState(() {
                            brightness = value;
                            _updateColor();
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
