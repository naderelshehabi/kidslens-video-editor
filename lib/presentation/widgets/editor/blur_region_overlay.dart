import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:kidslens_video_editor/data/models/edit_action.dart';

/// A blur region overlay with draggable handles for editing blur areas
class BlurRegionOverlay extends StatefulWidget {
  const BlurRegionOverlay({
    required this.blurAction,
    required this.videoSize,
    super.key,
    this.isSelected = false,
    this.isEditing = false,
    this.onBoundingBoxChanged,
    this.onIntensityChanged,
    this.onSelected,
    this.onHandleAdded,
    this.onHandleRemoved,
  });

  final EditAction blurAction;
  final Size videoSize;
  final bool isSelected;
  final bool isEditing;
  final void Function(BoundingBox newBox)? onBoundingBoxChanged;
  final void Function(double intensity)? onIntensityChanged;
  final VoidCallback? onSelected;
  final void Function(Offset position)? onHandleAdded;
  final void Function(int handleIndex)? onHandleRemoved;

  @override
  State<BlurRegionOverlay> createState() => _BlurRegionOverlayState();
}

class _BlurRegionOverlayState extends State<BlurRegionOverlay> {
  // Polygon handles for the blur region (normalized 0-1 coordinates)
  late List<Offset> _handles;
  int? _draggingHandleIndex;
  bool _isDraggingRegion = false;
  Offset _dragStartOffset = Offset.zero;
  List<Offset>? _dragStartHandles;

  @override
  void initState() {
    super.initState();
    _initializeHandles();
  }

