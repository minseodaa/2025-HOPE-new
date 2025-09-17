// ## 파일: lib/views/training_summary_screen.dart ##

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/constants.dart';
import '../models/expression_type.dart';
// TrainingRecordService 대신 TrainingApiService를 사용합니다.
import '../services/training_api_service.dart';
import 'training_log_screen.dart';
import 'package:collection/collection.dart'; // groupBy 사용을 위해 추가

class TrainingSummaryScreen extends StatefulWidget {
  const TrainingSummaryScreen({super.key});

  @override
  State<TrainingSummaryScreen> createState() => _TrainingSummaryScreenState();
}

class _TrainingSummaryScreenState extends State<TrainingSummaryScreen> {
  // TrainingRecordService 대신 TrainingApiService를 사용합니다.
  final TrainingApiService _apiService = TrainingApiService();

  // 서버에서 가져온 모든 기록 중에서 표정별 최고 점수를 계산하는 함수
  Map<ExpressionType, double> _calculateBestScores(List<dynamic> sessions) {
    final bestScores = <ExpressionType, double>{};

    // 1. 모든 표정 타입을 0점으로 초기화
    for (var type in ExpressionType.values) {
      bestScores[type] = 0.0;
    }

    // 2. 서버에서 받은 데이터를 순회하며 최고 점수 갱신
    for (final session in sessions) {
      if (session is! Map<String, dynamic>) continue;

      final exprString = session['expr'] as String?;
      // 점수는 0~1 범위로 계산
      final score = (session['finalScore'] as num?)?.toDouble();

      if (exprString == null || score == null) continue;

      final type = ExpressionType.values.firstWhereOrNull((e) => e.name == exprString);

      if (type != null) {
        final currentBest = bestScores[type] ?? 0.0;
        if (score > currentBest) {
          bestScores[type] = score; // 더 높은 점수가 나오면 갱신
        }
      }
    }
    return bestScores;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('훈련 기록', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        centerTitle: true,
      ),
      // FutureBuilder가 이제 서버에서 직접 데이터를 가져옵니다.
      body: FutureBuilder<Map<String, dynamic>>(
        future: _apiService.fetchSessions(pageSize: 100), // 모든 기록을 가져옴
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('기록을 불러올 수 없습니다.'));
          }

          final sessions = snapshot.data!['sessions'] as List<dynamic>;
          // 받아온 데이터로 표정별 최고 점수 계산
          final bestScores = _calculateBestScores(sessions);

          if (sessions.isEmpty) {
            return const Center(child: Text('저장된 기록이 없습니다.'));
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Column(
                children: [
                  _buildOverallAverageCard(_calculateOverallAverage(bestScores)),
                  const SizedBox(height: AppSizes.lg),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      const crossAxisCount = 2;
                      const spacing = AppSizes.md;
                      final totalSpacing = spacing * (crossAxisCount - 1);
                      final itemWidth =
                          (constraints.maxWidth - totalSpacing) / crossAxisCount;
                      const desiredItemHeight = 250.0;
                      final ratio = itemWidth / desiredItemHeight;

                      return GridView.count(
                        crossAxisCount: crossAxisCount,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: spacing,
                        mainAxisSpacing: spacing,
                        childAspectRatio: ratio,
                        children: ExpressionType.values.map((type) {
                          // 계산된 최고 점수를 카드에 전달
                          return _buildExpressionCard(
                            context,
                            type,
                            bestScores[type],
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  double _calculateOverallAverage(Map<ExpressionType, double> scores) {
    if (scores.isEmpty) return 0.0;
    final validScores = scores.values.where((score) => score > 0);
    if (validScores.isEmpty) return 0.0;
    final total = validScores.reduce((a, b) => a + b);
    return (total / validScores.length) * 100.0;
  }

  Widget _buildOverallAverageCard(double averageScore) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('최고 기록 평균 (%)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            Text(
              '${averageScore.round()}%',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            // 초기화 버튼은 서버 API 없이는 구현이 어려워 잠시 비활성화
            // TextButton(onPressed: () {}, child: const Text('초기화')),
          ],
        ),
      ),
    );
  }

  Widget _buildExpressionCard(
      BuildContext context, ExpressionType type, double? score) {
    // score는 0~1.0 범위의 값이므로 %로 변환
    final display = score != null ? (score * 100).round() : null;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.sm),
        child: Column(
          children: [
            SizedBox(
              height: 110,
              width: double.infinity,
              child: Container(
                color: Colors.grey[200],
                alignment: Alignment.center,
                child: Text(_getExpressionEmoji(type),
                    style: const TextStyle(fontSize: 44)),
              ),
            ),
            const SizedBox(height: 8),
            Text(_getExpressionName(type),
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('진척도: ${display != null ? '$display%' : 'N/A'}'),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  minimumSize: const Size.fromHeight(38),
                ),
                onPressed: () => Get.to(() => TrainingLogScreen(expressionType: type)),
                child: const Text('기록 보기'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getExpressionName(ExpressionType type) {
    switch (type) {
      case ExpressionType.smile:
        return '웃는 표정';
      case ExpressionType.sad:
        return '슬픈 표정';
      case ExpressionType.angry:
        return '화난 표정';
      case ExpressionType.neutral:
        return '무표정';
    }
  }

  String _getExpressionEmoji(ExpressionType type) {
    switch (type) {
      case ExpressionType.smile:
        return '😊';
      case ExpressionType.sad:
        return '😢';
      case ExpressionType.angry:
        return '😠';
      case ExpressionType.neutral:
        return '😐';
    }
  }
}