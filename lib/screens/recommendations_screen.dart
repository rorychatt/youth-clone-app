import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _isGenerating = false;
  List<String> _recommendations = [];
  String? _error;
  Timer? _pollingTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(_pulseController);
    _fetchOrGenerateRecommendations();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _fetchOrGenerateRecommendations() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.userId == null) {
      setState(() {
        _isLoading = false;
        _error = 'User not logged in';
      });
      return;
    }

    try {
      // First, try to fetch existing recommendations
      final recs = await ApiService.getRecommendations(userProvider.userId!);
      if (recs != null && recs.isNotEmpty) {
        if (mounted) {
          setState(() {
            _recommendations = recs;
            _isLoading = false;
          });
        }
      } else {
        // No recs yet, let's trigger a generation
        await _triggerGeneration(userProvider.userId!);
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

  Future<void> _triggerGeneration(String userId) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _isGenerating = true;
      _error = null;
    });

    try {
      await ApiService.triggerRecommendations(userId, "home_feed");
      _startPolling(userId);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Failed to start generation: ${e.toString()}";
          _isLoading = false;
          _isGenerating = false;
        });
      }
    }
  }

  void _startPolling(String userId) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        final recs = await ApiService.getRecommendations(userId);
        if (recs != null && recs.isNotEmpty) {
          timer.cancel();
          if (mounted) {
            setState(() {
              _recommendations = recs;
              _isLoading = false;
              _isGenerating = false;
            });
          }
        }
      } catch (e) {
        // Ignore fetch errors during polling, it might just be network blips
        debugPrint("Polling error: $e");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text('For You', style: AppTheme.headingMedium.copyWith(color: AppColors.dark)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        actions: [
          if (!_isLoading && !_isGenerating)
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.dark),
              onPressed: () {
                final userProvider = Provider.of<UserProvider>(context, listen: false);
                if (userProvider.userId != null) {
                  _triggerGeneration(userProvider.userId!);
                }
              },
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading || _isGenerating) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: _pulseAnimation,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFD67A58).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome, size: 64, color: Color(0xFFD67A58)),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Analyzing your health data...',
              style: AppTheme.headingSmall.copyWith(color: AppColors.darkGray),
            ),
            const SizedBox(height: 8),
            Text(
              'Claude is curating personalized insights.',
              style: AppTheme.bodyMedium.copyWith(color: AppColors.lightGray),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Text('Error: $_error', style: const TextStyle(color: Colors.red)),
      );
    }

    if (_recommendations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox, size: 64, color: AppColors.lightGray),
            const SizedBox(height: 16),
            Text('No recommendations available.', style: AppTheme.bodyMedium.copyWith(color: AppColors.darkGray)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      itemCount: _recommendations.length,
      itemBuilder: (context, index) {
        final rec = _recommendations[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD67A58).withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDF2ED), // Light peach
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.tips_and_updates, color: Color(0xFFD67A58), size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Insight ${index + 1}',
                      style: AppTheme.bodySmall.copyWith(
                        color: const Color(0xFFD67A58),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      rec,
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppColors.dark,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
