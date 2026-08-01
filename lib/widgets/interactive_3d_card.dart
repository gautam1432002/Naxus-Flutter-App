import 'package:flutter/material.dart';

class Interactive3DCard extends StatefulWidget {
  final Widget child;

  const Interactive3DCard({super.key, required this.child});

  @override
  State<Interactive3DCard> createState() => _Interactive3DCardState();
}

class _Interactive3DCardState extends State<Interactive3DCard> with SingleTickerProviderStateMixin {
  double x = 0;
  double y = 0;
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = Tween<Offset>(begin: Offset.zero, end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _animation.addListener(() {
      setState(() {
        x = _animation.value.dx;
        y = _animation.value.dy;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerMove: (event) {
        RenderBox? box = context.findRenderObject() as RenderBox?;
        if (box == null) return;
        
        Offset localPosition = box.globalToLocal(event.position);
        double halfWidth = box.size.width / 2;
        double halfHeight = box.size.height / 2;
        
        // Tilt slightly towards the user's finger
        setState(() {
          y = ((localPosition.dx - halfWidth) / halfWidth) * 0.1;
          x = ((halfHeight - localPosition.dy) / halfHeight) * 0.1;
          
          x = x.clamp(-0.15, 0.15);
          y = y.clamp(-0.15, 0.15);
        });
      },
      onPointerUp: (_) {
        _animation = Tween<Offset>(
          begin: Offset(x, y),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
        _controller.forward(from: 0);
      },
      onPointerCancel: (_) {
        _animation = Tween<Offset>(
          begin: Offset(x, y),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
        _controller.forward(from: 0);
      },
      child: Transform(
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateX(x)
          ..rotateY(y),
        alignment: FractionalOffset.center,
        child: widget.child,
      ),
    );
  }
}
