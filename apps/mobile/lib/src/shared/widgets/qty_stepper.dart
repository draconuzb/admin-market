import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// iOS-style quantity stepper with pill shape.
class QtyStepper extends StatelessWidget {
  const QtyStepper({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final canDec = value > min;
    final canInc = value < max;
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _button(Icons.remove, canDec, () => onChanged(value - 1)),
          Container(
            constraints: const BoxConstraints(minWidth: 40),
            alignment: Alignment.center,
            child: Text('$value',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          ),
          _button(Icons.add, canInc, () => onChanged(value + 1)),
        ],
      ),
    );
  }

  Widget _button(IconData icon, bool enabled, VoidCallback onTap) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36, height: 36,
        alignment: Alignment.center,
        child: Icon(
          icon, size: 18,
          color: enabled ? AppTheme.accent : AppTheme.textTertiary,
        ),
      ),
    );
  }
}
