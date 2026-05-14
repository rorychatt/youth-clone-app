import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SyncDataSheet extends StatelessWidget {
  final Map<String, dynamic> data;

  const SyncDataSheet({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // Handle both direct object (mock) and Junction API list format
    Map<String, dynamic> sleepData = data;
    if (data.containsKey('sleep') &&
        data['sleep'] is List &&
        (data['sleep'] as List).isNotEmpty) {
      sleepData = data['sleep'][0];
    }

    // Convert duration from seconds to hours if necessary (Junction API uses seconds)
    String durationStr = '--';
    if (sleepData['duration'] != null) {
      final hours = (sleepData['duration'] / 3600).toStringAsFixed(1);
      durationStr = hours;
    } else if (sleepData['duration_hours'] != null) {
      durationStr = sleepData['duration_hours'].toString();
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: AppColors.lightGray,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Latest Sync Data',
              style: AppTheme.headingMedium.copyWith(color: AppColors.dark),
            ),
            const SizedBox(height: 24),
            _buildDataRow(
              Icons.score,
              'Sleep Score',
              '${sleepData['score'] ?? '--'} / 100',
            ),
            const SizedBox(height: 16),
            _buildDataRow(Icons.timer, 'Duration', '$durationStr hrs'),
            const SizedBox(height: 16),
            _buildDataRow(
              Icons.battery_charging_full,
              'Efficiency',
              '${sleepData['efficiency'] ?? '--'}%',
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.dark,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'DONE',
                  style: TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFFF97316)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Text(
          value,
          style: AppTheme.headingSmall.copyWith(color: AppColors.dark),
        ),
      ],
    );
  }
}
