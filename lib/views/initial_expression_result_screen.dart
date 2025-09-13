import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/constants.dart';
import '../utils/score_converter.dart';
import '../models/expression_type.dart';

/// 초기 표정 기록(요약) 화면
/// 측정된 표정 점수를 차트로 표시하고 다음 단계로 안내
class InitialExpressionResultScreen extends StatelessWidget {
  final Map<ExpressionType, double> expressionScores;

  const InitialExpressionResultScreen({
    super.key,
    required this.expressionScores,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('초기 표정 기록'),
        centerTitle: true,
        backgroundColor: AppColors.surface,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSizes.xl),
            const Text(
              '초기 표정 기록',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSizes.xl),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(AppSizes.lg),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: _buildScoreChart(),
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            SizedBox(
              height: 56,
              child: FilledButton(
                onPressed: () {
                  // home_screen.dart로 이동
                  Get.offAllNamed('/home');
                },
                child: const Text('훈련하러 가기'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 표정 점수 차트 위젯 빌드
  Widget _buildScoreChart() {
    final expressions = [
      ExpressionType.neutral,
      ExpressionType.smile,
      ExpressionType.angry,
      ExpressionType.sad,
    ];

    return Column(
      children: [
        // 차트 제목
        const Text(
          '초기 표정 강도 측정 결과',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSizes.lg),

        // 차트 영역
        Expanded(
          child: Column(
            children: expressions.map((expression) {
              final score = expressionScores[expression] ?? 0.0;
              final level = ScoreConverter.getScoreLevel(score);
              final color = ScoreConverter.getScoreColor(score);

              return _buildScoreBar(
                expression: expression,
                score: score,
                level: level,
                color: color,
              );
            }).toList(),
          ),
        ),

        // 범례
        _buildLegend(),
      ],
    );
  }

  /// 개별 점수 바 위젯 빌드
  Widget _buildScoreBar({
    required ExpressionType expression,
    required double score,
    required String level,
    required int color,
  }) {
    final expressionName = _getExpressionName(expression);
    final barWidth = (score / 5.0) * 0.8; // 최대 80% 너비

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
      child: Row(
        children: [
          // 표정 이름
          SizedBox(
            width: 80,
            child: Text(
              expressionName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),

          const SizedBox(width: AppSizes.sm),

          // 점수 바
          Expanded(
            child: Container(
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Stack(
                children: [
                  // 배경
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),

                  // 점수 바
                  FractionallySizedBox(
                    widthFactor: barWidth,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color(color),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  // 점수 텍스트
                  Center(
                    child: Text(
                      score.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: AppSizes.sm),

          // 레벨 텍스트
          SizedBox(
            width: 60,
            child: Text(
              level,
              style: TextStyle(
                fontSize: 12,
                color: Color(color),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  /// 범례 위젯 빌드
  Widget _buildLegend() {
    return Container(
      margin: const EdgeInsets.only(top: AppSizes.lg),
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        children: [
          const Text(
            '점수 범위',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem('0-1', '매우 약함', 0xFF9E9E9E),
              _buildLegendItem('1-2', '약함', 0xFFE57373),
              _buildLegendItem('2-3', '보통', 0xFFFFB74D),
              _buildLegendItem('3-4', '강함', 0xFF81C784),
              _buildLegendItem('4-5', '매우 강함', 0xFF4CAF50),
            ],
          ),
        ],
      ),
    );
  }

  /// 범례 아이템 위젯 빌드
  Widget _buildLegendItem(String range, String label, int color) {
    return Column(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: Color(color),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          range,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  /// 표정 타입에 따른 한국어 이름 반환
  String _getExpressionName(ExpressionType expression) {
    switch (expression) {
      case ExpressionType.neutral:
        return '무표정';
      case ExpressionType.smile:
        return '웃는표정';
      case ExpressionType.angry:
        return '화난표정';
      case ExpressionType.sad:
        return '슬픈표정';
    }
  }
}
