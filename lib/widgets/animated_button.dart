import 'package:flutter/material.dart';

class AnimatedButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  final double height;
  final EdgeInsets padding;

  const AnimatedButton({
    Key? key,
    required this.onPressed,
    required this.child,
    this.height = 52,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: padding,
        ),
        child: AnimatedScale(
          scale: 1.0,
          duration: const Duration(milliseconds: 200),
          child: child,
        ),
      ),
    );
  }
}
