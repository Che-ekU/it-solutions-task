import 'package:flutter/material.dart';
import 'dart:math';

/// Entrypoint of the application.
void main() {
  runApp(const MyApp());
}

/// [Widget] building the [MaterialApp].
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.grey[900],
        body: Center(
          child: Dock(
            items: const [
              Icons.person,
              Icons.message,
              Icons.call,
              Icons.camera,
              Icons.photo,
            ],
            builder: (e) {
              return Container(
                constraints: const BoxConstraints(minWidth: 48),
                height: 48,
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.primaries[e.hashCode % Colors.primaries.length],
                ),
                child: Center(child: Icon(e, color: Colors.white)),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Dock of the reorderable [items].
class Dock<T> extends StatefulWidget {
  const Dock({
    super.key,
    this.items = const [],
    required this.builder,
  });

  /// Initial [T] items to put in this [Dock].
  final List<T> items;

  /// Builder building the provided [T] item.
  final Widget Function(T) builder;

  @override
  State<Dock<T>> createState() => _DockState<T>();
}

/// State of the [Dock] used to manipulate the [_items].
class _DockState<T> extends State<Dock<T>> {
  /// [T] items being manipulated.
  late final List<T> _items = widget.items.toList();

  double _hoverIndex = -1; // Index for scaling and spacing.
  int? _draggingIndex; // Index of the currently dragged item.

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.black12,
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;

          return DragTarget<int>(
            onAccept: (draggedIndex) {
              setState(() {
                final draggedItem = _items.removeAt(draggedIndex);
                _items.insert(index, draggedItem);
                _draggingIndex = null;
              });
            },
            onWillAccept: (_) {
              setState(() => _hoverIndex = index.toDouble());
              return true;
            },
            onLeave: (_) {
              setState(() => _hoverIndex = -1);
            },
            builder: (context, candidateData, rejectedData) {
              return Draggable<int>(
                data: index,
                onDragStarted: () {
                  setState(() => _draggingIndex = index);
                },
                onDragEnd: (_) {
                  setState(() {
                    _draggingIndex = null;
                    _hoverIndex = -1;
                  });
                },
                feedback: Transform.scale(
                  scale: 0.95,
                  child: widget.builder(item),
                ),
                childWhenDragging: const SizedBox.shrink(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                  margin: EdgeInsets.symmetric(
                    horizontal: _getSpacing(index), // Adjust spacing
                  ),
                  transform: Matrix4.identity()
                    ..scale(
                      _getScale(index),
                      _getScale(index),
                    ),
                  child: widget.builder(item),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }

  /// Calculates the scale for the item based on its proximity to the hovered index.
  double _getScale(int index) {
    if (_draggingIndex == null) return 1.0;
    if (_draggingIndex == index) return 0.7; // Shrink the dragged item.
    final distance = (_hoverIndex - index).abs();
    return max(1.0, 1.3 - 0.2 * distance); // Scale up nearby items.
  }

  /// Adjust spacing to make room for the dragged item.
  double _getSpacing(int index) {
    if (_draggingIndex == null || _hoverIndex == -1) return 8.0;
    final distance = (_hoverIndex - index).abs();
    return distance <= 1
        ? 16.0 - 8.0 * distance
        : 8.0; // Increase gap near the hover index.
  }
}
