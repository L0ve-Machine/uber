import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class DeliveryStatusStepper extends StatelessWidget {
  final String currentStatus;

  const DeliveryStatusStepper({
    super.key,
    required this.currentStatus,
  });

  @override
  Widget build(BuildContext context) {
    final steps = [
      _StepData('ready', '準備完了', Icons.restaurant),
      _StepData('picked_up', '受取済み', Icons.inventory),
      _StepData('delivering', '配達中', Icons.directions_bike),
      _StepData('delivered', '配達完了', Icons.check_circle),
    ];

    final currentIndex = steps.indexWhere((s) => s.status == currentStatus);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (index) {
          if (index.isOdd) {
            // Connector line
            final stepIndex = index ~/ 2;
            final isCompleted = stepIndex < currentIndex;
            return Expanded(
              child: Container(
                height: 3,
                color: isCompleted ? AppColors.success : Colors.grey[300],
              ),
            );
          } else {
            // Step circle
            final stepIndex = index ~/ 2;
            final step = steps[stepIndex];
            final isCompleted = stepIndex < currentIndex;
            final isCurrent = stepIndex == currentIndex;

            return _buildStep(step, isCompleted, isCurrent);
          }
        }),
      ),
    );
  }

  Widget _buildStep(_StepData step, bool isCompleted, bool isCurrent) {
    Color backgroundColor;
    Color iconColor;

    if (isCompleted) {
      backgroundColor = AppColors.success;
      iconColor = Colors.white;
    } else if (isCurrent) {
      backgroundColor = Colors.blue;
      iconColor = Colors.white;
    } else {
      backgroundColor = Colors.grey[300]!;
      iconColor = Colors.grey;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            step.icon,
            size: 20,
            color: iconColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          step.label,
          style: TextStyle(
            fontSize: 10,
            color: isCurrent ? Colors.blue : AppColors.textSecondary,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _StepData {
  final String status;
  final String label;
  final IconData icon;

  _StepData(this.status, this.label, this.icon);
}
