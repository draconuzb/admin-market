import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/theme.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

class EmptyView extends StatelessWidget {
  const EmptyView({super.key, this.message, this.icon = Icons.inbox_outlined});
  final String? message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F7),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: AppTheme.textTertiary),
          ),
          const SizedBox(height: 16),
          Text(message ?? 'common.empty'.tr(),
              style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 15,
              )),
        ],
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.danger.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.wifi_off_rounded, size: 32, color: AppTheme.danger),
            ),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text('common.retry'.tr()),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shimmer-animated list skeleton.
class ListSkeleton extends StatelessWidget {
  const ListSkeleton({super.key, this.count = 6});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE5E5EA),
      highlightColor: const Color(0xFFF2F2F7),
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => Container(
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

/// Shimmer-animated grid skeleton for product grids.
class GridSkeleton extends StatelessWidget {
  const GridSkeleton({super.key, this.count = 4});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE5E5EA),
      highlightColor: const Color(0xFFF2F2F7),
      child: GridView.count(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        padding: const EdgeInsets.all(20),
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        children: List.generate(
          count,
          (_) => Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
    );
  }
}
