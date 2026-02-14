import 'dart:ui';

import 'package:saber/components/canvas/_stroke.dart';

import 'package:saber/data/tools/_tool.dart';

double square(double x) => x * x;
double sqrDistanceBetween(Offset p1, Offset p2) =>
    square(p1.dx - p2.dx) + square(p1.dy - p2.dy);

class Eraser extends Tool {
  final double size;
  late final double sqrSize = square(size);

  List<Stroke> _erased = [];

  Eraser({this.size = 10});

  @override
  ToolId get toolId => .eraser;

  /// Returns any [strokes] that overlap with the given [scribbleStroke].
  /// This is used for the scribble-to-erase feature.
  static List<Stroke> findStrokesToErase(
    Stroke scribbleStroke,
    List<Stroke> strokes,
  ) {
    final List<Stroke> toErase = [];
    final sqrSize = square(
      scribbleStroke.options.size * 2,
    ); // Use 2x stroke size for collision

    for (final stroke in strokes) {
      if (_doesStrokeCollide(scribbleStroke, stroke, sqrSize)) {
        toErase.add(stroke);
      }
    }
    return toErase;
  }

  /// Returns any [strokes] that are close to the given [eraserPos].
  List<Stroke> checkForOverlappingStrokes(
    Offset eraserPos,
    List<Stroke> strokes,
  ) {
    final List<Stroke> overlapping = [];
    for (int i = 0; i < strokes.length; i++) {
      final stroke = strokes[i];
      if (_shouldStrokeBeErased(eraserPos, stroke, sqrSize)) {
        overlapping.add(stroke);
        _erased.add(stroke);
      }
    }
    return overlapping;
  }

  /// Returns the strokes that have been erased during this drag.
  List<Stroke> onDragEnd() {
    final List<Stroke> erased = _erased;
    _erased = [];
    return erased;
  }

  /// Check if [scribbleStroke] collides with [targetStroke].
  static bool _doesStrokeCollide(
    Stroke scribbleStroke,
    Stroke targetStroke,
    double sqrSize,
  ) {
    // Check if any point of the scribble is close to any point of the target stroke
    for (final scribblePoint in scribbleStroke.lowQualityPolygon) {
      for (int i = 0; i < targetStroke.lowQualityPolygon.length; i++) {
        final targetPoint = targetStroke.lowQualityPolygon[i];
        if (sqrDistanceBetween(scribblePoint, targetPoint) <= sqrSize) {
          return true;
        }
      }
    }
    return false;
  }

  static bool _shouldStrokeBeErased(
    Offset eraserPos,
    Stroke stroke,
    double sqrSize,
  ) {
    if (stroke.length <= 3) {
      if (stroke.lowQualityPath.contains(eraserPos)) return true;
    }

    /// skip checking every few vertices for performance
    final int verticesToSkip = switch (stroke.lowQualityPolygon.length) {
      < 100 => 0,
      < 1000 => 1,
      _ => 2,
    };

    for (
      int i = 0;
      i < stroke.lowQualityPolygon.length;
      i += verticesToSkip + 1
    ) {
      final Offset strokeVertex = stroke.lowQualityPolygon[i];
      if (sqrDistanceBetween(strokeVertex, eraserPos) <= sqrSize) return true;
    }
    return false;
  }
}
