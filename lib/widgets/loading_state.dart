import 'package:flutter/material.dart';
import 'skeleton_loader.dart';

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
          const SkeletonLoader(width: 48, height: 48, shape: BoxShape.circle),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
