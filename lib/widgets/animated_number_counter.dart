import 'package:flutter/material.dart';

class AnimatedNumberCounter extends StatelessWidget {
  final double value;
  final TextStyle style;
  final String prefix;
  final String suffix;
  final int fractionDigits;

  const AnimatedNumberCounter({
    super.key,
    required this.value,
    required this.style,
    this.prefix = '',
    this.suffix = '',
    this.fractionDigits = 0,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeOutCubic,
      builder: (context, val, child) {
        return Text(
          '$prefix${val.toStringAsFixed(fractionDigits)}$suffix',
          style: style,
        );
      },
    );
  }
}
