import 'package:flutter/material.dart';

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
    return Image.asset(
      'assets/images/loksetu_logo.png',
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          'Assets/images/loksetu_logo.png',
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error2, stackTrace2) {
            return Image.network(
              'loksetu_logo.png',
              width: width,
              height: height,
              fit: fit,
              errorBuilder: (context, error3, stackTrace3) {
                return Image.network(
                  'favicon.png',
                  width: width,
                  height: height,
                  fit: fit,
                  errorBuilder: (context, error4, stackTrace4) {
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
              },
            );
          },
        );
      },
    );
  }
}
