import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/user_provider.dart';

class FullDataScreen extends StatefulWidget {
  const FullDataScreen({super.key});

  @override
  State<FullDataScreen> createState() => _FullDataScreenState();
}

class _FullDataScreenState extends State<FullDataScreen> {
  bool _isLoading = true;
  String _error = '';
  List<dynamic> _history = [];

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.userId == null) {
      if (mounted) setState(() { _error = 'Not logged in'; _isLoading = false; });
      return;
    }

    try {
      final history = await ApiService.getHealthHistory(userProvider.userId!);
      if (mounted) {
        setState(() {
          _history = history.reversed.toList(); // Assuming API returns desc, we reverse for asc (oldest to newest)
          // Wait, the backend query uses ORDER BY recorded_at ASC, so oldest to newest. No need to reverse.
          _history = history;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF2C1E16), // Dark brown top
        const Color(0xFF5A3522), // Brown middle
        const Color(0xFF9E5C38), // Orange/peachy bottom
      ],
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(gradient: gradient),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Custom App Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'HISTORICAL DATA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : _error.isNotEmpty
                        ? Center(child: Text(_error, style: const TextStyle(color: Colors.white)))
                        : _history.isEmpty
                            ? const Center(child: Text('No historical data found', style: TextStyle(color: Colors.white)))
                            : _buildCharts(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCharts() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildChartCard(
          title: 'Wellness Score',
          spots: _getSpots((data) => (data['score'] as num?)?.toDouble() ?? 0.0),
          minY: 0,
          maxY: 100,
          idealMin: 80,
          idealMax: 100,
          lineColor: Colors.greenAccent,
        ),
        const SizedBox(height: 24),
        _buildChartCard(
          title: 'Resting Heart Rate (bpm)',
          spots: _getSpots((data) => (data['hr_resting'] as num?)?.toDouble() ?? (data['hr_lowest'] as num?)?.toDouble() ?? 0.0),
          minY: 30,
          maxY: 100,
          idealMin: 40,
          idealMax: 60,
          lineColor: Colors.pinkAccent,
        ),
        const SizedBox(height: 24),
        _buildChartCard(
          title: 'HRV (ms)',
          spots: _getSpots((data) => (data['average_hrv'] as num?)?.toDouble() ?? 0.0),
          minY: 10,
          maxY: 150,
          idealMin: 40,
          idealMax: 150,
          lineColor: Colors.orangeAccent,
        ),
        const SizedBox(height: 48),
      ],
    );
  }

  List<FlSpot> _getSpots(double Function(Map<String, dynamic>) extractor) {
    List<FlSpot> spots = [];
    for (int i = 0; i < _history.length; i++) {
      final val = extractor(_history[i]);
      if (val > 0) {
        spots.add(FlSpot(i.toDouble(), val));
      }
    }
    return spots;
  }

  Widget _buildChartCard({
    required String title,
    required List<FlSpot> spots,
    required double minY,
    required double maxY,
    required double idealMin,
    required double idealMax,
    required Color lineColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Range: ${idealMin.toInt()}-${idealMax.toInt()}',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (_history.length - 1).toDouble().clamp(1.0, double.infinity),
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.white.withValues(alpha: 0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: lineColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: spots.length == 1),
                    belowBarData: BarAreaData(
                      show: true,
                      color: lineColor.withValues(alpha: 0.1),
                    ),
                  ),
                ],
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: idealMin,
                      color: Colors.green.withValues(alpha: 0.5),
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    ),
                    if (idealMax < maxY)
                      HorizontalLine(
                        y: idealMax,
                        color: Colors.green.withValues(alpha: 0.5),
                        strokeWidth: 1,
                        dashArray: [5, 5],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
