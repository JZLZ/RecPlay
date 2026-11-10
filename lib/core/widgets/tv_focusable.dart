import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class TvFocusable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final ValueChanged<bool>? onFocusChange;
  final FocusNode? focusNode;
  final bool autofocus;
  final BorderRadius borderRadius;
  final double scaleFactor;
  final EdgeInsets padding;
  final Color? glowColor;
  final Color? focusedBorderColor;

  const TvFocusable({
    super.key,
    required this.child,
    this.onPressed,
    this.onFocusChange,
    this.focusNode,
    this.autofocus = false,
    this.borderRadius = const BorderRadius.all(Radius.circular(10)),
    this.scaleFactor = 1.06,
    this.padding = EdgeInsets.zero,
    this.glowColor,
    this.focusedBorderColor,
  });

  @override
  State<TvFocusable> createState() => _TvFocusableState();
}

class _TvFocusableState extends State<TvFocusable> {
  late FocusNode _node;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _node = widget.focusNode ?? FocusNode();
    _node.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (mounted) {
      final hasFocus = _node.hasFocus;
      if (_isFocused != hasFocus) {
        setState(() {
          _isFocused = hasFocus;
        });
        widget.onFocusChange?.call(hasFocus);
      }
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _node.dispose();
    } else {
      _node.removeListener(_handleFocusChange);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveGlowColor = widget.glowColor ?? AppTheme.cyan;
    final effectiveBorderColor = widget.focusedBorderColor ?? AppTheme.cyan;

    return Padding(
      padding: widget.padding,
      child: FocusableActionDetector(
        focusNode: _node,
        autofocus: widget.autofocus,
        onShowFocusHighlight: (show) {
          if (_isFocused != show) {
            setState(() {
              _isFocused = show;
            });
            widget.onFocusChange?.call(show);
          }
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onPressed?.call();
              return null;
            },
          ),
        },
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.select): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.gameButtonA): ActivateIntent(),
        },
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedScale(
            scale: _isFocused ? widget.scaleFactor : 1.0,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                borderRadius: widget.borderRadius,
                border: Border.all(
                  color: _isFocused ? effectiveBorderColor : Colors.transparent,
                  width: _isFocused ? 2.0 : 0.0,
                ),
                boxShadow: _isFocused
                    ? [
                        BoxShadow(
                          color: effectiveGlowColor.withOpacity(0.35),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
