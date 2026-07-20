import 'package:flutter/material.dart';

class ErrorState extends StatelessWidget {
  final Color accentColor;
  final String message;
  final VoidCallback onRetry;

  const ErrorState({
    super.key,
    required this.accentColor,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    const Color nearBlack = Color(0xFF0A0A12);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: nearBlack,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
