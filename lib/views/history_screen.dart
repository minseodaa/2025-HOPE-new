import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../models/training_record.dart';
import '../services/training_record_service.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('훈련 기록'),
        backgroundColor: AppColors.surface,
        centerTitle: true,
      ),
      body: FutureBuilder<List<TrainingRecord>>(
        future: TrainingRecordService().getAllRecords(),
        initialData: const <TrainingRecord>[],
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                '기록을 불러오지 못했습니다',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }
          final list = snapshot.data ?? const <TrainingRecord>[];
          if (list.isEmpty) {
            return const Center(
              child: Text(
                '기록이 없습니다',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }
          // 날짜 내림차순 정렬
          final sorted = List<TrainingRecord>.from(list)
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

          return ListView.separated(
            padding: const EdgeInsets.all(AppSizes.md),
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final r = sorted[i];
              final pct = (r.score * 100).round();
              return ListTile(
                title: Text(
                  '${r.dateKey}  •  ${r.expressionType.name}',
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
                subtitle: Text(
                  '점수: $pct%',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              );
            },
          );
        },
      ),
    );
  }
}