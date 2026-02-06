import 'package:in_app_review/in_app_review.dart';

class ReviewService {
  static final InAppReview _inAppReview = InAppReview.instance;

  static Future<void> requestReviewIfAvailable() async {
    if (await _inAppReview.isAvailable()) {
      await _inAppReview.requestReview();
    }
  }
}
