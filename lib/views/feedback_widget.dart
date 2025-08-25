import 'package:flutter/material.dart';
import '../models/expression_type.dart';
import '../utils/constants.dart';

class FeedbackWidget extends StatelessWidget {
  final bool isFaceDetected;
  final double score;
  final bool isTraining;
  final ExpressionType expressionType;

  const FeedbackWidget({
    super.key,
    required this.isFaceDetected,
    required this.score,
    required this.isTraining,
    required this.expressionType,
  });

  @override
  Widget build(BuildContext context) {
    if (!isTraining) return const SizedBox.shrink();
    if (!isFaceDetected) return const Text('얼굴이 감지되지 않았습니다.');

    return Text(
      _getFeedbackMessage(score, expressionType),
      style: TextStyle(color: _getFeedbackColor(score)),
    );
  }

  Color _getFeedbackColor(double score) {
    if (score >= 0.8) return AppColors.success;
    if (score >= 0.6) return AppColors.accent;
    return AppColors.error;
  }

  String _getFeedbackMessage(double score, ExpressionType type) {
    // ## angry와 neutral 메시지 추가 ##
    switch (type) {
      case ExpressionType.smile:
        if (score >= 0.8) return '최고예요!';
        return '더 활짝 웃어보세요!';
      case ExpressionType.sad:
        if (score >= 0.8) return '감정 전달이 잘 돼요.';
        return '조금 더 슬픈 표정을 지어보세요.';
      case ExpressionType.angry:
        if (score >= 0.8) return '카리스마 있어요!';
        return '눈에 힘을 주고, 미간을 찌푸려보세요.';
      case ExpressionType.neutral:
        if (score >= 0.8) return '평온한 상태입니다.';
        return '표정 변화를 최소화하세요.';
    }
  }
}