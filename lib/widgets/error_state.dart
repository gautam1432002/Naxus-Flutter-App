import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'tactile_glass_button.dart';

class ErrorState extends StatefulWidget {
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
  State<ErrorState> createState() => _ErrorStateState();
}

class _ErrorStateState extends State<ErrorState> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: AnimatedSize(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 24),
              TactileGlassButton(
                icon: Icons.refresh,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  widget.onRetry();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
