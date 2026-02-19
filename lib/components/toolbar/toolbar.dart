import 'dart:io';

import 'package:collapsible/collapsible.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:keybinder/keybinder.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:saber/components/theming/adaptive_icon.dart';
import 'package:saber/components/theming/dynamic_material_app.dart';
import 'package:saber/components/toolbar/color_bar.dart';
import 'package:saber/components/toolbar/export_bar.dart';
import 'package:saber/components/toolbar/pen_modal.dart';
import 'package:saber/components/toolbar/selection_bar.dart';
import 'package:saber/components/toolbar/size_picker.dart';
import 'package:saber/components/toolbar/toolbar_button.dart';
import 'package:saber/data/editor/page.dart';
import 'package:saber/data/extensions/color_extensions.dart';
import 'package:saber/data/prefs.dart';
import 'package:saber/data/tools/_tool.dart';
import 'package:saber/data/tools/eraser.dart';
import 'package:saber/data/tools/highlighter.dart';
import 'package:saber/data/tools/laser_pointer.dart';
import 'package:saber/data/tools/link.dart';
import 'package:saber/data/tools/pen.dart';
import 'package:saber/data/tools/pencil.dart';
import 'package:saber/data/tools/select.dart';
import 'package:saber/i18n/strings.g.dart';

class Toolbar extends StatefulWidget {
  const Toolbar({
    super.key,
    required this.readOnly,
    required this.setTool,
    required this.currentTool,
    required this.setColor,
    required this.quillFocus,
    required this.textEditing,
    required this.toggleTextEditing,
    required this.undo,
    required this.isUndoPossible,
    required this.redo,
    required this.isRedoPossible,
    required this.toggleFingerDrawing,
    required this.pickPhoto,
    required this.paste,
    required this.duplicateSelection,
    required this.deleteSelection,
    required this.exportAsSba,
    required this.exportAsPdf,
    required this.exportAsPng,
  });

  final bool readOnly;

  final ValueChanged<Tool> setTool;
  final Tool currentTool;
  final ValueChanged<Color> setColor;

  final ValueNotifier<QuillStruct?> quillFocus;
  final bool textEditing;
  final VoidCallback toggleTextEditing;

  final VoidCallback undo;
  final bool isUndoPossible;
  final VoidCallback redo;
  final bool isRedoPossible;

  final VoidCallback toggleFingerDrawing;

  final VoidCallback pickPhoto;

  final VoidCallback paste;

  final VoidCallback duplicateSelection;
  final VoidCallback deleteSelection;

  final Future Function(BuildContext)? exportAsSba;
  final Future Function(BuildContext)? exportAsPdf;
  final Future Function(BuildContext)? exportAsPng;

  @override
  State<Toolbar> createState() => _ToolbarState();

  static const _buttonPaddingHorizontal = EdgeInsets.symmetric(horizontal: 6);
  static const _buttonPaddingVertical = EdgeInsets.symmetric(vertical: 6);

  /// The diameter of the circular FAB toggle button.
  static const double fabSize = 52;
}

class _ToolbarState extends State<Toolbar> with SingleTickerProviderStateMixin {
  ValueNotifier<bool> showExportOptions = ValueNotifier(false);
  ValueNotifier<bool> showColorOptions = ValueNotifier(false);
  ValueNotifier<ToolOptions> toolOptionsType = ValueNotifier(ToolOptions.hide);

  /// Controls whether the floating toolbar is expanded or collapsed.
  bool _isExpanded = false;

  late AnimationController _expandController;
  late Animation<double> _expandAnimation;

  // Layer links for anchoring pen/pencil/highlighter/color popups to their buttons.
  final _penLayerLink = LayerLink();
  final _pencilLayerLink = LayerLink();
  final _highlighterLayerLink = LayerLink();
  final _colorLayerLink = LayerLink();

  /// The currently-open pen/pencil/highlighter popup overlay, if any.
  OverlayEntry? _penPopupOverlay;

  /// The currently-open color popup overlay, if any.
  OverlayEntry? _colorPopupOverlay;

  @override
  void initState() {
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );

    _assignKeybindings();

    DynamicMaterialApp.addFullscreenListener(_setState);

