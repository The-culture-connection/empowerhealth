import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Loading animation with 60 BPM pulsing (1 beat per second)
class ProviderSearchLoading extends StatefulWidget {
  final VoidCallback? onComplete;
  final Duration? duration;

  const ProviderSearchLoading({
    super.key,
    this.onComplete,
    this.duration,
  });

  @override
  State<ProviderSearchLoading> createState() => _ProviderSearchLoadingState();
}

class _ProviderSearchLoadingState extends State<ProviderSearchLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // 60 BPM = 1 beat per second = 1 second duration
    _controller = AnimationController(
      duration: const Duration(seconds: 1), // 60 BPM
      vsync: this,
    );

    // Create a pulse animation that goes from 0.4 to 1.0 opacity for more visible change
    _pulseAnimation = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    // Start the animation
    _controller.repeat(reverse: true);

    // If duration is provided, call onComplete after that time
    if (widget.duration != null) {
      Future.delayed(widget.duration!, () {
        if (mounted && widget.onComplete != null) {
          widget.onComplete!();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFF8F6F8)],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Pulsing heart icon with scale animation for more visible beat
                  Transform.scale(
                    scale: 0.8 + (_pulseAnimation.value * 0.2), // Scale from 0.8 to 1.0
                    child: Opacity(
                      opacity: _pulseAnimation.value,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF663399).withOpacity(_pulseAnimation.value),
                              const Color(0xFFCBBEC9).withOpacity(_pulseAnimation.value),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(40),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF663399).withOpacity(_pulseAnimation.value * 0.4),
                              blurRadius: 20 + (_pulseAnimation.value * 10), // Pulse shadow too
                              spreadRadius: 5 + (_pulseAnimation.value * 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Finding your care team...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
