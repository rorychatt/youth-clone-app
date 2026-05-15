import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/user_provider.dart';

enum TimeRange { today, week, month, all }

class FullDataScreen extends StatefulWidget {
  const FullDataScreen({super.key});

  @override
  State<FullDataScreen> createState() => _FullDataScreenState();
}

class _FullDataScreenState extends State<FullDataScreen> {
  bool _isLoading = true;
  String _error = '';
  List<dynamic> _history = [];
  TimeRange _selectedRange = TimeRange.all;

  List<dynamic> get _filteredHistory {
    if (_history.isEmpty) return [];

    DateTime now = DateTime.now();
    DateTime? cutoff;

    switch (_selectedRange) {
      case TimeRange.today:
        cutoff = null; // Today shows the latest data, no date filter needed
        break;
      case TimeRange.week:
        cutoff = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 7));
        break;
      case TimeRange.month:
        cutoff = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 30));
        break;
      case TimeRange.all:
        cutoff = null;
        break;
    }

    if (cutoff == null) return _history;

    return _history.where((point) {
      final dateStr = point['date'] as String?;
      DateTime? pointDate;
      if (dateStr != null && dateStr.isNotEmpty) {
        pointDate = DateTime.tryParse(dateStr);
      }

      if (pointDate == null) return false;
      return pointDate.isAfter(cutoff!) || pointDate.isAtSameMomentAs(cutoff);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.userId == null) {
      if (mounted) {
        setState(() {
          _error = 'Not logged in';
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final history = await ApiService.getHealthHistory(userProvider.userId!);
      if (mounted) {
        setState(() {
          if (history.isNotEmpty) {
            List<Map<String, dynamic>> allPoints = [];
            for (var syncEvent in history) {
              final recordedAt = syncEvent['recorded_at'] as String?;
              final sleepArray = syncEvent['sleep'] as List<dynamic>?;
              if (sleepArray != null) {
                for (var sleepDay in sleepArray) {
                  if (sleepDay is Map) {
                    final point = Map<String, dynamic>.from(sleepDay);
                    point['recorded_at'] = recordedAt;
                    allPoints.add(point);
                  }
                }
              }
            }

            Map<String, Map<String, dynamic>> grouped = {};
            for (var point in allPoints) {
              final date = point['date'] as String? ?? '';
              final provider =
                  (point['source'] as Map?)?['name'] as String? ?? 'Unknown';
              final key = '${date}_$provider';
              if (date.isNotEmpty) {
                grouped[key] = point;
              }
            }

            List<Map<String, dynamic>> finalPoints = grouped.values.toList();

            finalPoints.sort((a, b) {
              final dateA = a['date'] as String? ?? '';
              final dateB = b['date'] as String? ?? '';
              final cmp = dateA.compareTo(dateB);
              if (cmp != 0) return cmp;

              final recA = a['recorded_at'] as String? ?? '';
              final recB = b['recorded_at'] as String? ?? '';
              return recA.compareTo(recB);
            });

            _history = finalPoints;
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
                                  if (textController.text.trim().isEmpty) {
                                    return;
                                  }
                                  setSheetState(() {
                                    isAsking = true;
                                    chatResponse = '';
                                  });

                                  Map<String, dynamic>? latestSleep;
                                  if (_history.isNotEmpty) {
                                    latestSleep =
                                        _history.last as Map<String, dynamic>?;
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

  Widget _buildFilterChip(String label, TimeRange range) {
    final isSelected = _selectedRange == range;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRange = range;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? null
              : Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check, size: 16, color: Colors.white),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.7),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
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
              // Filter Buttons
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  children: [
                    _buildFilterChip('Today', TimeRange.today),
                    const SizedBox(width: 8),
                    _buildFilterChip('7 Days', TimeRange.week),
                    const SizedBox(width: 8),
                    _buildFilterChip('30 Days', TimeRange.month),
                    const SizedBox(width: 8),
                    _buildFilterChip('All Time', TimeRange.all),
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
                    : _filteredHistory.isEmpty
                    ? const Center(
                        child: Text(
                          'No historical data found',
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    : _selectedRange == TimeRange.today
                    ? _buildTodaySummary()
                    : _buildCharts(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodaySummary() {
    if (_filteredHistory.isEmpty) {
      return const SizedBox.shrink();
    }

    final todayData = _filteredHistory.last;
    final score = (todayData['score'] as num?)?.toDouble() ?? 0.0;
    final restingHr =
        (todayData['hr_resting'] as num?)?.toInt() ??
        (todayData['hr_lowest'] as num?)?.toInt() ??
        0;
    final hrv = (todayData['average_hrv'] as num?)?.toInt() ?? 0;
    final totalSleepSecs =
        (todayData['total'] as num?)?.toInt() ??
        (todayData['duration'] as num?)?.toInt() ??
        0;
    final hours = totalSleepSecs ~/ 3600;
    final minutes = (totalSleepSecs % 3600) ~/ 60;
    final sleepStr = totalSleepSecs > 0 ? '${hours}h ${minutes}m' : 'N/A';

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildSummaryCard(
          title: 'WELLNESS SCORE',
          value: score.toInt().toString(),
          unit: '/ 100',
          icon: Icons.health_and_safety,
          color: Colors.greenAccent,
        ),
        const SizedBox(height: 16),
        _buildSummaryCard(
          title: 'RESTING HR',
          value: restingHr.toString(),
          unit: 'bpm',
          icon: Icons.favorite,
          color: Colors.pinkAccent,
        ),
        const SizedBox(height: 16),
        _buildSummaryCard(
          title: 'SLEEP DURATION',
          value: sleepStr
              .replaceAll('h ', 'h\n')
              .replaceAll('m', 'm'), // formatting for space
          unit: '',
          icon: Icons.bedtime,
          color: Colors.deepPurpleAccent,
        ),
        const SizedBox(height: 16),
        _buildSummaryCard(
          title: 'HRV',
          value: hrv.toString(),
          unit: 'ms',
          icon: Icons.monitor_heart,
          color: Colors.orangeAccent,
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value.contains('\n') ? value.split('\n')[0] : value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    value.contains('\n') ? value.split('\n')[1] : unit,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: value.contains('\n') ? 32 : 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCharts() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildLegend(),
        const SizedBox(height: 24),
        _buildChartCard(
          title: 'Wellness Score',
          spotsByProvider: _getSpotsByProvider(
            (data) => (data['score'] as num?)?.toDouble() ?? 0.0,
          ),
          minY: 0,
          maxY: 110,
          idealMin: 80,
          idealMax: 100,
        ),
        const SizedBox(height: 24),
        _buildChartCard(
          title: 'Sleep Duration (hrs)',
          spotsByProvider: _getSpotsByProvider((data) {
            final d =
                (data['total'] as num?)?.toDouble() ??
                (data['duration'] as num?)?.toDouble() ??
                0.0;
            return d / 3600.0;
          }),
          minY: 0,
          maxY: 12,
          idealMin: 7,
          idealMax: 9,
        ),
        const SizedBox(height: 24),
        _buildChartCard(
          title: 'Resting Heart Rate (bpm)',
          spotsByProvider: _getSpotsByProvider(
            (data) =>
                (data['hr_resting'] as num?)?.toDouble() ??
                (data['hr_lowest'] as num?)?.toDouble() ??
                0.0,
          ),
          minY: 30,
          maxY: 110,
          idealMin: 40,
          idealMax: 60,
        ),
        const SizedBox(height: 24),
        _buildChartCard(
          title: 'HRV (ms)',
          spotsByProvider: _getSpotsByProvider(
            (data) => (data['average_hrv'] as num?)?.toDouble() ?? 0.0,
          ),
          minY: 10,
          maxY: 160,
          idealMin: 40,
          idealMax: 150,
        ),
        const SizedBox(height: 48),
      ],
    );
  }

  Widget _buildLegend() {
    final providers = _filteredHistory
        .map((e) => (e['source'] as Map?)?['name'] as String? ?? 'Unknown')
        .toSet()
        .toList();
    if (providers.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: providers.map((p) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _getColorForProvider(p),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              p,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  List<String> get _chartDates {
    final dates = _filteredHistory
        .map((e) => e['date'] as String? ?? '')
        .toSet()
        .toList();
    dates.sort();
    return dates;
  }

  Color _getColorForProvider(String provider) {
    final p = provider.toLowerCase();
    if (p.contains('oura')) return Colors.greenAccent;
    if (p.contains('whoop')) return Colors.cyanAccent;
    if (p.contains('apple')) return Colors.orangeAccent;
    if (p.contains('garmin')) return Colors.pinkAccent;
    return Colors.deepPurpleAccent;
  }

  Map<String, List<FlSpot>> _getSpotsByProvider(
    double Function(Map<String, dynamic>) extractor,
  ) {
    Map<String, List<FlSpot>> spotsByProvider = {};
    final dates = _chartDates;

    for (int i = 0; i < dates.length; i++) {
      final date = dates[i];
      final pointsForDate = _filteredHistory.where(
        (e) => (e['date'] as String? ?? '') == date,
      );

      for (var point in pointsForDate) {
        final provider =
            (point['source'] as Map?)?['name'] as String? ?? 'Unknown';
        final val = extractor(point);
        if (val > 0) {
          if (!spotsByProvider.containsKey(provider)) {
            spotsByProvider[provider] = [];
          }
          spotsByProvider[provider]!.add(FlSpot(i.toDouble(), val));
        }
      }
    }
    return spotsByProvider;
  }

  Widget _buildChartCard({
    required String title,
    required Map<String, List<FlSpot>> spotsByProvider,
    required double minY,
    required double maxY,
    required double idealMin,
    required double idealMax,
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
            height: 220,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (_chartDates.length - 1).toDouble().clamp(
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
                      reservedSize: 42,
                      interval: (_chartDates.length / 5).ceilToDouble().clamp(
                        1.0,
                        double.infinity,
                      ),
                      getTitlesWidget: (value, meta) {
                        final dates = _chartDates;
                        int index = value.toInt();
                        if (index < 0 || index >= dates.length) {
                          return const SizedBox.shrink();
                        }

                        String text = '';
                        final dateStr = dates[index];
                        if (dateStr.length >= 10) {
                          try {
                            final parsedDate = DateTime.parse(dateStr);
                            text = '${parsedDate.month}/${parsedDate.day}';
                          } catch (_) {
                            text = dateStr.substring(5, 10);
                          }
                        }

                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            text,
                            textAlign: TextAlign.center,
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
                lineBarsData: spotsByProvider.entries.map((entry) {
                  final provider = entry.key;
                  final spots = entry.value;
                  final color = _getColorForProvider(provider);

                  return LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    preventCurveOverShooting: true,
                    color: color,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: spots.length == 1),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withValues(alpha: 0.1),
                    ),
                  );
                }).toList(),
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
