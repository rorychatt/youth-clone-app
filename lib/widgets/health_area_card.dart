import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HealthAreaCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String count;

  const HealthAreaCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.lightGray),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                Text('$count biomarkers to improve', style: AppTheme.bodySmall),
              ],
            ),
          ),
          Row(
            children: [
              Container(
                width: 6,
                height: 14,
                decoration: BoxDecoration(
                  color: const Color(0xFFF97316),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 6),
              Text('Average', style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(width: 4),
              const Icon(CupertinoIcons.chevron_down, color: AppColors.darkGray, size: 16),
            ],
          ),
        ],
      ),
    );
  }
}
