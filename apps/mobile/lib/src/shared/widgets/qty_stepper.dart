import 'package:flutter/material.dart';

/// Quantity stepper that clamps between [min] (min order qty) and [max] (stock).
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
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: canDec ? () => onChanged(value - 1) : null,
            visualDensity: VisualDensity.compact,
          ),
          Text('$value', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: canInc ? () => onChanged(value + 1) : null,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
