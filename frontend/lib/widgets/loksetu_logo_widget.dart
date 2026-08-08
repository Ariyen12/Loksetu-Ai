import 'package:flutter/material.dart';
import 'loksetu_logo_data.dart';

class LokSetuLogoWidget extends StatelessWidget {
  final double width;
  final double height;
  final BoxFit fit;

  const LokSetuLogoWidget({
    super.key,
    this.width = 120,
    this.height = 120,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return Image.memory(
      kLokSetuLogoBytes,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: Icon(
            Icons.auto_awesome,
            size: width * 0.5,
            color: const Color(0xFF2563EB),
          ),
        );
      },
    );
  }
}
