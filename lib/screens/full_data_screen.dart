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
      if (mounted)
        setState(() {
          _error = 'Not logged in';
          _isLoading = false;
        });
      return;
    }

    try {
      final history = await ApiService.getHealthHistory(userProvider.userId!);
      if (mounted) {
        setState(() {
          if (history.isNotEmpty) {
            final latestSync = history.last;
            final sleepArray = latestSync['sleep'] as List<dynamic>?;
            _history = sleepArray ?? [];
          } else {
            _history = [];
          }
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

  void _showAskMoreSheet(BuildContext context) {
    final textController = TextEditingController();
    bool isAsking = false;
    String chatResponse = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF2C1E16),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ask Claude',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (chatResponse.isNotEmpty)
                        Container(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(ctx).size.height * 0.5,
                          ),
                          margin: const EdgeInsets.only(bottom: 16.0),
                          child: SingleChildScrollView(
                            child: Text(
                              chatResponse,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),
                      TextField(
                        controller: textController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'e.g. Why is my HRV so low?',
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: isAsking
                              ? null
                              : () async {
                                  if (textController.text.trim().isEmpty)
                                    return;
                                  setSheetState(() {
                                    isAsking = true;
                                    chatResponse = '';
                                  });

                                  Map<String, dynamic>? latestSleep;
                                  if (_history.isNotEmpty) {
                                    latestSleep = _history.last as Map<String, dynamic>?;
                                  }

                                  final score =
                                      (latestSleep?['score'] as num?)
                                          ?.toDouble() ??
                                      0.0;
                                  final restingHr =
                                      (latestSleep?['hr_resting'] as num?)
                                          ?.toInt() ??
                                      (latestSleep?['hr_lowest'] as num?)
                                          ?.toInt() ??
                                      0;
                                  final hrv =
                                      (latestSleep?['average_hrv'] as num?)
                                          ?.toInt() ??
                                      0;

                                  final prompt =
                                      "Context: The user's latest sleep score is ${score.toInt()}/100, resting HR is $restingHr bpm, and HRV is $hrv ms. Question: ${textController.text}";

                                  try {
                                    final res = await ApiService.askClaude(
                                      prompt,
                                    );
                                    if (ctx.mounted) {
                                      setSheetState(() {
                                        chatResponse = res;
                                        isAsking = false;
                                      });
                                    }
                                  } catch (e) {
                                    if (ctx.mounted) {
                                      setSheetState(() {
                                        chatResponse =
                                            "Sorry, couldn't reach Claude.";
                                        isAsking = false;
                                      });
                                    }
                                  }
                                },
                          child: isAsking
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Ask',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                      ),
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
                    const Spacer(),
                    IconButton(
                      icon: const Icon(
                        Icons.auto_awesome,
                        color: Colors.orangeAccent,
                      ),
                      onPressed: () => _showAskMoreSheet(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : _error.isNotEmpty
                    ? Center(
                        child: Text(
                          _error,
                          style: const TextStyle(color: Colors.white),
                        ),
                      )
                    : _history.isEmpty
                    ? const Center(
                        child: Text(
                          'No historical data found',
                          style: TextStyle(color: Colors.white),
                        ),
                      )
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
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Range: ${idealMin.toInt()}-${idealMax.toInt()}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
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
                maxX: (_history.length - 1).toDouble().clamp(
                  1.0,
                  double.infinity,
                ),
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
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index < 0 || index >= _history.length) return const SizedBox.shrink();
                        
                        String text = '${index + 1}';
                        final dateStr = _history[index]['date'] as String?;
                        if (dateStr != null && dateStr.length >= 10) {
                          try {
                            final parsed = DateTime.parse(dateStr);
                            text = '${parsed.month}/${parsed.day}';
                          } catch (_) {
                            text = dateStr.substring(5, 10);
                          }
                        }
                        
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            text,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 10,
                          ),
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
