import 'package:flutter/material.dart';

class UnilaLogoWidget extends StatelessWidget {
  final double size;
  final bool isWhite;

  const UnilaLogoWidget({
    super.key,
    this.size = 100,
    this.isWhite = false,
  });

  @override
  Widget build(BuildContext context) {
    return Image.network(
      'https://upload.wikimedia.org/wikipedia/commons/8/87/Logo_UnivLampung.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback: Custom Vector Shield Unila Drawing
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isWhite ? Colors.white : const Color(0xFF1976D2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.school,
                color: isWhite ? const Color(0xFF1976D2) : Colors.yellow[700],
                size: size * 0.45,
              ),
              const SizedBox(height: 2),
              Text(
                'UNILA',
                style: TextStyle(
                  color: isWhite ? const Color(0xFF1976D2) : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: size * 0.16,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return SizedBox(
          width: size,
          height: size,
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
    );
  }
}
