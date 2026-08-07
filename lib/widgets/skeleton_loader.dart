import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonLoader extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final BoxShape shape;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 24.0,
    this.shape = BoxShape.rectangle,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Shimmer.fromColors(
        baseColor: const Color(0xFF1E293B),
        highlightColor: const Color(0xFF334155),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            shape: shape,
            borderRadius: shape == BoxShape.circle ? null : BorderRadius.circular(borderRadius),
          ),
        ),
      ),
    );
  }
}
