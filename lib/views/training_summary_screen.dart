// ## 파일: lib/views/training_summary_screen.dart ##

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../utils/constants.dart';
import '../models/expression_type.dart';
import '../services/training_api_service.dart';
import '../services/training_record_service.dart';
import 'training_log_screen.dart';

class TrainingSummaryScreen extends StatefulWidget {
  const TrainingSummaryScreen({super.key});
  @override
  State<TrainingSummaryScreen> createState() => _TrainingSummaryScreenState();
}

class _TrainingSummaryScreenState extends State<TrainingSummaryScreen> {
  final TrainingApiService _apiService = TrainingApiService();
  final TrainingRecordService _recordService = TrainingRecordService();
  late final Future<Map<ExpressionType, double>> _personalBestScoresFuture;

  @override
  void initState() {
    super.initState();
    _personalBestScoresFuture = _fetchAndCalculatePersonalBestScores();
  }

  Future<Map<ExpressionType, double>> _fetchAndCalculatePersonalBestScores() async {
    final results = await Future.wait([
      _apiService.fetchInitialScores(),
      _apiService.fetchSessions(pageSize: 1000),
    ]);

    final initialScoresData = results[0];
    final trainingSessionsData = results[1];

    final personalBest = <ExpressionType, double>{};
    final initialExpressionScores = initialScoresData['expressionScores'] as Map<String, dynamic>? ?? {};

    for (var type in ExpressionType.values) {
      final score = (initialExpressionScores[type.name] as num?)?.toDouble() ?? 0.0;
      personalBest[type] = score / 100.0;
    }

    final sessions = trainingSessionsData['sessions'] as List<dynamic>;
    for (final session in sessions) {
      if (session is! Map<String, dynamic>) continue;

      final exprString = session['expr'] as String?;
      var score = (session['finalScore'] as num?)?.toDouble();

      if (exprString == null || score == null) continue;

      if (score > 1.0) {
        score = score / 100.0;
      }

      final type = ExpressionType.values.firstWhereOrNull((e) => e.name == exprString);

      if (type != null) {
        final currentBest = personalBest[type] ?? 0.0;
        if (score > currentBest) {
          personalBest[type] = score;
        }
      }
    }
    return personalBest;
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
      body: FutureBuilder<Map<ExpressionType, double>>(
        future: _personalBestScoresFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('기록을 불러올 수 없습니다: ${snapshot.error}'));
          }

          final bestScores = snapshot.data ?? {};
          if (bestScores.values.every((score) => score == 0.0)) {
            return const Center(child: Text('저장된 기록이 없습니다.'));
          }

          // 1. 버튼 표시 조건: 모든 표정의 최고 기록이 100% (1.0) 이상인지 확인
          final bool isAllCompleted = bestScores.values.every((score) => score >= 1.0);

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
                      final itemWidth = (constraints.maxWidth - totalSpacing) / crossAxisCount;
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
                          return _buildExpressionCard(
                            context,
                            type,
                            bestScores[type],
                          );
                        }).toList(),
                      );
                    },
                  ),

                  // 2. 초기화 버튼 추가: 조건이 만족되면 화면에 버튼 표시
                  if (isAllCompleted)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSizes.xl),
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text(
                            '새로운 목표 설정하기 (초기화)',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () async {
                            // 3. 버튼 동작: 데이터 초기화 후 초기 측정 화면으로 이동
                            await _recordService.resetAllProgress();
                            Get.offAllNamed('/initial-expression');
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
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
            const Text('전체 진척도 평균',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            Text(
              '${averageScore.round()}%',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpressionCard(
      BuildContext context, ExpressionType type, double? score) {
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