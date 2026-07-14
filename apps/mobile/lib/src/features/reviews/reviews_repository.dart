import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/dio_client.dart';
import '../../models/page.dart';
import '../../providers.dart';

class Review {
  Review({
    required this.id,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });
  final int id;
  final String userName;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  factory Review.fromJson(Map<String, dynamic> j) => Review(
        id: j['id'] as int,
        userName: j['user_name'] as String,
        rating: j['rating'] as int,
        comment: j['comment'] as String?,
        createdAt: DateTime.tryParse(j['created_at']?.toString() ?? '') ?? DateTime.now(),
      );
}

class ReviewsRepository {
  ReviewsRepository(this._api);
  final ApiClient _api;

  Future<Paged<Review>> list(int productId, {int page = 1}) async {
    final resp = await _api.get('/products/$productId/reviews', query: {'page': page});
    return Paged.fromJson(resp.data as Map<String, dynamic>, Review.fromJson);
  }

  Future<void> submit(int productId, int rating, String? comment) {
    return _api.post('/products/$productId/reviews',
        data: {'rating': rating, if (comment != null && comment.isNotEmpty) 'comment': comment});
  }
}

final reviewsRepositoryProvider = Provider<ReviewsRepository>(
  (ref) => ReviewsRepository(ref.watch(apiClientProvider)),
);

final productReviewsProvider =
    FutureProvider.family<Paged<Review>, int>((ref, productId) {
  return ref.watch(reviewsRepositoryProvider).list(productId);
});
