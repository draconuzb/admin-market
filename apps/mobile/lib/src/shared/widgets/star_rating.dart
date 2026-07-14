import 'package:flutter/material.dart';

const _amber = Color(0xFFFF9500);

/// Read-only star row for an average rating (supports half stars).
class StarRating extends StatelessWidget {
  const StarRating({super.key, required this.rating, this.size = 16});
  final num rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            rating >= i
                ? Icons.star_rounded
                : (rating >= i - 0.5 ? Icons.star_half_rounded : Icons.star_outline_rounded),
            size: size,
            color: _amber,
          ),
      ],
    );
  }
}

/// Interactive 1..5 star selector.
class StarInput extends StatelessWidget {
  const StarInput({super.key, required this.value, required this.onChanged, this.size = 40});
  final int value;
  final ValueChanged<int> onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 1; i <= 5; i++)
          GestureDetector(
            onTap: () => onChanged(i),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(
                value >= i ? Icons.star_rounded : Icons.star_outline_rounded,
                size: size,
                color: _amber,
              ),
            ),
          ),
      ],
    );
  }
}
