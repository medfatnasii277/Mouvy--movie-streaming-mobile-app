import 'package:flutter/material.dart';
import 'dart:math';

class FloatingDots extends StatefulWidget {
  final int numberOfDots;
  final Color dotColor;
  final double dotSize;
  final Duration animationDuration;

  const FloatingDots({
    super.key,
    this.numberOfDots = 20,
    this.dotColor = const Color(0xFF00FF7F),
    this.dotSize = 4.0,
    this.animationDuration = const Duration(seconds: 10),
  });

  @override
  State<FloatingDots> createState() => _FloatingDotsState();
}

class _FloatingDotsState extends State<FloatingDots> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _xAnimations;
  late List<Animation<double>> _yAnimations;
  late List<double> _startX;
  late List<double> _startY;
  late List<double> _endX;
  late List<double> _endY;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    final random = Random();
    _controllers = [];
    _xAnimations = [];
    _yAnimations = [];
    _startX = [];
    _startY = [];
    _endX = [];
    _endY = [];

    for (int i = 0; i < widget.numberOfDots; i++) {
      // Random start and end positions
      final startX = random.nextDouble();
      final startY = random.nextDouble();
      final endX = random.nextDouble();
      final endY = random.nextDouble();

      _startX.add(startX);
      _startY.add(startY);
      _endX.add(endX);
      _endY.add(endY);

      final controller = AnimationController(
        duration: widget.animationDuration,
        vsync: this,
      );

      final xAnimation = Tween<double>(
        begin: startX,
        end: endX,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ));

      final yAnimation = Tween<double>(
        begin: startY,
        end: endY,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ));

      _controllers.add(controller);
      _xAnimations.add(xAnimation);
      _yAnimations.add(yAnimation);

      // Start animation with random delay
      Future.delayed(Duration(milliseconds: random.nextInt(5000)), () {
        if (mounted) {
          controller.repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: List.generate(widget.numberOfDots, (index) {
        return AnimatedBuilder(
          animation: Listenable.merge([_xAnimations[index], _yAnimations[index]]),
          builder: (context, child) {
            return Positioned(
              left: _xAnimations[index].value * MediaQuery.of(context).size.width,
              top: _yAnimations[index].value * MediaQuery.of(context).size.height,
              child: Container(
                width: widget.dotSize,
                height: widget.dotSize,
                decoration: BoxDecoration(
                  color: widget.dotColor.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}