import 'package:flutter/material.dart';

/// A tappable surface with a pressed state, standing in for the prototype's
/// styled `<button>` elements (which use hover colours on the web).
///
/// If [pressedColor] is null the whole surface dims while pressed instead.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.color,
    this.pressedColor,
    this.borderRadius,
    this.border,
    this.boxShadow,
    this.height,
    this.width,
    this.padding,
    this.alignment,
    this.semanticLabel,
    this.excludeSemantics = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color? color;
  final Color? pressedColor;
  final BorderRadiusGeometry? borderRadius;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;
  final double? height;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry? alignment;
  final String? semanticLabel;
  final bool excludeSemantics;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  void _set(bool v) {
    if (widget.onTap == null || _pressed == v) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final dimWhenPressed = widget.pressedColor == null;
    final bg = _pressed && !dimWhenPressed ? widget.pressedColor : widget.color;
    // Align (rather than Container.alignment) so a surface without an explicit
    // width hugs its content instead of stretching to the available width.
    final alignment = widget.alignment;
    final content = alignment == null
        ? widget.child
        : Align(
            alignment: alignment,
            widthFactor: widget.width == null ? 1 : null,
            heightFactor: widget.height == null ? 1 : null,
            child: widget.child,
          );
    Widget box = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      height: widget.height,
      width: widget.width,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: widget.borderRadius,
        border: widget.border,
        boxShadow: widget.boxShadow,
      ),
      child: content,
    );
    if (dimWhenPressed) {
      box = AnimatedOpacity(
        opacity: _pressed ? 0.6 : 1,
        duration: const Duration(milliseconds: 120),
        child: box,
      );
    }
    return Semantics(
      button: true,
      enabled: widget.onTap != null,
      label: widget.semanticLabel,
      excludeSemantics: widget.excludeSemantics,
      child: MouseRegion(
        cursor: widget.onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          onTapDown: (_) => _set(true),
          onTapUp: (_) => _set(false),
          onTapCancel: () => _set(false),
          child: box,
        ),
      ),
    );
  }
}
