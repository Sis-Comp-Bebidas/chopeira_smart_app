import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class BeerFillingAnimationWithoutLogo extends StatefulWidget {
  const BeerFillingAnimationWithoutLogo({super.key});

  @override
  BeerFillingAnimationWithoutLogoState createState() => BeerFillingAnimationWithoutLogoState();
}

class BeerFillingAnimationWithoutLogoState
    extends State<BeerFillingAnimationWithoutLogo> with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _fillController;
  late Animation<double> _fillAnimation;
  late Timer _bubbleTimer;

  final List<Bubble> _bubbles = [];

  @override
  void initState() {
    super.initState();

    // Initialize wave controller with smoother wave motion
    _waveController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2000), // Slower cycle for natural wave motion
    )..repeat();

    // Initialize fill controller for smooth filling
    _fillController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 6),
    );

    _fillAnimation = CurvedAnimation(
      parent: _fillController,
      curve: Curves.easeInOut,
    );

    // Start filling animation
    _startFillingAnimation();

    // Increase the bubble generation rate and ensure randomness in bubble appearance
    _bubbleTimer = Timer.periodic(Duration(milliseconds: 200), (timer) {
      setState(() {
        _bubbles.add(Bubble()); // Add new bubbles more frequently
      });
    });
  }

  void _startFillingAnimation() {
    _fillController.forward();
  }

  @override
  void dispose() {
    _waveController.dispose();
    _fillController.dispose();
    _bubbleTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Wave and filling animation
        AnimatedBuilder(
          animation: _fillAnimation,
          builder: (context, _) {
            return ClipPath(
              clipper: BeerWaveClipper(_fillAnimation.value, _waveController.value),
              child: Container(
                // Reduced height and width for the zoom-out effect
                height: MediaQuery.of(context).size.height * 0.6,
                width: MediaQuery.of(context).size.width * 0.6,
                color: Colors.amber.withOpacity(0.7), // Color of the "beer"
              ),
            );
          },
        ),
        // More bubbles rising with variation in size and speed
        ..._bubbles.map((bubble) => AnimatedBubble(bubble: bubble)),
      ],
    );
  }
}

// Custom clipper for the wave effect
class BeerWaveClipper extends CustomClipper<Path> {
  final double fillLevel;
  final double waveShift;

  BeerWaveClipper(this.fillLevel, this.waveShift);

  @override
  Path getClip(Size size) {
    final Path path = Path();
    final double fillHeight = size.height * fillLevel;

    // Draw the wave from left to right
    path.lineTo(0.0, size.height - fillHeight);

    final double waveHeight = 20.0; // Reduced wave height for subtler waves
    final double waveFrequency = 1.5 * math.pi / size.width; // Reduced frequency for sparser waves

    // Create a smooth, flowing wave at the top of the "beer"
    for (double i = 0.0; i <= size.width; i++) {
      path.lineTo(
        i,
        size.height - fillHeight + math.sin((i * waveFrequency) + (waveShift * 2 * math.pi)) * waveHeight,
      );
    }

    // Close the path at the bottom of the screen
    path.lineTo(size.width, size.height);
    path.lineTo(0.0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return true; // Redraw whenever the wave shifts or fill level changes
  }
}

// Bubble class representing each bubble
class Bubble {
  final double size = math.Random().nextDouble() * 20 + 10; // Random size for bubbles
  final double startX = math.Random().nextDouble(); // Random horizontal starting position
  final double speed = math.Random().nextDouble() * 2 + 1; // Random speed for bubbles

  Bubble();
}

// Animated bubble widget
class AnimatedBubble extends StatefulWidget {
  final Bubble bubble;

  const AnimatedBubble({super.key, required this.bubble});

  @override
  AnimatedBubbleState createState() => AnimatedBubbleState();
}

class AnimatedBubbleState extends State<AnimatedBubble> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animationY;
  late Animation<double> _animationX;

  @override
  void initState() {
    super.initState();

    // Control the bubble animation
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: (8 / widget.bubble.speed).round()), // Faster bubbles
    )..repeat(reverse: false);

    // Vertical bubble rising animation
    _animationY = Tween<double>(begin: 1.0, end: 0.0).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    ));

    // Horizontal bubble movement to sync with the wave
    _animationX = Tween<double>(begin: widget.bubble.startX, end: widget.bubble.startX + 0.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: MediaQuery.of(context).size.width * _animationX.value,
          top: MediaQuery.of(context).size.height * _animationY.value,
          child: Opacity(
            opacity: 0.7,
            child: Container(
              width: widget.bubble.size,
              height: widget.bubble.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.3), // Translucent white bubbles
              ),
            ),
          ),
        );
      },
    );
  }
}
