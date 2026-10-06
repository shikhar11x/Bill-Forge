import 'dart:async';

import 'package:flutter/material.dart';

class AppSearchField extends StatefulWidget {
  const AppSearchField({
    required this.controller,
    required this.onChanged,
    this.hint = 'Search',
    this.debounce = const Duration(milliseconds: 300),
    super.key,
  });

  final TextEditingController controller;

  /// Called once the user pauses typing (debounced), or immediately on clear.
  final ValueChanged<String> onChanged;
  final String hint;
  final Duration debounce;

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _handleChanged(String value) {
    _timer?.cancel();
    _timer = Timer(widget.debounce, () => widget.onChanged(value));
  }

  void _clear() {
    _timer?.cancel();
    widget.controller.clear();
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) => TextField(
        controller: widget.controller,
        onChanged: _handleChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: widget.hint,
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          suffixIcon: widget.controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: _clear,
                ),
        ),
      ),
    );
  }
}
