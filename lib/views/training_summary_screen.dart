import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/constants.dart';
import '../models/expression_type.dart';
import '../models/training_record.dart';
import '../services/training_record_service.dart';
import 'training_log_screen.dart';

class TrainingSummaryScreen extends StatefulWidget {
  const TrainingSummaryScreen({super.key});

  @override
  State<TrainingSummaryScreen> createState() => _TrainingSummaryScreenState();
}

class _TrainingSummaryScreenState extends State<TrainingSummaryScreen> {
  final TrainingRecordService _recordService = TrainingRecordService();

  // 점수 정규화: 0~1 → 0~100, 이미 0~100이면 그대로
  double _normalizeTo100(double raw) {
    if (raw.isNaN) return 0;
    return raw <= 1.0 ? (raw * 100.0) : raw;
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
      body: FutureBuilder<Map<ExpressionType, TrainingRecord?>>(
        future: _recordService.getLatestRecordForEachType(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('저장된 기록이 없습니다.'));
          }
          final latestRecords = snapshot.data!;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Column(
                children: [
                  _buildOverallAverageCard(_calculateOverallAverage(latestRecords)),
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
                          return _buildExpressionCard(
                            context,
                            type,
                            latestRecords[type],
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

  double _calculateOverallAverage(
      Map<ExpressionType, TrainingRecord?> latestRecords) {
    double total = 0;
    for (var type in ExpressionType.values) {
      final s = latestRecords[type]?.score ?? 0;
      total += _normalizeTo100(s);
    }
    return total / ExpressionType.values.length; // 이미 0~100 스케일 평균
  }

  Widget _buildOverallAverageCard(double averageScore) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('전체 진척도의 평균 (%)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            Text(
              '${averageScore.round()}%', // 이미 0~100 값
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            TextButton(
              onPressed: () async {
                await _recordService.clearAll();
                setState(() {});
              },
              child: const Text('초기화'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpressionCard(
      BuildContext context, ExpressionType type, TrainingRecord? record) {
    final display = record != null ? _normalizeTo100(record.score).round() : null;

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
