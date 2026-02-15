import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:saber/components/canvas/_rectangle_stroke.dart';
import 'package:saber/components/canvas/_stroke.dart';
import 'package:saber/data/editor/page.dart';
import 'package:saber/data/tools/_tool.dart';

class Link extends Tool {
  Link._();

  static final _currentLink = Link._();
  static Link get currentLink => _currentLink;

  @override
  ToolId get toolId => .link;

  static const IconData linkIcon = FontAwesomeIcons.code;

  /// The default link color (yellow highlight)
  static Color get defaultColor => const Color(0x80FFEB3B);

  late final Color color;

  /// The current link being drawn
  RectangleStroke? currentStroke;

  /// The target page index for the current link
  int? targetPageIndex;

  Link({Color? color}) : color = color ?? defaultColor;

  void onDragStart(Offset position, EditorPage page, int pageIndex) {
    targetPageIndex = null;
    currentStroke = RectangleStroke(
      color: color,
      pressureEnabled: false,
      options: StrokeOptions(),
      pageIndex: pageIndex,
      page: page,
      toolId: toolId,
      rect: Rect.fromPoints(position, position),
    );
  }

  void onDragUpdate(Offset position) {
    if (currentStroke == null) return;

    final startPoint = currentStroke!.rect.topLeft;
    currentStroke!.rect = Rect.fromPoints(startPoint, position);
    currentStroke!.markPolygonNeedsUpdating();
  }

  RectangleStroke? onDragEnd() {
    final stroke = currentStroke;
    currentStroke = null;
    if (stroke == null) return null;

    // Don't create very small links (accidental clicks)
    if (stroke.rect.width < 20 || stroke.rect.height < 20) {
      return null;
    }

    stroke.markPolygonNeedsUpdating();
    return stroke;
  }
}
