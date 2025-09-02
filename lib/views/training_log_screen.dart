import 'package:flutter/material.dart';
import '../utils/constants.dart';

class TrainingLogScreen extends StatelessWidget {
  const TrainingLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          '훈련 기록',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOverallAverageCard(78), // 전체 평균 진척도 (예시 데이터)
              const SizedBox(height: AppSizes.xl),
              Row(
                children: [
                  Expanded(
                    child: _buildExpressionCard(
                      context,
                      title: '웃는 표정',
                      iconData: Icons.sentiment_satisfied_alt,
                      color: AppColors.accent,
                      progress: 85, // 예시 데이터
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: _buildExpressionCard(
                      context,
                      title: '화난 표정',
                      iconData: Icons.sentiment_very_dissatisfied,
                      color: AppColors.error,
                      progress: 62, // 예시 데이터
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.md),
              Row(
                children: [
                  Expanded(
                    child: _buildExpressionCard(
                      context,
                      title: '슬픈 표정',
                      iconData: Icons.sentiment_dissatisfied,
                      color: AppColors.secondary,
                      progress: 78, // 예시 데이터
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: _buildExpressionCard(
                      context,
                      title: '무표정',
                      iconData: Icons.sentiment_neutral,
                      color: AppColors.textSecondary,
                      progress: 95, // 예시 데이터
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 전체 진척도 평균을 표시하는 카드 위젯
  Widget _buildOverallAverageCard(int averageProgress) {
    return Card(
      elevation: 2.0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg, vertical: AppSizes.md),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '전체 진척도의 평균',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                TextButton(
                  onPressed: () { /* 초기화 로직 (나중에 구현) */ },
                  child: const Text('초기화'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    backgroundColor: AppColors.background,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              '$averageProgress%',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 각 표정별 기록을 표시하는 카드 위젯
  Widget _buildExpressionCard(
      BuildContext context, {
        required String title,
        required IconData iconData,
        required Color color,
        required int progress,
      }) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      clipBehavior: Clip.antiAlias, // Card의 자식 위젯이 Card의 모양을 따르도록 함
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 가장 최근 훈련 사진 (현재는 아이콘으로 대체)
          AspectRatio(
            aspectRatio: 1.0, // 1:1 비율
            child: Container(
              color: color.withOpacity(0.1),
              child: Icon(iconData, size: 60, color: color),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppSizes.sm),
                // 진척도 표시
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: AppSizes.xs),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                      children: [
                        const TextSpan(text: '최근 진척도: '),
                        TextSpan(
                          text: '$progress%',
                          style: TextStyle(fontWeight: FontWeight.bold, color: color),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.md),
                // 기록 보기 버튼
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () { /* '훈련 기록 상세' 페이지로 이동 (나중에 구현) */ },
                    child: const Text('기록 보기'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.surface,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}