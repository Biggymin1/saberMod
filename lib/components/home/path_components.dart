import 'package:flutter/material.dart';
import 'package:saber/i18n/strings.g.dart';

class PathComponents extends StatelessWidget {
  PathComponents(
    String? path, {
    super.key,
    required this.onPathComponentTap,
    this.externalFolderPath,
  }) : components = _splitPath(path);

  final List<String> components;
  final void Function(String? path) onPathComponentTap;

  /// External folder path when browsing a user-selected directory
  final String? externalFolderPath;

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    return ElevatedButtonTheme(
      data: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          minimumSize: const Size(24, 8),
          padding: const .all(8),
          shape: RoundedRectangleBorder(borderRadius: .circular(4)),
        ),
      ),
      child: Padding(
        padding: const .symmetric(horizontal: 16),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // External folder indicator
            if (externalFolderPath != null) ...[
              ElevatedButton(
                onPressed: () {
                  onPathComponentTap(null);
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.folder_open,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(t.home.externalFolder),
                  ],
                ),
              ),
            ] else if (components.isNotEmpty)
              ElevatedButton(
                onPressed: () {
                  onPathComponentTap(null);
                },
                child: const Text('/'),
              ),
            for (var i = 0; i < components.length; i++) ...[
              const Icon(Icons.chevron_right, size: 16),
              ElevatedButton(
                onPressed: () {
                  final path = '/${components.sublist(0, i + 1).join('/')}';
                  onPathComponentTap(path);
                },
                child: Text(components[i]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static List<String> _splitPath(String? path) {
    return (path ?? '')
        .split(RegExp(r'[\\/]'))
        .where((s) => s.isNotEmpty)
        .toList(growable: false);
  }
}
