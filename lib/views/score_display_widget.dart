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
    if (score >= 0.8) return AppColors.success;
    if (score >= 0.6) return AppColors.accent;
    return AppColors.error;
  }

  String _getScoreMessage(double score, ExpressionType type) {
    // ## angry와 neutral 메시지 추가 ##
    switch (type) {
      case ExpressionType.smile:
        if (score >= 0.8) return '완벽한 미소! 🎉';
        return '조금 더 웃어보세요!';
      case ExpressionType.sad:
        if (score >= 0.8) return '슬픔이 느껴져요 😢';
        return '입꼬리를 더 내려보세요';
      case ExpressionType.angry:
        if (score >= 0.8) return '분노가 느껴집니다! 😠';
        return '눈을 더 가늘게 떠보세요';
      case ExpressionType.neutral:
        if (score >= 0.8) return '완벽한 무표정! 👍';
        return '표정 변화 없이 유지하세요';
    }
  }
}