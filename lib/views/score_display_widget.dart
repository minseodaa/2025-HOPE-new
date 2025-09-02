import 'package:flutter/material.dart';
import '../models/expression_type.dart';
import '../utils/constants.dart';

class ScoreDisplayWidget extends StatelessWidget {
  final double score;
  final bool isTraining;
  final ExpressionType expressionType;

  const ScoreDisplayWidget({
    super.key,
    required this.score,
    required this.isTraining,
    required this.expressionType,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (score * 100).round();
    final color = _getScoreColor(score);
    final message = _getScoreMessage(score, expressionType);

    return Column(
      children: [
        Text('진척도', style: TextStyle(fontSize: 16)),
        SizedBox(height: 8),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: CircularProgressIndicator(
                value: score,
                strokeWidth: 8,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            Text('$percentage%', style: TextStyle(fontSize: 24, color: color)),
          ],
        ),
        SizedBox(height: 8),
        Text(message, style: TextStyle(fontSize: 18, color: color)),
      ],
    );
  }

  Color _getScoreColor(double score) {
    if (score >= AppConstants.highScoreThreshold) return AppColors.success;
    if (score >= AppConstants.mediumScoreThreshold) return AppColors.accent;
    return AppColors.error;
  }

  // ## 수정: 피드백 메시지를 점수대별로 세분화 ##
  String _getScoreMessage(double score, ExpressionType type) {
    final level = (score >= AppConstants.highScoreThreshold)
        ? 'high'
        : (score >= AppConstants.mediumScoreThreshold)
        ? 'medium'
        : 'low';

    switch (type) {
      case ExpressionType.smile:
        if (level == 'high') return '완벽한 미소예요! 😁';
        if (level == 'medium') return '좋아요! 조금 더 활짝! 😊';
        return '입꼬리를 올려보세요! 😐';
      case ExpressionType.sad:
        if (level == 'high') return '슬픔이 잘 표현됐어요 😢';
        if (level == 'medium') return '좋아요! 감정을 더 실어봐요';
        return '입꼬리를 더 내려보세요';
      case ExpressionType.angry:
        if (level == 'high') return '분노가 느껴져요! 😠';
        if (level == 'medium') return '좋아요! 눈썹에 힘을! 😡';
        return '미간을 찌푸려보세요';
      case ExpressionType.neutral:
        if (level == 'high') return '완벽한 무표정입니다 👍';
        if (level == 'medium') return '좋아요! 조금만 더 유지!';
        return '표정 변화 없이 유지하세요';
    }
  }
}