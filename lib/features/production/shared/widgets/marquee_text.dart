import 'package:flutter/material.dart';

/// Single-line scrolling text. Scrolls only when text overflows the available
/// width; otherwise renders as a plain static Text.
class MarqueeText extends StatefulWidget {
  const MarqueeText(
    this.text, {
    super.key,
    this.style,
    this.velocity = 28.0,
    this.pauseDuration = const Duration(seconds: 2),
    this.gap = 40.0,
  });

  final String text;
  final TextStyle? style;

  /// Pixels per second.
  final double velocity;

  /// How long to wait at start before scrolling begins (and after each loop).
  final Duration pauseDuration;

  /// Gap between the end of text and the repeated copy.
  final double gap;

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText>
    with SingleTickerProviderStateMixin {
  late ScrollController _scroll;
  bool _needsScroll = false;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _scroll = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  void didUpdateWidget(MarqueeText old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) {
      _scroll.jumpTo(0);
      WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    }
  }

  void _measure() {
    if (_disposed || !mounted) return;
    final pos = _scroll.position;
    final overflows = pos.maxScrollExtent > 0;
    if (overflows != _needsScroll) {
      setState(() => _needsScroll = overflows);
    }
    if (overflows) _startLoop();
  }

  Future<void> _startLoop() async {
    while (!_disposed && mounted && _needsScroll) {
      await Future<void>.delayed(widget.pauseDuration);
      if (_disposed || !mounted) return;
      final max = _scroll.position.maxScrollExtent;
      if (max <= 0) return;
      await _scroll.animateTo(
        max,
        duration: Duration(milliseconds: (max / widget.velocity * 1000).round()),
        curve: Curves.linear,
      );
      if (_disposed || !mounted) return;
      await Future<void>.delayed(widget.pauseDuration);
      if (_disposed || !mounted) return;
      _scroll.jumpTo(0);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textWidget = Text(
      widget.text,
      style: widget.style,
      maxLines: 1,
      softWrap: false,
    );

    if (!_needsScroll) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: _scroll,
        physics: const NeverScrollableScrollPhysics(),
        child: textWidget,
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      controller: _scroll,
      physics: const NeverScrollableScrollPhysics(),
      child: Row(
        children: [
          textWidget,
          SizedBox(width: widget.gap),
          textWidget,
        ],
      ),
    );
  }
}
