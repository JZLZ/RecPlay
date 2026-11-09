import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TvFocusable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final FocusNode? focusNode;
  final bool autofocus;
  final BorderRadius borderRadius;
  final double scaleFactor;
  final EdgeInsets padding;

  const TvFocusable({
    super.key,
    required this.child,
    this.onPressed,
    this.focusNode,
    this.autofocus = false,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.scaleFactor = 1.06,
    this.padding = EdgeInsets.zero,
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
      setState(() {
        _isFocused = _node.hasFocus;
      });
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
    return Padding(
      padding: widget.padding,
      child: FocusableActionDetector(
        focusNode: _node,
        autofocus: widget.autofocus,
        onShowFocusHighlight: (show) {
          setState(() {
            _isFocused = show;
          });
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
                  color: _isFocused ? Colors.white : Colors.transparent,
                  width: _isFocused ? 2.5 : 0.0,
                ),
                boxShadow: _isFocused
                    ? [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                          blurRadius: 16,
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
