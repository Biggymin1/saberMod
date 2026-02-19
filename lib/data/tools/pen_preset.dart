import 'package:flutter/material.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:saber/data/tools/_tool.dart';
import 'package:saber/data/tools/pen.dart';
import 'package:saber/data/tools/shape_pen.dart';

/// A pen preset that stores color, stroke options, and pen type.
class PenPreset {
  const PenPreset({
    required this.color,
    required this.options,
    required this.penType,
  });

  final Color color;
  final StrokeOptions options;
  final PenType penType;

  /// Creates a Pen instance from this preset.
  Pen createPen() {
    switch (penType) {
      case PenType.fountainPen:
        return Pen.fountainPen()
          ..color = color
          ..options = options;
      case PenType.ballpointPen:
        return Pen.ballpointPen()
          ..color = color
          ..options = options;
      case PenType.shapePen:
        return ShapePen()
          ..color = color
          ..options = options;
    }
  }

  /// Converts this preset to a JSON map.
  Map<String, dynamic> toJson() => {
    'color': color.toARGB32(),
    'options': options.toJson(),
    'penType': penType.index,
  };

  /// Creates a preset from a JSON map.
  factory PenPreset.fromJson(Map<String, dynamic> json) {
    return PenPreset(
      color: Color(json['color'] as int? ?? Colors.black.toARGB32()),
      options: json['options'] != null
          ? StrokeOptions.fromJson(json['options'] as Map<String, dynamic>)
          : Pen.defaultOptions,
      penType: PenType.values[json['penType'] as int? ?? 0],
    );
  }

  /// Default preset values.
  static PenPreset get defaultPreset1 => PenPreset(
    color: Colors.black,
    options: Pen.defaultOptions,
    penType: PenType.fountainPen,
  );
  static PenPreset get defaultPreset2 => PenPreset(
    color: Colors.red,
    options: Pen.defaultOptions,
    penType: PenType.fountainPen,
  );
  static PenPreset get defaultPreset3 => PenPreset(
    color: Colors.blue,
    options: Pen.defaultOptions,
    penType: PenType.ballpointPen,
  );
}

/// Types of pens that can be stored in a preset.
enum PenType { fountainPen, ballpointPen, shapePen }

/// Extension to get the icon for each pen type.
extension PenTypeIcon on PenType {
  IconData get icon {
    switch (this) {
      case PenType.fountainPen:
        return Pen.fountainPenIcon;
      case PenType.ballpointPen:
        return Pen.ballpointPenIcon;
      case PenType.shapePen:
        return ShapePen.shapePenIcon;
    }
  }

  ToolId get toolId {
    switch (this) {
      case PenType.fountainPen:
        return ToolId.fountainPen;
      case PenType.ballpointPen:
        return ToolId.ballpointPen;
      case PenType.shapePen:
        return ToolId.shapePen;
    }
  }
}
