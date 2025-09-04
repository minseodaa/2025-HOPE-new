// ## 파일: lib/views/training_result_screen.dart ##

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/expression_type.dart';
import '../models/training_record.dart';
import '../services/training_record_service.dart';
import '../utils/constants.dart';
import 'training_log_screen.dart';

class TrainingResultScreen extends StatefulWidget {
  final ExpressionType expressionType;
  final double finalScore;

  const TrainingResultScreen({
    super.key,
    required this.expressionType,
    required this.finalScore,
  });

  @override
  State<TrainingResultScreen> createState() => _TrainingResultScreenState();
}

class _TrainingResultScreenState extends State<TrainingResultScreen> {
  final TrainingRecordService _recordService = TrainingRecordService();

  @override
  void initState() {
    super.initState();
    // 화면이 열릴 때 훈련 기록을 자동으로 저장합니다.
    _saveRecord();
  }

  Future<void> _saveRecord() async {
    await _recordService.addRecord(TrainingRecord(
      timestamp: DateTime.now(),
      expressionType: widget.expressionType,
      score: widget.finalScore,
    ));
  }

  String _getTitle() {
    switch (widget.expressionType) {
      case ExpressionType.smile: return '웃는 표정 결과';
      case ExpressionType.sad: return '슬픈 표정 결과';
      case ExpressionType.angry: return '화난 표정 결과';
      case ExpressionType.neutral: return '무표정 결과';
    }
  }

  @override
  Widget build(BuildContext context) {
    final percentage = (widget.finalScore * 100).round();
    final color = widget.finalScore >= 0.8 ? AppColors.success : (widget.finalScore >= 0.6 ? AppColors.accent : AppColors.error);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_getTitle(), style: const TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: false, // 뒤로가기 버튼 제거
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            const Text('오늘의 훈련 결과', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSizes.lg),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: CircularProgressIndicator(
                    value: widget.finalScore,
                    strokeWidth: 10,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                Text('$percentage%', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
            const SizedBox(height: AppSizes.xl),
            const Text(
              '수고하셨습니다!\n결과가 기록에 저장되었어요.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                // 상세 기록(그래프) 페이지로 이동
                Get.to(() => TrainingLogScreen(expressionType: widget.expressionType));
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSizes.lg),
              ),
              child: const Text('기록 페이지로 이동', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: AppSizes.sm),
            TextButton(
              onPressed: () {
                // 훈련 선택 화면으로 돌아가기 (스택의 맨 처음으로)
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('홈으로 돌아가기'),
            ),
            const SizedBox(height: AppSizes.lg),
          ],
        ),
      ),
    );
  }
}