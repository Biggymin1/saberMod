import 'dart:math';

import 'package:flutter/material.dart';
import 'package:saber/components/canvas/_stroke.dart';
import 'package:saber/components/canvas/image/editor_image.dart';
import 'package:saber/data/tools/_tool.dart';

class Select extends Tool {
  Select._();

  static final _currentSelect = Select._();
  static Select get currentSelect => _currentSelect;

  /// The minimum ratio of points inside a stroke or image
  /// for it to be selected.
  static const minPercentInside = 0.7;

  var selectResult = SelectResult(
    pageIndex: -1,
    strokes: const [],
    images: const [],
    path: Path(),
  );
  var doneSelecting = false;

  @override
  ToolId get toolId => .select;

  void unselect() {
    doneSelecting = false;
    selectResult.pageIndex = -1;
  }

  Color? getDominantStrokeColor() {
    if (!doneSelecting) return null;
    if (selectResult.strokes.isEmpty) return null;

    final colorDistribution = <Color, int>{};
    for (final stroke in selectResult.strokes) {
      colorDistribution.update(
        stroke.color,
        (value) => value + stroke.length,
        ifAbsent: () => stroke.length,
      );
    }
    assert(colorDistribution.isNotEmpty);

    return colorDistribution.entries.reduce((a, b) {
      return a.value > b.value ? a : b;
    }).key;
  }

  void onDragStart(Offset position, int pageIndex) {
    doneSelecting = false;
    selectResult = SelectResult(
      pageIndex: pageIndex,
      strokes: [],
      images: [],
      path: Path(),
    );
    selectResult.path.moveTo(position.dx, position.dy);
    onDragUpdate(position);
  }

  void onDragUpdate(Offset position) {
    selectResult.path.lineTo(position.dx, position.dy);
  }

  /// Adds the indices of any [strokes] that are inside the selection area
  /// to [selectResult.indices].
  void onDragEnd(List<Stroke> strokes, List<EditorImage> images) {
    selectResult.path.close();
    doneSelecting = true;

    for (int i = 0; i < strokes.length; i++) {
      final stroke = strokes[i];
      final percentInside = polygonPercentInside(
        selectResult.path,
        stroke.lowQualityPolygon,
      );
      if (percentInside > minPercentInside) {
        selectResult.strokes.add(stroke);
      }
    }

    for (int i = 0; i < images.length; i++) {
      final image = images[i];
      final percentInside = rectPercentInside(selectResult.path, image.dstRect);
      if (percentInside >= minPercentInside) {
        selectResult.images.add(image);
      }
    }
  }

  static double rectPercentInside(Path selection, Rect rect) {
    const int gridSize = 5;
    final gridCellWidth = rect.width / (gridSize - 1);
    final gridCellHeight = rect.height / (gridSize - 1);

    int pointsInside = 0;
    for (int x = 0; x < gridSize; x++) {
      for (int y = 0; y < gridSize; y++) {
        if (selection.contains(
          Offset(rect.left + gridCellWidth * x, rect.top + gridCellHeight * y),
        )) {
          pointsInside++;
        }
      }
    }

    // times 1.25 because the grid is not very accurate
    return pointsInside / (gridSize * gridSize) * 1.25;
  }

  static double polygonPercentInside(Path selection, List<Offset> polygon) {
    int pointsInside = 0;
    for (final point in polygon) {
      if (selection.contains(point)) {
        pointsInside++;
      }
    }
    return pointsInside / polygon.length;
  }
}

class SelectResult {
  int pageIndex;
  final List<Stroke> strokes;
  final List<EditorImage> images;
  Path path;

  SelectResult({
    required this.pageIndex,
    required this.strokes,
    required this.images,
    required this.path,
  });

  bool get isEmpty {
    return strokes.isEmpty && images.isEmpty;
  }

  /// The axis-aligned bounding rect that contains all selected strokes and images.
  Rect get boundingRect {
    double left = double.infinity,
        top = double.infinity,
        right = double.negativeInfinity,
        bottom = double.negativeInfinity;

    for (final stroke in strokes) {
      for (final point in stroke.lowQualityPolygon) {
        if (point.dx < left) left = point.dx;
        if (point.dy < top) top = point.dy;
        if (point.dx > right) right = point.dx;
        if (point.dy > bottom) bottom = point.dy;
      }
    }
    for (final image in images) {
      if (image.dstRect.left < left) left = image.dstRect.left;
      if (image.dstRect.top < top) top = image.dstRect.top;
      if (image.dstRect.right > right) right = image.dstRect.right;
      if (image.dstRect.bottom > bottom) bottom = image.dstRect.bottom;
    }

    if (left == double.infinity) return Rect.zero;
    return Rect.fromLTRB(left, top, right, bottom);
  }

  /// The visual size of each handle square in canvas-space units.
  /// Pass [currentScale] (the canvas zoom level) to keep handles a fixed
  /// screen-pixel size regardless of zoom.
  static double handleSize(double currentScale) =>
      max(8.0, 20.0 / currentScale);

  /// Returns the [Rect] for handle [index] around [bounds].
  ///
  /// Handle indices (8 handles):
  /// ```
  /// 0 --- 1 --- 2
  /// |           |
  /// 3           4
  /// |           |
  /// 5 --- 6 --- 7
  /// ```
  static Rect handleRectAt(int index, Rect bounds, double currentScale) {
    final hs = handleSize(currentScale) / 2;
    final center = switch (index) {
      0 => bounds.topLeft,
      1 => bounds.topCenter,
      2 => bounds.topRight,
      3 => Offset(bounds.left, bounds.center.dy),
      4 => Offset(bounds.right, bounds.center.dy),
      5 => bounds.bottomLeft,
      6 => bounds.bottomCenter,
      7 => bounds.bottomRight,
      _ => bounds.center,
    };
    return Rect.fromCenter(center: center, width: hs * 2, height: hs * 2);
  }

  /// Returns the point that stays fixed when dragging handle [index].
  /// This is the corner/edge diagonally opposite to the handle.
  static Offset pinnedPointForHandle(int index, Rect bounds) {
    return switch (index) {
      0 => bounds.bottomRight,
      1 => bounds.bottomCenter,
      2 => bounds.bottomLeft,
      3 => Offset(bounds.right, bounds.center.dy),
      4 => Offset(bounds.left, bounds.center.dy),
      5 => bounds.topRight,
      6 => bounds.topCenter,
      7 => bounds.topLeft,
      _ => bounds.center,
    };
  }

  SelectResult copyWith({
    int? pageIndex,
    List<Stroke>? strokes,
    List<EditorImage>? images,
    Path? path,
  }) {
    return SelectResult(
      pageIndex: pageIndex ?? this.pageIndex,
      strokes: strokes ?? this.strokes,
      images: images ?? this.images,
      path: path ?? this.path,
    );
  }
}
