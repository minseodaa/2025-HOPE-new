import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// 초기 표정 기록(요약) 화면 - Placeholder
/// 백엔드 연동 전까지 결과 요약 및 다음 단계 버튼만 제공
class InitialExpressionResultScreen extends StatelessWidget {
  const InitialExpressionResultScreen({super.key});

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
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: const Text(
                  '요약 차트/리스트 영역 (추후 연동)',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            SizedBox(
              height: 56,
              child: FilledButton(
                onPressed: () {
                  // 홈의 훈련모드(캘린더 있는 카드)를 보여주는 첫 화면으로 이동
                  Navigator.of(context).popUntil((r) => r.isFirst);
                },
                child: const Text('훈련하러 가기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
