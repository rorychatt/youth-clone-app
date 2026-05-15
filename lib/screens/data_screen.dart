import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/user_provider.dart';
import 'full_data_screen.dart';
import '../widgets/circular_gauge.dart';

class DataScreen extends StatefulWidget {
  const DataScreen({super.key});

  @override
  State<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen> {
  bool _isLoading = true;
  String _error = '';
  Map<String, dynamic>? _sleepData;
  String _aiSuggestion = '';
  bool _isAiLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.userId == null) {
      setState(() {
        _error = 'User not logged in';
        _isLoading = false;
      });
      return;
    }

    try {
      final metrics = await ApiService.getHealthMetrics(userProvider.userId!);

      // metrics might be {"sleep": [{...}]}
      if (metrics['sleep'] != null && (metrics['sleep'] as List).isNotEmpty) {
        setState(() {
          _sleepData = (metrics['sleep'] as List).last;
          _isLoading = false;
        });
        _fetchSuggestion();
      } else {
        setState(() {
          _error = 'No recent sleep data found.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchSuggestion() async {
    final score = (_sleepData?['score'] as num?)?.toDouble() ?? 0.0;
    final restingHr =
        (_sleepData?['hr_resting'] as num?)?.toInt() ??
        (_sleepData?['hr_lowest'] as num?)?.toInt() ??
        0;
    final hrv = (_sleepData?['average_hrv'] as num?)?.toInt() ?? 0;

    final prompt =
        "I am an app user tracking my sleep and recovery. My overall sleep score last night was ${score.toInt()}/100. My resting heart rate was $restingHr bpm and my average HRV was $hrv ms. In exactly two short sentences, what does this mean for my health baseline and what should my priority be today? Do not include greetings.";

    try {
      final response = await ApiService.askClaude(prompt);
      if (mounted) {
        setState(() {
          _aiSuggestion = response;
          _isAiLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _aiSuggestion = 'Unable to generate insight at this time.';
          _isAiLoading = false;
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

                                  final score =
                                      (_sleepData?['score'] as num?)
                                          ?.toDouble() ??
                                      0.0;
                                  final restingHr =
                                      (_sleepData?['hr_resting'] as num?)
                                          ?.toInt() ??
                                      (_sleepData?['hr_lowest'] as num?)
                                          ?.toInt() ??
                                      0;
                                  final hrv =
                                      (_sleepData?['average_hrv'] as num?)
                                          ?.toInt() ??
                                      0;

                                  final prompt =
                                      "Context: The user's sleep score is ${score.toInt()}/100, resting HR is $restingHr bpm, and HRV is $hrv ms. Question: ${textController.text}";

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
    // Exact dark theme gradient from screenshot
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
      backgroundColor: Colors
          .transparent, // Parent might provide background, but we'll override it
      body: Container(
        decoration: BoxDecoration(gradient: gradient),
        child: SafeArea(
          bottom: false,
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : _error.isNotEmpty
              ? _buildErrorState()
              : _buildDataContent(),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.white70, size: 48),
          const SizedBox(height: 16),
          Text(
            _error,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isLoading = true;
                _error = '';
              });
              _fetchData();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildDataContent() {
    // Extracting real values
    final score = (_sleepData?['score'] as num?)?.toDouble() ?? 0.0;

    // Determine labels based on score
    String scoreLabel = 'Moderate';
    Color scoreColor = Colors.orange;
    if (score >= 80) {
      scoreLabel = 'Strong';
      scoreColor = Colors.greenAccent;
    } else if (score < 60) {
      scoreLabel = 'Weak';
      scoreColor = Colors.pinkAccent;
    }

    final restingHr =
        (_sleepData?['hr_resting'] as num?)?.toInt() ??
        (_sleepData?['hr_lowest'] as num?)?.toInt() ??
        0;
    final hrv = (_sleepData?['average_hrv'] as num?)?.toInt() ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Center(
            child: Text(
              'SCAN RESULTS',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
                letterSpacing: 2.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 28,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                children: [
                  const TextSpan(text: 'Your wellness score\nis '),
                  TextSpan(
                    text: scoreLabel.toLowerCase(),
                    style: TextStyle(
                      color: scoreColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.arrow_upward,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  'Higher than 25% of users',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 48),

          // Main Gauge Card (Glassmorphic)
          Container(
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Wellness score',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'UPDATED TODAY',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 10,
                            letterSpacing: 1.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FullDataScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'SEE FULL DATA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            letterSpacing: 1.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Center(
                  child: CircularGauge(score: score, label: ''),
                ),
                // Custom label under gauge score replacing the built in one
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 12,
                        decoration: BoxDecoration(
                          color: scoreColor,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        scoreLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Resting HR: $restingHr bpm • HRV: $hrv ms',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Priority Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withValues(alpha: 0.1),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'WHAT THIS MEANS',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 10,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _isAiLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: CircularProgressIndicator(
                            color: Colors.white54,
                          ),
                        ),
                      )
                    : Text(
                        _aiSuggestion,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () => _showAskMoreSheet(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'ASK MORE',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.chevron_right,
                          color: Colors.black,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 120), // Padding for BottomNavBar
        ],
      ),
    );
  }
}
