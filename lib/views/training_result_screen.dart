import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../models/expression_type.dart';
import '../models/training_record.dart';
import '../services/training_record_service.dart';

class TrainingResultScreen extends StatelessWidget {
  final ExpressionType expressionType;
  final double finalScore;
  final int totalSets;

  const TrainingResultScreen({
    super.key,
    required this.expressionType,
    required this.finalScore,
    this.totalSets = 3,
  });

  String _title() {
    switch (expressionType) {
      case ExpressionType.smile:
        return '미소 훈련 결과';
      case ExpressionType.sad:
        return '슬픈 표정 훈련 결과';
      case ExpressionType.angry:
        return '화난 표정 훈련 결과';
      case ExpressionType.neutral:
        return '무표정 훈련 결과';
    }
  }

  @override
  Widget build(BuildContext context) {
    final percentage = (finalScore * 100).round();
    final Color color = finalScore >= 0.8
        ? AppColors.success
        : (finalScore >= 0.6 ? AppColors.accent : AppColors.error);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _title(),
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.surface,
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: AppSizes.xl),
            Text(
              '총 세트: $totalSets',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSizes.lg),
            // 진척도(결과) - score_display_widget과 동일한 축소 디자인 적용
            const Text('진척도', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: finalScore.clamp(0.0, 1.0),
                    strokeWidth: 6,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                Text(
                  '$percentage%',
                  style: TextStyle(fontSize: 20, color: color),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.xl),
            Text(
              '훈련을 완료했어요! 수고하셨습니다.',
              style: const TextStyle(
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.md),
            FutureBuilder(
              future: TrainingRecordService().add(
                TrainingRecord(
                  timestamp: DateTime.now(),
                  expressionType: expressionType,
                  score: finalScore,
                ),
              ),
              builder: (context, snapshot) {
                return const SizedBox.shrink();
              },
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text('확인'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
