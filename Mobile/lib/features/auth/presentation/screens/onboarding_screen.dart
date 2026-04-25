import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  late final AnimationController _bgController;
  late final Animation<double> _bgAnimation;
  int _currentPage = 0;

  static const _slides = [
    _Slide(
      icon: Icons.search_rounded,
      color1: Color(0xFF1A8FE3),
      color2: Color(0xFF0D6EAF),
      title: 'Find the Right Doctor',
      subtitle:
          'Search verified doctors by specialty, location, and rating — all in one place.',
    ),
    _Slide(
      icon: Icons.calendar_today_rounded,
      color1: Color(0xFF11A8CD),
      color2: Color(0xFF0D7FA0),
      title: 'Book in Seconds',
      subtitle:
          'Choose a time slot that works for you and confirm your appointment instantly.',
    ),
    _Slide(
      icon: Icons.favorite_rounded,
      color1: Color(0xFF0E9E8A),
      color2: Color(0xFF0A7A6A),
      title: 'Your Health, Our Priority',
      subtitle:
          'Track your records, manage prescriptions, and chat with your doctor anytime.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
    _bgAnimation = Tween<double>(begin: 0, end: 1).animate(_bgController);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_seen', true);
    if (!mounted) return;
    context.goNamed(RouteNames.login);
  }

  void _next() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _complete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_currentPage];
    return Scaffold(
      body: AnimatedBuilder(
        animation: _bgAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  slide.color1.withAlpha(220),
                  slide.color2,
                ],
                stops: [_bgAnimation.value * 0.4, 1.0],
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 16, 24, 0),
                  child: _currentPage < _slides.length - 1
                      ? TextButton(
                          onPressed: _complete,
                          child: Text(
                            'Skip',
                            style: AppTextStyles.bodyMd
                                .copyWith(color: Colors.white70),
                          ),
                        )
                      : const SizedBox(height: 40),
                ),
              ),

              // Illustration area
              Expanded(
                flex: 5,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (context, i) {
                    return _SlidePage(slide: _slides[i]);
                  },
                ),
              ),

              // Dots + buttons
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Dot indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_slides.length, (i) {
                          final isActive = i == _currentPage;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: isActive ? 28 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.white
                                  : Colors.white.withAlpha(80),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 40),

                      // Action button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _next,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: slide.color2,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            _currentPage < _slides.length - 1
                                ? 'Next'
                                : 'Get Started',
                            style: AppTextStyles.bodyMd.copyWith(
                              fontWeight: FontWeight.w700,
                              color: slide.color2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _Slide {
  final IconData icon;
  final Color color1;
  final Color color2;
  final String title;
  final String subtitle;

  const _Slide({
    required this.icon,
    required this.color1,
    required this.color2,
    required this.title,
    required this.subtitle,
  });
}

class _SlidePage extends StatefulWidget {
  final _Slide slide;
  const _SlidePage({required this.slide});

  @override
  State<_SlidePage> createState() => _SlidePageState();
}

class _SlidePageState extends State<_SlidePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideIn = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeIn,
      child: SlideTransition(
        position: _slideIn,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with animated rings
              _AnimatedIconRings(
                icon: widget.slide.icon,
                color: Colors.white,
              ),
              const SizedBox(height: 40),
              Text(
                widget.slide.title,
                style: AppTextStyles.heading2.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                widget.slide.subtitle,
                style: AppTextStyles.bodyMd.copyWith(
                  color: Colors.white.withAlpha(204),
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedIconRings extends StatefulWidget {
  final IconData icon;
  final Color color;
  const _AnimatedIconRings({required this.icon, required this.color});

  @override
  State<_AnimatedIconRings> createState() => _AnimatedIconRingsState();
}

class _AnimatedIconRingsState extends State<_AnimatedIconRings>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 180,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _RingsPainter(
              progress: _controller.value,
              color: widget.color,
            ),
            child: child,
          );
        },
        child: Center(
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(40),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withAlpha(100), width: 2),
            ),
            child: Icon(widget.icon, size: 44, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  final double progress;
  final Color color;
  _RingsPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    for (int i = 0; i < 3; i++) {
      final t = ((progress + i * 0.33) % 1.0);
      final radius = 50.0 + t * 40.0;
      final alpha = (1.0 - t);
      final paint = Paint()
        ..color = color.withAlpha((alpha * 60).round())
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_RingsPainter old) => old.progress != progress;
}
