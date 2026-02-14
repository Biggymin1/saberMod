import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:saber/components/canvas/canvas_gesture_detector.dart';
import 'package:saber/components/canvas/canvas_preview.dart';
import 'package:saber/components/theming/adaptive_icon.dart';
import 'package:saber/components/theming/saber_theme.dart';
import 'package:saber/data/editor/editor_core_info.dart';
import 'package:saber/i18n/strings.g.dart';

class EditorPageManager extends StatefulWidget {
  const EditorPageManager({
    super.key,
    required this.coreInfo,
    required this.currentPageIndex,
    required this.redrawAndSave,
    required this.insertPageAfter,
    required this.duplicatePage,
    required this.clearPage,
    required this.deletePage,
    required this.transformationController,
  });

  final EditorCoreInfo coreInfo;
  final int? currentPageIndex;
  final VoidCallback redrawAndSave;

  final void Function(int) insertPageAfter;
  final void Function(int) duplicatePage;
  final void Function(int) clearPage;
  final void Function(int) deletePage;

  final TransformationController transformationController;

  @override
  State<EditorPageManager> createState() => _EditorPageManagerState();
}

class _EditorPageManagerState extends State<EditorPageManager> {
  void scrollToPage(int pageIndex) => CanvasGestureDetector.scrollToPage(
    pageIndex: pageIndex,
    pages: widget.coreInfo.pages,
    screenWidth: MediaQuery.sizeOf(context).width,
    transformationController: widget.transformationController,
  );

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;
    final cupertino = platform.isCupertino;

    // Get list of bookmarked pages
    final bookmarkedPages = <int>[];
    for (int i = 0; i < widget.coreInfo.pages.length; i++) {
      if (widget.coreInfo.pages[i].isBookmarked) {
        bookmarkedPages.add(i);
      }
    }

    return SizedBox(
      width: cupertino ? null : 300,
      height: cupertino ? 600 : null,
      child: Column(
        children: [
          // Bookmarks section
          if (bookmarkedPages.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  const Icon(Icons.bookmark, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    t.editor.menu.bookmarks,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: bookmarkedPages.length,
                itemBuilder: (context, index) {
                  final pageIndex = bookmarkedPages[index];
                  return InkWell(
                    onTap: () {
                      scrollToPage(pageIndex);
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      width: 80,
                      padding: const EdgeInsets.all(4),
                      child: Column(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: CanvasPreview(
                                  pageIndex: pageIndex,
                                  height: null,
                                  coreInfo: widget.coreInfo,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${pageIndex + 1}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(),
          ],
          Expanded(
            child: ReorderableListView.builder(
              buildDefaultDragHandles: false,
              itemCount: widget.coreInfo.pages.length,
              itemBuilder: (context, pageIndex) {
                final isEmptyLastPage =
                    pageIndex == widget.coreInfo.pages.length - 1 &&
                    widget.coreInfo.pages[pageIndex].isEmpty;
                return InkWell(
                  key: ValueKey(pageIndex),
                  onTap: () => scrollToPage(pageIndex),
                  child: Padding(
                    padding: const .all(8),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Text(
                              '${pageIndex + 1} / ${widget.coreInfo.pages.length}',
                            ),
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: cupertino ? 100 : 150,
                                maxHeight: 250,
                              ),
                              child: FittedBox(
                                child: CanvasPreview(
                                  pageIndex: pageIndex,
                                  height: null,
                                  coreInfo: widget.coreInfo,
                                ),
                              ),
                            ),
                            MouseRegion(
                              cursor: SystemMouseCursors.resizeUpDown,
                              child: ReorderableDragStartListener(
                                index: pageIndex,
                                child: const Padding(
                                  padding: .all(8),
                                  child: Icon(Icons.drag_handle),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              tooltip:
                                  widget.coreInfo.pages[pageIndex].isBookmarked
                                  ? t.editor.menu.removeBookmark
                                  : t.editor.menu.addBookmark,
                              icon: Icon(
                                widget.coreInfo.pages[pageIndex].isBookmarked
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                              ),
                              onPressed: () => setState(() {
                                widget.coreInfo.pages[pageIndex].isBookmarked =
                                    !widget
                                        .coreInfo
                                        .pages[pageIndex]
                                        .isBookmarked;
                                widget.redrawAndSave();
                              }),
                            ),
                            IconButton(
                              tooltip: t.editor.menu.insertPage,
                              icon: const AdaptiveIcon(
                                icon: Icons.insert_page_break,
                                cupertinoIcon: CupertinoIcons.add,
                              ),
                              onPressed: () => setState(() {
                                widget.insertPageAfter(pageIndex);
                                scrollToPage(pageIndex + 1);
                              }),
                            ),
                            IconButton(
                              tooltip: t.editor.menu.duplicatePage,
                              icon: const AdaptiveIcon(
                                icon: Icons.content_copy,
                                cupertinoIcon: CupertinoIcons.doc_on_clipboard,
                              ),
                              onPressed: () => setState(() {
                                widget.duplicatePage(pageIndex);
                                scrollToPage(pageIndex + 1);
                              }),
                            ),
                            IconButton(
                              tooltip: t.editor.menu.clearPage(
                                page: pageIndex + 1,
                                totalPages: widget.coreInfo.pages.length,
                              ),
                              icon: const Icon(Icons.cleaning_services),
                              onPressed: isEmptyLastPage
                                  ? null
                                  : () => setState(() {
                                      widget.clearPage(pageIndex);
                                      scrollToPage(pageIndex);
                                    }),
                            ),
                            IconButton(
                              tooltip: t.editor.menu.deletePage,
                              icon: const AdaptiveIcon(
                                icon: Icons.delete,
                                cupertinoIcon: CupertinoIcons.delete,
                              ),
                              onPressed: isEmptyLastPage
                                  ? null
                                  : () => setState(() {
                                      widget.deletePage(pageIndex);
                                      scrollToPage(pageIndex);
                                    }),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
              onReorder: (oldIndex, newIndex) {
                if (oldIndex == newIndex) return;
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }
                widget.coreInfo.pages.insert(
                  newIndex,
                  widget.coreInfo.pages.removeAt(oldIndex),
                );

                // reassign pageIndex of pages' strokes and images
                for (int i = 0; i < widget.coreInfo.pages.length; i++) {
                  for (final stroke in widget.coreInfo.pages[i].strokes) {
                    stroke.pageIndex = i;
                  }
                  for (final image in widget.coreInfo.pages[i].images) {
                    image.pageIndex = i;
                  }
                }

                widget.redrawAndSave();
              },
            ),
          ),
        ],
      ),
    );
  }
}
