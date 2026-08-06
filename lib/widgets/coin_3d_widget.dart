import 'dart:math';
import 'package:flutter/material.dart';

class Coin3DWidget extends StatefulWidget {
  final bool isFlipping;
  final String? result; // "HEADS" or "TAILS" or null

  const Coin3DWidget({
    super.key,
    required this.isFlipping,
    this.result,
  });

  @override
  State<Coin3DWidget> createState() => _Coin3DWidgetState();
}

class _Coin3DWidgetState extends State<Coin3DWidget>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _rotationAnim;
  Animation<double>? _heightAnim;

  @override
  void initState() {
    super.initState();
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2700),
    );

    _rotationAnim = Tween<double>(
      begin: 0,
      end: 16 * pi, // 8 complete 3D rotations
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.decelerate,
    ));

    _heightAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -100.0)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 35.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -100.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 45.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -12.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 10.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -12.0, end: 0.0)
            .chain(CurveTween(curve: Curves.bounceOut)),
        weight: 10.0,
      ),
    ]).animate(controller);

    _controller = controller;
  }

  @override
  void didUpdateWidget(Coin3DWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFlipping && !oldWidget.isFlipping) {
      _controller?.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || _rotationAnim == null || _heightAnim == null) {
      return const SizedBox.shrink();
    }

    final controller = _controller!;
    final rotationAnim = _rotationAnim!;
    final heightAnim = _heightAnim!;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        double angle = rotationAnim.value;
        double currentResultAngle = 0;

        if (!controller.isAnimating && widget.result != null) {
          currentResultAngle = (widget.result == 'TAILS') ? pi : 0;
        }

        double totalAngle = angle + currentResultAngle;
        bool showHeads = cos(totalAngle) >= 0;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.translate(
              offset: Offset(0, heightAnim.value),
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0025) // Perspective depth for 3D realism
                  ..rotateY(totalAngle),
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [
                        Color(0xFFFFF59D),
                        Color(0xFFFFD700),
                        Color(0xFFFFB300),
                        Color(0xFF8F5D00),
                      ],
                      stops: [0.15, 0.45, 0.8, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.45),
                        blurRadius: controller.isAnimating ? 35 : 18,
                        spreadRadius: controller.isAnimating ? 6 : 2,
                      ),
                    ],
                    border: Border.all(color: const Color(0xFFFFFDE7), width: 6),
                  ),
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(showHeads ? 0 : pi),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            showHeads ? '🪙' : '🦅',
                            style: const TextStyle(fontSize: 48),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            showHeads ? 'HEADS' : 'TAILS',
                            style: const TextStyle(
                              color: Color(0xFF3E2723),
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Dynamic shadow under the coin
            AnimatedContainer(
              duration: const Duration(milliseconds: 50),
              width: (110 + (heightAnim.value * 0.4)).clamp(30.0, 140.0),
              height: 12,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: (controller.isAnimating ? 0.3 : 0.6)),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
