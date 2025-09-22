import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../models/expression_type.dart';
import '../utils/constants.dart';
import 'training_screen.dart';
import '../services/training_api_service.dart';

class ExpressionSelectScreen extends StatefulWidget {
  final CameraDescription camera;

  const ExpressionSelectScreen({super.key, required this.camera});

  @override
  State<ExpressionSelectScreen> createState() => _ExpressionSelectScreenState();
}

class _ExpressionSelectScreenState extends State<ExpressionSelectScreen> {
  final _api = TrainingApiService();
  bool _loadingRecs = false;
  List<Map<String, dynamic>> _recommendations = const [];

  void _navigate(BuildContext context, ExpressionType type) {
    Get.to(() => TrainingScreen(camera: widget.camera, expressionType: type));
  }

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    setState(() => _loadingRecs = true);
    try {
      final recs = await _api.fetchTrainingRecommendations(limit: 3);
      setState(() {
        _recommendations = recs;
        _loadingRecs = false;
      });
    } catch (_) {
      setState(() => _loadingRecs = false);
    }
  }

  String _exprLabel(String? expr) {
    if (expr == null) return '해당 표정';
    final e = expr.toLowerCase();
    switch (e) {
      case 'smile':
      case 'happy':
        return '웃는 표정';
      case 'angry':
        return '화난 표정';
      case 'sad':
        return '슬픈 표정';
      case 'neutral':
      case 'none':
        return '무표정';
      default:
        return expr;
    }
  }

  int? _extractPercent(dynamic v) {
    if (v == null) return null;
    if (v is num) {
      final d = v.toDouble();
      if (d <= 1.0) return (d * 100).round();
      if (d > 1.0 && d <= 100.0) return d.round();
      return d.clamp(0.0, 100.0).round();
    }
    final parsed = double.tryParse(v.toString());
    if (parsed == null) return null;
    if (parsed <= 1.0) return (parsed * 100).round();
    if (parsed > 1.0 && parsed <= 100.0) return parsed.round();
    return parsed.clamp(0.0, 100.0).round();
  }

  String _formatRecommendation(Map<String, dynamic> m) {
    final expr = (m['expr'] ?? m['expression'] ?? m['type'])?.toString();
    final percent = _extractPercent(
      m['progress'] ??
          m['percent'] ??
          m['percentage'] ??
          m['score'] ??
          m['value'] ??
          m['avg'] ??
          m['average'],
    );
    if (expr != null && percent != null) {
      final label = _exprLabel(expr);
      return '$label의 진척도가 ${percent}% 입니다. 이 표정 훈련 어떠세요?';
    }
    // 폴백: 기존 텍스트 키 사용
    final primary =
        m['title'] ??
        m['message'] ??
        m['tip'] ??
        m['text'] ??
        m['content'] ??
        expr ??
        '표정 훈련을 제안합니다';
    return primary.toString();
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '진척도에 따른 표정 훈련 제안',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  if (_loadingRecs)
                    const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else if (_recommendations.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _recommendations
                          .take(3)
                          .map(
                            (m) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('• '),
                                  Expanded(
                                    child: Text(_formatRecommendation(m)),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    )
                  else
                    const Text(
                      '추천 정보를 불러올 수 없습니다.',
                      style: TextStyle(color: AppColors.textSecondary),
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
