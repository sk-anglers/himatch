import 'package:flutter/material.dart';

/// An [IndexedStack] variant that lazily builds children on first display.
///
/// Standard [IndexedStack] builds all children at once even if only one is
/// visible. [LazyIndexedStack] defers each child's construction until the
/// user first navigates to that index, reducing initial build cost.
class LazyIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;

  const LazyIndexedStack({
    super.key,
    required this.index,
    required this.children,
  });

  @override
  State<LazyIndexedStack> createState() => _LazyIndexedStackState();
}

class _LazyIndexedStackState extends State<LazyIndexedStack> {
  late final List<bool> _activated;

  @override
  void initState() {
    super.initState();
    _activated = List.filled(widget.children.length, false);
    _activated[widget.index] = true;
  }

  @override
  void didUpdateWidget(LazyIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Mark newly selected index as activated
    if (!_activated[widget.index]) {
      _activated[widget.index] = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: widget.index,
      children: List.generate(widget.children.length, (i) {
        if (_activated[i]) {
          return widget.children[i];
        }
        return const SizedBox.shrink();
      }),
    );
  }
}
