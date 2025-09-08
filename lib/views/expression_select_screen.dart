import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../models/expression_type.dart';
import '../utils/constants.dart';
import 'training_screen.dart';

class ExpressionSelectScreen extends StatelessWidget {
  final CameraDescription camera;

  const ExpressionSelectScreen({super.key, required this.camera});

  void _navigate(BuildContext context, ExpressionType type) {
    Get.to(() => TrainingScreen(camera: camera, expressionType: type));
  }

  @override
  Widget build(BuildContext context) {
    final String todayLabel = DateFormat(
      'y년 M월 d일 (EEE)',
      'ko',
    ).format(DateTime.now());
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          '훈련모드',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: AppColors.surface,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    todayLabel,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: 0.55, // 화면 너비의 18% 길이
                child: Container(height: 3, color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(height: AppSizes.md),
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: AppSizes.md,
                horizontal: AppSizes.lg,
              ),
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withOpacity(0.25),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      '진척도에 따른 표정 훈련 제안',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.xl),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: AppSizes.lg,
                mainAxisSpacing: AppSizes.lg,
                childAspectRatio: 0.7,
                children: [
                  _gridItem(
                    title: '웃는 표정',
                    emoji: '😊',
                    buttonColor: AppColors.primary,
                    onTrain: () => _navigate(context, ExpressionType.smile),
                  ),
                  _gridItem(
                    title: '화난 표정',
                    emoji: '😠',
                    buttonColor: AppColors.error,
                    onTrain: () => _navigate(context, ExpressionType.angry),
                  ),
                  _gridItem(
                    title: '슬픈 표정',
                    emoji: '😢',
                    buttonColor: AppColors.secondary,
                    onTrain: () => _navigate(context, ExpressionType.sad),
                  ),
                  _gridItem(
                    title: '무표정',
                    emoji: '😐',
                    buttonColor: AppColors.accent,
                    onTrain: () => _navigate(context, ExpressionType.neutral),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gridItem({
    required String title,
    required String emoji,
    required Color buttonColor,
    required VoidCallback onTrain,
  }) {
    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 6),
                  child: Text(emoji, style: const TextStyle(fontSize: 64)),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onTrain,
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: AppColors.surface,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            child: const Text(
              '훈련하기',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
