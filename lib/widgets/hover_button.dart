import 'package:flutter/material.dart';

class HoverButton extends StatefulWidget {
  final IconData icon;
  final double size;
  final Color defaultColor;
  final Color hoverColor;
  final Color strokeColor;
  final VoidCallback onPressed;

  const HoverButton({
    Key? key,
    required this.icon,
    this.size = 40.0,
    this.defaultColor = Colors.grey,
    this.hoverColor = Colors.orange,
    this.strokeColor = Colors.white,
    required this.onPressed,
  }) : super(key: key);

  @override
  _HoverButtonState createState() => _HoverButtonState();
}

class _HoverButtonState extends State<HoverButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _isHovered = true;
        });
      },
      onExit: (_) {
        setState(() {
          _isHovered = false;
        });
      },
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: _isHovered ? widget.hoverColor : widget.defaultColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            widget.icon,
            color: widget.strokeColor,
            size: widget.size * 0.6,
          ),
        ),
      ),
    );
  }
}
