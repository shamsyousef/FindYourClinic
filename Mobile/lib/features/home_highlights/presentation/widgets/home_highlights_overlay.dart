import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/tour_step.dart';
import '../cubits/home_highlights_cubit.dart';
import '../cubits/home_highlights_state.dart';

class HomeHighlightsOverlay extends StatefulWidget {
  final List<TourStep> steps;

  const HomeHighlightsOverlay({super.key, required this.steps});

  @override
  State<HomeHighlightsOverlay> createState() => _HomeHighlightsOverlayState();
}

class _HomeHighlightsOverlayState extends State<HomeHighlightsOverlay> {
  int _currentIndex = 0;
  Rect? _targetRect;

  @override
  void initState() {
    super.initState();
    context.read<HomeHighlightsCubit>().checkVisibility();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateRect());
  }

  @override
  void didUpdateWidget(covariant HomeHighlightsOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateRect());
  }

  void _updateRect() {
    if (!mounted) return;
    if (widget.steps.isEmpty) return;
    if (_currentIndex >= widget.steps.length) return;

    final ctx = widget.steps[_currentIndex].targetKey.currentContext;
    final box = ctx?.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) {
      // Target not rendered (off-screen sliver, conditional widget) — skip it.
      _advance(autoSkip: true);
      return;
    }
    final offset = box.localToGlobal(Offset.zero);
    final newRect = offset & box.size;
    if (newRect != _targetRect) {
      setState(() => _targetRect = newRect);
    }
  }

  void _advance({bool autoSkip = false}) {
    if (_currentIndex < widget.steps.length - 1) {
      setState(() {
        _currentIndex++;
        _targetRect = null;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _updateRect());
    } else if (!autoSkip) {
      _finish();
    } else {
      // Auto-skipped the last step — dismiss.
      _finish();
    }
  }

  void _finish() {
    context.read<HomeHighlightsCubit>().markAsSeen();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeHighlightsCubit, HomeHighlightsState>(
      builder: (context, state) {
        if (state is! HomeHighlightsVisible || widget.steps.isEmpty) {
          return const SizedBox.shrink();
        }

        final step = widget.steps[_currentIndex];
        final isLast = _currentIndex == widget.steps.length - 1;
        final rect = _targetRect;
        final padding = step.cutoutPadding;
        final inflated = rect == null
            ? null
            : Rect.fromLTRB(
                rect.left - padding.left,
                rect.top - padding.top,
                rect.right + padding.right,
                rect.bottom + padding.bottom,
              );

        return Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              // Dark scrim with cut-out — also blocks taps to underlying content.
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {}, // absorb taps
                  child: CustomPaint(
                    painter: _CoachMarkPainter(
                      cutout: inflated,
                      radius: step.cutoutRadius,
                    ),
                    size: Size.infinite,
                  ),
                ),
              ),
              // Skip button (top-right).
              Positioned(
                top: MediaQuery.paddingOf(context).top + 4,
                right: 8,
                child: TextButton(
                  onPressed: _finish,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.white.withAlpha(30),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'Skip',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              // Tooltip card.
              if (inflated != null)
                _Tooltip(
                  rect: inflated,
                  step: step,
                  index: _currentIndex,
                  total: widget.steps.length,
                  isLast: isLast,
                  onNext: _advance,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Tooltip extends StatelessWidget {
  final Rect rect;
  final TourStep step;
  final int index;
  final int total;
  final bool isLast;
  final VoidCallback onNext;

  const _Tooltip({
    required this.rect,
    required this.step,
    required this.index,
    required this.total,
    required this.isLast,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final safeTop = MediaQuery.paddingOf(context).top;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    const horizontalMargin = 20.0;
    const gap = 16.0;

    final spaceAbove = rect.top - safeTop;
    final spaceBelow = screen.height - rect.bottom - safeBottom;
    final placeBelow = spaceBelow >= spaceAbove;

    final card = Container(
      width: screen.width - horizontalMargin * 2,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withAlpha(80), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(120),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(40),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${index + 1} of $total',
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            step.title,
            style: AppTextStyles.heading3.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            step.description,
            style: AppTextStyles.bodyMd.copyWith(
              color: Colors.white.withAlpha(220),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 26,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text(
                isLast ? 'Got it' : 'Next',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return Positioned(
      left: horizontalMargin,
      right: horizontalMargin,
      top: placeBelow ? rect.bottom + gap : null,
      bottom: placeBelow ? null : screen.height - rect.top + gap,
      child: Align(alignment: Alignment.center, child: card),
    );
  }
}

class _CoachMarkPainter extends CustomPainter {
  final Rect? cutout;
  final double radius;

  _CoachMarkPainter({required this.cutout, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withAlpha(200);
    final full = Offset.zero & size;

    if (cutout == null) {
      canvas.drawRect(full, paint);
      return;
    }

    final outer = Path()..addRect(full);
    final hole = Path()
      ..addRRect(RRect.fromRectAndRadius(cutout!, Radius.circular(radius)));
    canvas.drawPath(
      Path.combine(PathOperation.difference, outer, hole),
      paint,
    );

    // Subtle highlight ring around the cutout.
    final ringPaint = Paint()
      ..color = AppColors.primary.withAlpha(180)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(cutout!, Radius.circular(radius)),
      ringPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CoachMarkPainter oldDelegate) {
    return oldDelegate.cutout != cutout || oldDelegate.radius != radius;
  }
}
