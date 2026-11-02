import 'package:flutter/material.dart';
import 'package:th2/core/constants/app_colors.dart';
import 'package:th2/core/constants/app_spacing.dart';
import 'package:th2/core/utils/haptic_helper.dart';

/// Interactive Daily Goal Selector allowing exact minute selection (Stepper, Slider, and Custom Input Dialog).
/// Fulfills user request: "Thời gian mục tiêu đổi thành chọn cụ thể chứ không chọn 1 vài gợi ý".
class DailyGoalSelector extends StatefulWidget {
  final int currentMinutes;
  final ValueChanged<int> onGoalChanged;

  const DailyGoalSelector({
    super.key,
    required this.currentMinutes,
    required this.onGoalChanged,
  });

  @override
  State<DailyGoalSelector> createState() => _DailyGoalSelectorState();
}

class _DailyGoalSelectorState extends State<DailyGoalSelector> {
  late double _minutes;

  @override
  void initState() {
    super.initState();
    _minutes = widget.currentMinutes.clamp(1, 180).toDouble();
  }

  @override
  void didUpdateWidget(covariant DailyGoalSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentMinutes != widget.currentMinutes) {
      _minutes = widget.currentMinutes.clamp(1, 180).toDouble();
    }
  }

  void _updateValue(int newMinutes) {
    final clamped = newMinutes.clamp(1, 180);
    setState(() {
      _minutes = clamped.toDouble();
    });
    HapticHelper.selectionClick();
    widget.onGoalChanged(clamped);
  }

  Future<void> _showCustomInputDialog() async {
    HapticHelper.lightImpact();
    final controller = TextEditingController(text: '${_minutes.round()}');
    String? errorMessage;

    final result = await showDialog<int>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              ),
              title: const Row(
                children: [
                  Icon(Icons.edit_calendar_rounded, color: AppColors.primary, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Nhập số phút mục tiêu',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chọn thời gian luyện tập cụ thể mỗi ngày (1 - 180 phút):',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Số phút mỗi ngày',
                      suffixText: 'phút',
                      errorText: errorMessage,
                      prefixIcon: const Icon(Icons.timer_outlined, color: AppColors.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                    ),
                    onSubmitted: (value) {
                      final parsed = int.tryParse(value.trim());
                      if (parsed == null || parsed < 1 || parsed > 180) {
                        setDialogState(() {
                          errorMessage = 'Vui lòng nhập từ 1 đến 180 phút';
                        });
                      } else {
                        Navigator.of(ctx).pop(parsed);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final parsed = int.tryParse(controller.text.trim());
                    if (parsed == null || parsed < 1 || parsed > 180) {
                      setDialogState(() {
                        errorMessage = 'Vui lòng nhập từ 1 đến 180 phút';
                      });
                    } else {
                      Navigator.of(ctx).pop(parsed);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  child: const Text('Xác nhận', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      _updateValue(result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã đặt mục tiêu cụ thể: $result phút/ngày!'),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentVal = _minutes.round();
    final estimatedSentences = (currentVal * 60) ~/ 45;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: AppSpacing.cardShadow,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title & Exact Minutes Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thời gian mục tiêu:',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                  Text(
                    'Kéo thanh trượt hoặc nhập số phút',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondaryLight.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppColors.vibrantGradient,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_rounded, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '$currentVal phút/ngày',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Stepper Control Row: [-5m] [-1m] [Target Display] [+1m] [+5m]
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStepButton(
                label: '-5p',
                onPressed: currentVal > 5 ? () => _updateValue(currentVal - 5) : null,
              ),
              const SizedBox(width: 6),
              _buildStepButton(
                label: '-1p',
                onPressed: currentVal > 1 ? () => _updateValue(currentVal - 1) : null,
              ),
              const SizedBox(width: 12),
              // Prominent Center Number
              Container(
                constraints: const BoxConstraints(minWidth: 90),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      '$currentVal',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                        height: 1.1,
                      ),
                    ),
                    const Text(
                      'phút mỗi ngày',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buildStepButton(
                label: '+1p',
                onPressed: currentVal < 180 ? () => _updateValue(currentVal + 1) : null,
              ),
              const SizedBox(width: 6),
              _buildStepButton(
                label: '+5p',
                onPressed: currentVal <= 175 ? () => _updateValue(currentVal + 5) : null,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Continuous Slider (1 to 120 minutes)
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.primarySoft,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.15),
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              value: _minutes.clamp(1.0, 120.0),
              min: 1.0,
              max: 120.0,
              divisions: 119,
              label: '$currentVal phút',
              onChanged: (val) {
                setState(() {
                  _minutes = val;
                });
              },
              onChangeEnd: (val) {
                _updateValue(val.round());
              },
            ),
          ),

          // Direct Custom Input Button & Motivational estimate
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '💡 Tương đương ~$estimatedSentences câu luyện/ngày',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondaryLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
              InkWell(
                onTap: _showCustomInputDialog,
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    border: Border.all(color: AppColors.primary, width: 1.2),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_outlined, size: 14, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text(
                        'Nhập cụ thể...',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepButton({required String label, required VoidCallback? onPressed}) {
    final isEnabled = onPressed != null;

    return Material(
      color: isEnabled ? AppColors.primarySoft : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Container(
          width: 42,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(
              color: isEnabled
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : Colors.grey.shade300,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isEnabled ? AppColors.primaryDark : Colors.grey.shade400,
            ),
          ),
        ),
      ),
    );
  }
}
