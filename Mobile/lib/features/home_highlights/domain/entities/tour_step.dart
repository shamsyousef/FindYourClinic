import 'package:flutter/widgets.dart';

class TourStep {
  final GlobalKey targetKey;
  final String title;
  final String description;
  final EdgeInsets cutoutPadding;
  final double cutoutRadius;

  const TourStep({
    required this.targetKey,
    required this.title,
    required this.description,
    this.cutoutPadding = const EdgeInsets.all(8),
    this.cutoutRadius = 16,
  });
}