  @override
  void didUpdateWidget(BlurRegionOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.blurAction.boundingBox != widget.blurAction.boundingBox) {
      _initializeHandles();
    }
  }

  void _initializeHandles() {
    final box = widget.blurAction.boundingBox;
    if (box != null) {
      // Initialize with 4 corner handles from bounding box
      _handles = [
        Offset(box.left, box.top),
        Offset(box.left + box.width, box.top),
        Offset(box.left + box.width, box.top + box.height),
        Offset(box.left, box.top + box.height),
      ];
    } else {
      // Default to full frame
      _handles = [
        const Offset(0.1, 0.1),
        const Offset(0.9, 0.1),
        const Offset(0.9, 0.9),
        const Offset(0.1, 0.9),
      ];
    }
  }

  Offset _normalizedToPixel(Offset normalized) => Offset(
      normalized.dx * widget.videoSize.width,
      normalized.dy * widget.videoSize.height,
    );

  Offset _pixelToNormalized(Offset pixel) => Offset(
      (pixel.dx / widget.videoSize.width).clamp(0.0, 1.0),
      (pixel.dy / widget.videoSize.height).clamp(0.0, 1.0),
    );

  BoundingBox _handlesToBoundingBox() {
    if (_handles.isEmpty) {
      return const BoundingBox(left: 0, top: 0, width: 1, height: 1);
    }

    var minX = _handles.first.dx;
    var maxX = _handles.first.dx;
    var minY = _handles.first.dy;
    var maxY = _handles.first.dy;

    for (final handle in _handles) {
      if (handle.dx < minX) minX = handle.dx;
      if (handle.dx > maxX) maxX = handle.dx;
      if (handle.dy < minY) minY = handle.dy;
      if (handle.dy > maxY) maxY = handle.dy;
    }

    return BoundingBox(
      left: minX,
      top: minY,
      width: maxX - minX,
      height: maxY - minY,
    );
  }

  void _onHandleDragStart(int index, DragStartDetails details) {
    setState(() {
      _draggingHandleIndex = index;
    });
  }

  void _onHandleDragUpdate(int index, DragUpdateDetails details) {
    if (_draggingHandleIndex != index) return;

    setState(() {
      final currentPixel = _normalizedToPixel(_handles[index]);
      final newPixel = currentPixel + details.delta;
      _handles[index] = _pixelToNormalized(newPixel);
    });
  }

  void _onHandleDragEnd(int index, DragEndDetails details) {
    if (_draggingHandleIndex == index) {
      setState(() {
        _draggingHandleIndex = null;
      });
      widget.onBoundingBoxChanged?.call(_handlesToBoundingBox());
    }
  }

  void _onRegionDragStart(DragStartDetails details) {
    setState(() {
      _isDraggingRegion = true;
      _dragStartOffset = details.localPosition;
      _dragStartHandles = List.from(_handles);
    });
  }

  void _onRegionDragUpdate(DragUpdateDetails details) {
    if (!_isDraggingRegion || _dragStartHandles == null) return;

    final delta = details.localPosition - _dragStartOffset;
    final normalizedDelta = Offset(
      delta.dx / widget.videoSize.width,
      delta.dy / widget.videoSize.height,
    );

    setState(() {
      for (var i = 0; i < _handles.length; i++) {
        final newX = (_dragStartHandles![i].dx + normalizedDelta.dx).clamp(0.0, 1.0);
        final newY = (_dragStartHandles![i].dy + normalizedDelta.dy).clamp(0.0, 1.0);
        _handles[i] = Offset(newX, newY);
      }
    });
  }

  void _onRegionDragEnd(DragEndDetails details) {
    if (_isDraggingRegion) {
      setState(() {
        _isDraggingRegion = false;
        _dragStartHandles = null;
      });
      widget.onBoundingBoxChanged?.call(_handlesToBoundingBox());
    }
  }

  void _onEdgeDoubleTap(Offset position) {
    if (!widget.isEditing) return;

    // Find the closest edge and add a handle on it
    final normalized = _pixelToNormalized(position);
    
    // Find the two closest handles to insert between
    var insertIndex = 0;
    var minDistance = double.infinity;
    
    for (var i = 0; i < _handles.length; i++) {
      final current = _handles[i];
      final next = _handles[(i + 1) % _handles.length];
      
      // Calculate distance to edge
      final edgeDistance = _distanceToLineSegment(normalized, current, next);
      if (edgeDistance < minDistance) {
        minDistance = edgeDistance;
        insertIndex = i + 1;
      }
    }

    // Insert handle if close enough to an edge
    if (minDistance < 0.1) {
      setState(() {
        _handles.insert(insertIndex, normalized);
      });
      widget.onHandleAdded?.call(position);
      widget.onBoundingBoxChanged?.call(_handlesToBoundingBox());
    }
  }

  void _onHandleDoubleTap(int index) {
    if (!widget.isEditing) return;
    if (_handles.length <= 3) return; // Minimum 3 handles for a polygon

    setState(() {
      _handles.removeAt(index);
    });
    widget.onHandleRemoved?.call(index);
    widget.onBoundingBoxChanged?.call(_handlesToBoundingBox());
  }

  double _distanceToLineSegment(Offset point, Offset start, Offset end) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final lengthSquared = dx * dx + dy * dy;
    
    if (lengthSquared == 0) {
      return (point - start).distance;
    }
    
    final t = ((point.dx - start.dx) * dx + (point.dy - start.dy) * dy) / lengthSquared;
    final tClamped = t.clamp(0.0, 1.0);
    
    final projX = start.dx + tClamped * dx;
    final projY = start.dy + tClamped * dy;
    
    return (point - Offset(projX, projY)).distance;
  }

  @override
  Widget build(BuildContext context) {
    if (_handles.isEmpty) return const SizedBox.shrink();

    final pixelHandles = _handles.map(_normalizedToPixel).toList();

    return GestureDetector(
      onTap: widget.onSelected,
      child: Stack(
        children: [
          // Blur effect within polygon
          ClipPath(
            clipper: _PolygonClipper(pixelHandles),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 20 * widget.blurAction.blurIntensity,
                sigmaY: 20 * widget.blurAction.blurIntensity,
              ),
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
          
          // Polygon outline
          if (widget.isSelected || widget.isEditing)
            CustomPaint(
              painter: _PolygonPainter(
                handles: pixelHandles,
                isEditing: widget.isEditing,
                isSelected: widget.isSelected,
              ),
              size: widget.videoSize,
            ),
          
          // Drag area for moving the entire region
          if (widget.isEditing)
            GestureDetector(
              onPanStart: _onRegionDragStart,
              onPanUpdate: _onRegionDragUpdate,
              onPanEnd: _onRegionDragEnd,
              onDoubleTapDown: (details) => _onEdgeDoubleTap(details.localPosition),
              child: CustomPaint(
                painter: _PolygonHitAreaPainter(handles: pixelHandles),
                size: widget.videoSize,
              ),
            ),
          
          // Handle points
          if (widget.isEditing)
            ...List.generate(_handles.length, (index) {
              final pixelPos = pixelHandles[index];
              return Positioned(
                left: pixelPos.dx - 8,
                top: pixelPos.dy - 8,
                child: GestureDetector(
                  onPanStart: (d) => _onHandleDragStart(index, d),
                  onPanUpdate: (d) => _onHandleDragUpdate(index, d),
                  onPanEnd: (d) => _onHandleDragEnd(index, d),
                  onDoubleTap: () => _onHandleDoubleTap(index),
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: _draggingHandleIndex == index 
                          ? Colors.blue 
                          : Colors.white,
                      border: Border.all(color: Colors.blue, width: 2),
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          
          // Intensity control panel when editing
          if (widget.isEditing)
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.blur_on, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      'Blur:',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    Expanded(
                      child: Slider(
                        value: widget.blurAction.blurIntensity.clamp(0.0, 1.0),
                        divisions: 20,
                        activeColor: Colors.blue,
                        inactiveColor: Colors.white30,
                        onChanged: (value) {
                          widget.onIntensityChanged?.call(value);
                        },
                      ),
                    ),
                    Text(
                      '${(widget.blurAction.blurIntensity * 100).round()}%',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Custom clipper for polygon shapes
class _PolygonClipper extends CustomClipper<Path> {
  _PolygonClipper(this.handles);

  final List<Offset> handles;

  @override
  Path getClip(Size size) {
    final path = Path();
    if (handles.isEmpty) return path;

    path.moveTo(handles.first.dx, handles.first.dy);
    for (var i = 1; i < handles.length; i++) {
      path.lineTo(handles[i].dx, handles[i].dy);
    }
    path.close();

    return path;
  }

  @override
  bool shouldReclip(_PolygonClipper oldClipper) => oldClipper.handles != handles;
}

/// Custom painter for polygon outline
class _PolygonPainter extends CustomPainter {
  _PolygonPainter({
    required this.handles,
    required this.isEditing,
    required this.isSelected,
  });

  final List<Offset> handles;
  final bool isEditing;
  final bool isSelected;

  @override
  void paint(Canvas canvas, Size size) {
    if (handles.isEmpty) return;

    final paint = Paint()
      ..color = isEditing ? Colors.blue : Colors.blue.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isEditing ? 3 : 2;

    final path = Path()
      ..moveTo(handles.first.dx, handles.first.dy);
    for (var i = 1; i < handles.length; i++) {
      path.lineTo(handles[i].dx, handles[i].dy);
    }
    path.close();

    canvas.drawPath(path, paint);

    // Draw dashed line when editing
    if (isEditing) {
      final dashPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      canvas.drawPath(path, dashPaint);
    }
  }

  @override
  bool shouldRepaint(_PolygonPainter oldDelegate) => oldDelegate.handles != handles ||
        oldDelegate.isEditing != isEditing ||
        oldDelegate.isSelected != isSelected;
}

/// Custom painter for polygon hit area (for drag detection)
class _PolygonHitAreaPainter extends CustomPainter {
  _PolygonHitAreaPainter({required this.handles});

  final List<Offset> handles;

  @override
  void paint(Canvas canvas, Size size) {
    // Invisible paint for hit testing
  }

  @override
  bool shouldRepaint(_PolygonHitAreaPainter oldDelegate) => oldDelegate.handles != handles;

  @override
  bool? hitTest(Offset position) {
    if (handles.isEmpty) return false;

    final path = Path()
      ..moveTo(handles.first.dx, handles.first.dy);
    for (var i = 1; i < handles.length; i++) {
      path.lineTo(handles[i].dx, handles[i].dy);
    }
    path.close();

    return path.contains(position);
  }
}

/// Simple blur overlay for displaying blur effects during playback (non-editable)
class SimpleBlurOverlay extends StatelessWidget {
  const SimpleBlurOverlay({
    required this.videoSize,
    super.key,
    this.boundingBox,
    this.intensity = 1.0,
  });

  final BoundingBox? boundingBox;
  final double intensity;
  final Size videoSize;

  @override
  Widget build(BuildContext context) {
    final box = boundingBox ?? const BoundingBox(left: 0, top: 0, width: 1, height: 1);
    
    final left = box.left * videoSize.width;
    final top = box.top * videoSize.height;
    final width = box.width * videoSize.width;
    final height = box.height * videoSize.height;

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 20 * intensity,
            sigmaY: 20 * intensity,
          ),
          child: Container(
            color: Colors.transparent,
          ),
        ),
      ),
    );
  }
}
