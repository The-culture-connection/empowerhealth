import 'package:flutter/material.dart';

class DSBackground extends StatelessWidget {
  final String imagePath;
  final Widget child;
  final Color? overlayColor;

  const DSBackground({
    super.key,
    required this.imagePath,
    required this.child,
    this.overlayColor,
  });

  @override
  Widget build(BuildContext context) {
    final overlay = overlayColor ??
        (Theme.of(context).brightness == Brightness.dark
            ? Colors.black.withOpacity(0.6)
            : Colors.white.withOpacity(0.72));

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(imagePath),
              fit: BoxFit.cover,
            ),
          ),
        ),
        ColoredBox(color: overlay),
        child,
      ],
    );
  }
}
