import 'package:flutter/material.dart';

class LoadingState extends StatelessWidget {
  final Color accentColor;
  final String message;

  const LoadingState({
    super.key,
    required this.accentColor,
    this.message = 'Loading...',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: accentColor),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
