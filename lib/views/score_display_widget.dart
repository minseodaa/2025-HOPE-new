import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../utils/constants.dart';

class ScoreDisplayWidget extends StatelessWidget {
  final double score;
  final bool isTraining;
  final String? label; // 기본: '진척도'
  final bool neutralMode; // 무표정 전용 메시지/색상 유지 여부

  const ScoreDisplayWidget({
    super.key,
    required this.score,
    required this.isTraining,
    this.label,
    this.neutralMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (score * 100).round();
    final color = _getScoreColor(score);
    final message = _getScoreMessage(score);

    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.textTertiary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 점수 라벨
          Text(
            label ?? '진척도',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: AppSizes.md),

          // 점수 원형 프로그레스
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 배경 원
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 8,
                    backgroundColor: AppColors.textTertiary.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),

                // 점수 원
                SizedBox(
                      width: 120,
                      height: 120,
                      child: CircularProgressIndicator(
                        value: score,
                        strokeWidth: 8,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    )
                    .animate(target: isTraining ? 1 : 0)
                    .scale(
                      duration: AppAnimations.normal,
                      curve: Curves.easeInOut,
                    ),

                // 점수 텍스트
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$percentage%',
                      style: TextStyle(
                        color: color,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${score.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSizes.md),

          // 점수 메시지
          Text(
                message,
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              )
              .animate(target: isTraining ? 1 : 0)
              .fadeIn(duration: AppAnimations.normal)
              .slideY(begin: 0.3, duration: AppAnimations.normal),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 0.9) {
      return AppColors.success;
    } else if (score >= 0.8) {
      return Color(0xFF22C55E); // 밝은 초록
    } else if (score >= 0.7) {
      return AppColors.success;
    } else if (score >= 0.6) {
      return AppColors.accent;
    } else if (score >= 0.5) {
      return Color(0xFFF97316); // 주황
    } else if (score >= 0.4) {
      return AppColors.warning;
    } else if (score >= 0.2) {
      return Color(0xFFDC2626); // 빨강
    } else {
      return AppColors.error;
    }
  }

  String _getScoreMessage(double score) {
    if (neutralMode) {
      // 무표정 전용 문구
      if (score >= 0.9) return '완벽한 무표정 유지! 🎯';
      if (score >= 0.8) return '아주 안정적이에요! 👍';
      if (score >= 0.7) return '좋아요, 그대로 유지하세요.';
      if (score >= 0.6) return '살짝 힘을 빼고 안정적으로.';
      if (score >= 0.5) return '조금만 더 힘을 빼볼까요?';
      if (score >= 0.4) return '입 주변 움직임을 줄여보세요.';
      if (score >= 0.2) return '표정 근육의 긴장을 풀어보세요.';
      return '호흡을 고르고 힘을 천천히 빼보세요.';
    }

    // 기존(미소) 문구
    if (score >= 0.9) {
      return '완벽한 미소! 🎉';
    } else if (score >= 0.8) {
      return '거의 완벽해요! 🌟';
    } else if (score >= 0.7) {
      return '훌륭한 미소! ✨';
    } else if (score >= 0.6) {
      return '좋은 미소예요! 😊';
    } else if (score >= 0.5) {
      return '괜찮은 미소! 🙂';
    } else if (score >= 0.4) {
      return '조금 더 웃어보세요! 😄';
    } else if (score >= 0.2) {
      return '더 밝게 웃어보세요! 😃';
    } else {
      return '미소를 연습해보세요! 😌';
    }
  }
}