    super.initState();
  }

  void _setState() => setState(() {});

  Keybinding? _ctrlF;
  Keybinding? _ctrlE;
  Keybinding? _ctrlC;
  Keybinding? _ctrlShiftS;
  Keybinding? _f11;
  Keybinding? _ctrlV;
  void _assignKeybindings() {
    _ctrlF = Keybinding([
      KeyCode.ctrl,
      KeyCode.from(LogicalKeyboardKey.keyF),
    ], inclusive: true);
    _ctrlE = Keybinding([
      KeyCode.ctrl,
      KeyCode.from(LogicalKeyboardKey.keyE),
    ], inclusive: true);
    _ctrlC = Keybinding([
      KeyCode.ctrl,
      KeyCode.from(LogicalKeyboardKey.keyC),
    ], inclusive: true);
    _ctrlShiftS = Keybinding([
      KeyCode.ctrl,
      KeyCode.shift,
      KeyCode.from(LogicalKeyboardKey.keyS),
    ], inclusive: true);
    _f11 = Keybinding([KeyCode.from(LogicalKeyboardKey.f11)], inclusive: true);
    _ctrlV = Keybinding([
      KeyCode.ctrl,
      KeyCode.from(LogicalKeyboardKey.keyV),
    ], inclusive: true);

    Keybinder.bind(_ctrlF!, widget.toggleFingerDrawing);
    Keybinder.bind(_ctrlE!, toggleEraser);
    Keybinder.bind(_ctrlC!, toggleColorOptions);
    Keybinder.bind(_ctrlShiftS!, toggleExportBar);
    Keybinder.bind(_f11!, toggleFullscreen);
    Keybinder.bind(_ctrlV!, widget.paste);
  }

  void _removeKeybindings() {
    if (_ctrlF != null) Keybinder.remove(_ctrlF!);
    if (_ctrlE != null) Keybinder.remove(_ctrlE!);
    if (_ctrlC != null) Keybinder.remove(_ctrlC!);
    if (_ctrlShiftS != null) Keybinder.remove(_ctrlShiftS!);
    if (_f11 != null) Keybinder.remove(_f11!);
    if (_ctrlV != null) Keybinder.remove(_ctrlV!);
  }

  void toggleEraser() {
    _hidePenPopup();
    toolOptionsType.value = ToolOptions.hide;
    widget.setTool(Eraser()); // this toggles eraser
  }

  void toggleColorOptions() {
    showColorOptions.value = !showColorOptions.value;
  }

  void toggleExportBar() {
    showExportOptions.value = !showExportOptions.value;
  }

  void toggleFullscreen() async {
    DynamicMaterialApp.setFullscreen(
      !DynamicMaterialApp.isFullscreen,
      updateSystem: true,
    );
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
        // Collapse sub-panels when toolbar is collapsed
        showExportOptions.value = false;
        showColorOptions.value = false;
        toolOptionsType.value = ToolOptions.hide;
        _hidePenPopup();
      }
    });
  }

  /// Shows the pen options popup anchored to [layerLink].
  /// [getTool] returns the pen whose options are shown.
  /// If the popup is already showing for the same link, it is dismissed instead.
  void _showPenPopup({
    required LayerLink layerLink,
    required Tool Function() getTool,
  }) {
    // If a popup is already open, close it (toggle off).
    if (_penPopupOverlay != null) {
      _hidePenPopup();
      return;
    }

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            // Full-screen invisible barrier — tap to dismiss.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _hidePenPopup,
                child: const SizedBox.expand(),
              ),
            ),
            // The popup card, positioned above the button via CompositedTransformFollower.
            CompositedTransformFollower(
              link: layerLink,
              showWhenUnlinked: false,
              targetAnchor: Alignment.topCenter,
              followerAnchor: Alignment.bottomCenter,
              offset: const Offset(0, -8),
              child: _AnimatedPopup(
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.grey[200],
                  shadowColor: Colors.black.withValues(alpha: 0.3),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: StatefulBuilder(
                      builder: (context, setPopupState) {
                        return PenModal(
                          getTool: getTool,
                          setTool: (pen) {
                            widget.setTool(pen);
                            // Rebuild the popup to reflect new pen type/options.
                            setPopupState(() {});
                            // Also rebuild the toolbar so the button icon updates.
                            setState(() {});
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    _penPopupOverlay = entry;
    Overlay.of(context).insert(entry);
  }

  void _hidePenPopup() {
    _penPopupOverlay?.remove();
    _penPopupOverlay = null;
  }

  /// Shows the color picker popup anchored to [layerLink].
  /// If the popup is already showing, it is dismissed instead.
  void _showColorPopup({required LayerLink layerLink}) {
    // If a popup is already open, close it (toggle off).
    if (_colorPopupOverlay != null) {
      _hideColorPopup();
      return;
    }

    final brightness = Theme.brightnessOf(context);
    final invert =
        stows.editorAutoInvert.value && brightness == Brightness.dark;

    final currentColor = switch (widget.currentTool) {
      final Pen pen => pen.color,
      final Select select => select.getDominantStrokeColor(),
      _ => null,
    };

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            // Full-screen invisible barrier — tap to dismiss.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _hideColorPopup,
                child: const SizedBox.expand(),
              ),
            ),
            // The popup card, positioned above the button via CompositedTransformFollower.
            CompositedTransformFollower(
              link: layerLink,
              showWhenUnlinked: false,
              targetAnchor: Alignment.topCenter,
              followerAnchor: Alignment.bottomCenter,
              offset: const Offset(0, -8),
              child: _AnimatedPopup(
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.grey[200],
                  shadowColor: Colors.black.withValues(alpha: 0.3),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: StatefulBuilder(
                      builder: (context, setPopupState) {
                        return ColorBar(
                          axis: Axis.vertical,
                          setColor: (color) {
                            widget.setColor(color);
                            setPopupState(() {});
                            setState(() {});
                          },
                          currentColor: currentColor,
                          invert: invert,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    _colorPopupOverlay = entry;
    Overlay.of(context).insert(entry);
  }

  void _hideColorPopup() {
    _colorPopupOverlay?.remove();
    _colorPopupOverlay = null;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);

    final brightness = Theme.brightnessOf(context);
    final invert =
        stows.editorAutoInvert.value && brightness == Brightness.dark;

    final isToolbarVertical =
        stows.editorToolbarAlignment.value == AxisDirection.left ||
        stows.editorToolbarAlignment.value == AxisDirection.right;

    final buttonPadding = isToolbarVertical
        ? Toolbar._buttonPaddingVertical
        : Toolbar._buttonPaddingHorizontal;

    final currentColor = switch (widget.currentTool) {
      final Pen pen => pen.color,
      final Select select => select.getDominantStrokeColor(),
      _ => null,
    };

    if (widget.currentTool == Select.currentSelect) {
      toolOptionsType.value = Select.currentSelect.doneSelecting
          ? ToolOptions.select
          : ToolOptions.hide;
    }

    // ── Sub-panel widgets (export bar, selection bar, color bar, quill toolbar) ──
    // Note: pen/pencil/highlighter options are now shown as overlay popups
    // anchored to each button, NOT inline in this panel.
    final subPanelContent = <Widget>[
      ValueListenableBuilder(
        valueListenable: showExportOptions,
        builder: (context, showExportOptions, child) {
          return Collapsible(
            axis: isToolbarVertical
                ? CollapsibleAxis.horizontal
                : CollapsibleAxis.vertical,
            maintainState: true,
            collapsed: !showExportOptions,
            child: child!,
          );
        },
        child: ExportBar(
          axis: isToolbarVertical ? Axis.vertical : Axis.horizontal,
          toggleExportBar: toggleExportBar,
          exportAsSba: widget.exportAsSba,
          exportAsPdf: widget.exportAsPdf,
          exportAsPng: widget.exportAsPng,
        ),
      ),
      ValueListenableBuilder(
        valueListenable: toolOptionsType,
        builder: (context, toolOptionsType, _) {
          return Collapsible(
            axis: isToolbarVertical
                ? CollapsibleAxis.horizontal
                : CollapsibleAxis.vertical,
            maintainState: true,
            collapsed: toolOptionsType != ToolOptions.select,
            child: toolOptionsType == ToolOptions.select
                ? SelectionBar(
                    duplicateSelection: widget.duplicateSelection,
                    deleteSelection: widget.deleteSelection,
                  )
                : const SizedBox.square(dimension: SizePicker.smallLength),
          );
        },
      ),
      ValueListenableBuilder(
        valueListenable: widget.quillFocus,
        builder: (context, quill, _) {
          final baseButtonStyle =
              IconButtonTheme.of(context).style ?? const ButtonStyle();

          final iconTheme = QuillIconTheme(
            iconButtonUnselectedData: IconButtonData(
              style: baseButtonStyle.copyWith(
                backgroundColor: WidgetStateProperty.all(Colors.transparent),
                foregroundColor: WidgetStateProperty.all(colorScheme.primary),
              ),
            ),
            iconButtonSelectedData: IconButtonData(
              style: baseButtonStyle.copyWith(
                backgroundColor: WidgetStateProperty.all(colorScheme.primary),
                foregroundColor: WidgetStateProperty.all(colorScheme.onPrimary),
              ),
            ),
          );
          return Collapsible(
            axis: isToolbarVertical
                ? CollapsibleAxis.horizontal
                : CollapsibleAxis.vertical,
            maintainState: false,
            collapsed: !widget.textEditing || quill == null,
            child: quill != null
                ? QuillSimpleToolbar(
                    controller: quill.controller,
                    config: QuillSimpleToolbarConfig(
                      axis: isToolbarVertical ? Axis.vertical : Axis.horizontal,
                      buttonOptions: QuillSimpleToolbarButtonOptions(
                        base: QuillToolbarBaseButtonOptions(
                          iconTheme: iconTheme,
                        ),
                      ),
                      multiRowsDisplay: !Platform.isAndroid && !Platform.isIOS,
                      showUndo: false,
                      showRedo: false,
                      showFontSize: false,
                      showFontFamily: false,
                      showClearFormat: false,
                    ),
                  )
                : const SizedBox.shrink(),
          );
        },
      ),
    ];

    // ── Main tool buttons row/column ──
    final toolButtons = Center(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Wrap(
          direction: isToolbarVertical ? Axis.vertical : Axis.horizontal,
          alignment: WrapAlignment.center,
          runSpacing: 8,
          children: [
            // ── Pen button with popup anchor ──
            CompositedTransformTarget(
              link: _penLayerLink,
              child: ToolbarIconButton(
                tooltip: Pen.currentPen.name,
                selected: widget.currentTool == Pen.currentPen,
                enabled: !widget.readOnly,
                onPressed: () {
                  // Always select the pen tool first.
                  if (widget.currentTool != Pen.currentPen) {
                    toolOptionsType.value = ToolOptions.hide;
                    widget.setTool(Pen.currentPen);
                  }
                  // Then toggle the popup.
                  _showPenPopup(
                    layerLink: _penLayerLink,
                    getTool: () => Pen.currentPen,
                  );
                },
                padding: buttonPadding,
                child: FaIcon(Pen.currentPen.icon, size: 16),
              ),
            ),
            // ── Pencil button with popup anchor ──
            CompositedTransformTarget(
              link: _pencilLayerLink,
              child: ToolbarIconButton(
                tooltip: t.editor.pens.pencil,
                selected: widget.currentTool == Pencil.currentPencil,
                enabled: !widget.readOnly,
                onPressed: () {
                  if (widget.currentTool != Pencil.currentPencil) {
                    toolOptionsType.value = ToolOptions.hide;
                    widget.setTool(Pencil.currentPencil);
                  }
                  _showPenPopup(
                    layerLink: _pencilLayerLink,
                    getTool: () => Pencil.currentPencil,
                  );
                },
                padding: buttonPadding,
                child: const FaIcon(Pencil.pencilIcon, size: 16),
              ),
            ),
            // ── Highlighter button with popup anchor ──
            CompositedTransformTarget(
              link: _highlighterLayerLink,
              child: ToolbarIconButton(
                tooltip: t.editor.pens.highlighter,
                selected: widget.currentTool == Highlighter.currentHighlighter,
                enabled: !widget.readOnly,
                onPressed: () {
                  if (widget.currentTool != Highlighter.currentHighlighter) {
                    toolOptionsType.value = ToolOptions.hide;
                    widget.setTool(Highlighter.currentHighlighter);
                  }
                  _showPenPopup(
                    layerLink: _highlighterLayerLink,
                    getTool: () => Highlighter.currentHighlighter,
                  );
                },
                padding: buttonPadding,
                child: const FaIcon(Highlighter.highlighterIcon, size: 16),
              ),
            ),
            // ── Color button with popup anchor ──
            CompositedTransformTarget(
              link: _colorLayerLink,
              child: ToolbarIconButton(
                tooltip: t.editor.toolbar.toggleColors,
                selected: _colorPopupOverlay != null,
                enabled: !widget.readOnly,
                onPressed: () => _showColorPopup(layerLink: _colorLayerLink),
                padding: buttonPadding,
                child: currentColor == null
                    ? const Icon(Icons.palette)
                    : Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: currentColor
                              .withInversion(invert)
                              .withValues(alpha: 1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.primary,
                            width: 2,
                          ),
                        ),
                      ),
              ),
            ),
            ToolbarIconButton(
              tooltip: t.editor.toolbar.select,
              selected: widget.currentTool is Select,
              enabled: !widget.readOnly,
              onPressed: () {
                _hidePenPopup();
                toolOptionsType.value = ToolOptions.hide;
                widget.setTool(Select.currentSelect);
              },
              padding: buttonPadding,
              child: const Icon(CupertinoIcons.lasso),
            ),
            ToolbarIconButton(
              tooltip: t.editor.pens.laserPointer,
              selected: widget.currentTool == LaserPointer.currentLaserPointer,
              enabled: true,
              onPressed: () {
                _hidePenPopup();
                toolOptionsType.value = ToolOptions.hide;
                widget.setTool(LaserPointer.currentLaserPointer);
              },
              padding: buttonPadding,
              child: const Icon(Symbols.stylus_laser_pointer),
            ),
            ToolbarIconButton(
              tooltip: t.editor.toolbar.toggleEraser,
              selected: widget.currentTool is Eraser,
              enabled: !widget.readOnly,
              onPressed: toggleEraser,
              padding: buttonPadding,
              child: const FaIcon(FontAwesomeIcons.eraser, size: 16),
            ),
            ToolbarIconButton(
              tooltip: t.editor.toolbar.link,
              selected: widget.currentTool is Link,
              enabled: !widget.readOnly,
              onPressed: () {
                _hidePenPopup();
                toolOptionsType.value = ToolOptions.hide;
                widget.setTool(Link.currentLink);
              },
              padding: buttonPadding,
              child: FaIcon(Link.linkIcon, size: 16),
            ),
            ToolbarIconButton(
              tooltip: t.editor.toolbar.photo,
              enabled: !widget.readOnly,
              onPressed: widget.pickPhoto,
              padding: buttonPadding,
              child: const AdaptiveIcon(
                icon: Icons.photo,
                cupertinoIcon: CupertinoIcons.photo,
              ),
            ),
            ToolbarIconButton(
              tooltip: t.editor.toolbar.text,
              selected: widget.textEditing,
              enabled: !widget.readOnly,
              onPressed: widget.toggleTextEditing,
              padding: buttonPadding,
              child: const AdaptiveIcon(
                icon: Icons.text_fields,
                cupertinoIcon: CupertinoIcons.text_cursor,
              ),
            ),
            if (!stows.hideFingerDrawingToggle.value)
              ValueListenableBuilder(
                valueListenable: stows.editorFingerDrawing,
                builder: (context, value, child) {
                  return ToolbarIconButton(
                    tooltip: t.editor.toolbar.toggleFingerDrawing,
                    selected: value,
                    enabled: !widget.readOnly,
                    onPressed: widget.toggleFingerDrawing,
                    padding: buttonPadding,
                    child: const Icon(CupertinoIcons.hand_draw),
                  );
                },
              ),
            ToolbarIconButton(
              tooltip: t.editor.toolbar.fullscreen,
              selected: DynamicMaterialApp.isFullscreen,
              enabled: !widget.readOnly,
              onPressed: toggleFullscreen,
              padding: buttonPadding,
              child: AdaptiveIcon(
                icon: DynamicMaterialApp.isFullscreen
                    ? Icons.fullscreen_exit
                    : Icons.fullscreen,
                cupertinoIcon: DynamicMaterialApp.isFullscreen
                    ? CupertinoIcons.fullscreen_exit
                    : CupertinoIcons.fullscreen,
              ),
            ),
            Wrap(
              direction: isToolbarVertical ? Axis.vertical : Axis.horizontal,
              children: [
                ToolbarIconButton(
                  tooltip: t.editor.toolbar.undo,
                  enabled: !widget.readOnly && widget.isUndoPossible,
                  onPressed: widget.undo,
                  padding: buttonPadding,
                  child: const AdaptiveIcon(
                    icon: Icons.undo,
                    cupertinoIcon: CupertinoIcons.arrow_uturn_left,
                  ),
                ),
                ToolbarIconButton(
                  tooltip: t.editor.toolbar.redo,
                  enabled: !widget.readOnly && widget.isRedoPossible,
                  onPressed: widget.redo,
                  padding: buttonPadding,
                  child: const AdaptiveIcon(
                    icon: Icons.redo,
                    cupertinoIcon: CupertinoIcons.arrow_uturn_right,
                  ),
                ),
              ],
            ),
            ValueListenableBuilder(
              valueListenable: showExportOptions,
              builder: (context, showExportOptions, child) {
                return ToolbarIconButton(
                  tooltip: t.editor.toolbar.export,
                  selected: showExportOptions,
                  enabled: !widget.readOnly,
                  onPressed: toggleExportBar,
                  padding: buttonPadding,
                  child: child!,
                );
              },
              child: const AdaptiveIcon(
                icon: Icons.share,
                cupertinoIcon: CupertinoIcons.share,
              ),
            ),
          ],
        ),
      ),
    );

    // ── Collapsible panel: always expands horizontally to the left ──
    // The Padding gives breathing room so the drop-shadow on the left rounded
    // corner is never clipped by SizeTransition's overflow rect.
    final collapsiblePanel = SizeTransition(
      sizeFactor: _expandAnimation,
      axis: Axis.horizontal,
      axisAlignment: 1, // grows from right to left
      child: Padding(
        padding: const EdgeInsets.only(left: 4, top: 4, bottom: 4),
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(24),
          color: Colors.grey[200],
          shadowColor: Colors.black.withValues(alpha: 0.25),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [...subPanelContent, toolButtons],
            ),
          ),
        ),
      ),
    );

    // ── Circular FAB toggle button ──
    final fabToggle = SizedBox(
      width: Toolbar.fabSize,
      height: Toolbar.fabSize,
      child: Material(
        elevation: 8,
        shape: const CircleBorder(),
        color: Colors.grey[200],
        shadowColor: Colors.black.withValues(alpha: 0.3),
        child: InkWell(
          onTap: _toggleExpanded,
          customBorder: const CircleBorder(),
          child: Center(
            child: AnimatedRotation(
              turns: _isExpanded ? 0.125 : 0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: const Icon(Icons.menu, color: Colors.black, size: 24),
            ),
          ),
        ),
      ),
    );

    // Panel slides out to the left of the FAB
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [collapsiblePanel, const SizedBox(width: 8), fabToggle],
    );
  }

  @override
  void dispose() {
    _hidePenPopup();
    _hideColorPopup();

    DynamicMaterialApp.removeFullscreenListener(_setState);
    DynamicMaterialApp.setFullscreen(false, updateSystem: true);

    _expandController.dispose();
    _removeKeybindings();
    super.dispose();
  }
}

enum ToolOptions { hide, pen, highlighter, pencil, select }

/// A widget that animates its child with a vertical expand animation.
/// The child expands from the bottom upward.
class _AnimatedPopup extends StatefulWidget {
  const _AnimatedPopup({required this.child});

  final Widget child;

  @override
  State<_AnimatedPopup> createState() => _AnimatedPopupState();
}

class _AnimatedPopupState extends State<_AnimatedPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ClipRect(
          child: Align(
            alignment: Alignment.bottomCenter,
            heightFactor: _animation.value,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
