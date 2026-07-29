import 'package:flutter/material.dart';
import 'tactile_glass_button.dart';

/// A single, immutable, globally shared navigation header for all Nexus screens.
/// Enforces exact pixel positioning across the entire application.
class NexusUniversalHeader extends StatelessWidget {
  /// Called when the back button is pressed. Defaults to Navigator.pop.
  final VoidCallback? onBack;

  /// The icon for the back/close button. Defaults to arrow_back_ios_new.
  final IconData backIcon;

  /// Optional center widget (title text or status pill).
  final Widget? center;

  /// Optional list of right-side action buttons.
  final List<Widget> actions;

  const NexusUniversalHeader({
    super.key,
    this.onBack,
    this.backIcon = Icons.arrow_back_ios_new,
    this.center,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              // Left slot: Back Button
              TactileGlassButton(
                icon: backIcon,
                onTap: onBack ?? () => Navigator.of(context).pop(),
              ),

              // Center slot: Title or Status Pill
              Expanded(
                child: center != null
                    ? Center(child: center!)
                    : const SizedBox.shrink(),
              ),

              // Right slot: Action buttons
              if (actions.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: actions,
                )
              else
                const SizedBox(width: 48), // Balance spacer when no actions
            ],
          ),
        ),
      ),
    );
  }
}
