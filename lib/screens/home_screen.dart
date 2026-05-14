import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/circular_gauge.dart';
import '../widgets/glass_action_card.dart';
import '../widgets/health_area_card.dart';
import '../widgets/sync_data_sheet.dart';
import 'link_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;
  bool _hasSynced = false;

  void _connectWearable() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.getLinkToken(userProvider.userId!);
      final linkUrl = res['link_url'];

      final success = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LinkScreen(url: linkUrl)),
      );

      if (success == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wearable connected! Syncing data...')),
        );
        _syncData();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _syncData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.syncJunction(userProvider.userId!);
      if (!mounted) return;
      setState(() => _hasSynced = true);

      final data = res['data_fetched'] ?? {};

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) => SyncDataSheet(data: data),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          // Main Scrollable Content
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(
                bottom: 100,
              ), // Space for bottom nav
              child: Column(
                children: [
                  _buildTopDarkSection(context),
                  _buildBottomLightSection(),
                ],
              ),
            ),
          ),

          // Bottom Navigation Bar
          // Bottom navbar removed to MainWrapper
        ],
      ),
    );
  }

  Widget _buildTopDarkSection(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    // Use stored name if available, otherwise fall back to email prefix
    String displayName;
    if (userProvider.name != null && userProvider.name!.isNotEmpty) {
      displayName = userProvider.name!;
    } else {
      final emailPrefix = userProvider.email?.split('@')[0] ?? 'User';
      displayName = emailPrefix.isNotEmpty
          ? '${emailPrefix[0].toUpperCase()}${emailPrefix.substring(1)}'
          : 'User';
    }

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
        gradient: RadialGradient(
          center: Alignment(0.0, -0.2),
          radius: 1.0,
          colors: [
            Color(0xFFD4835A),
            Color(0xFFC06A3A),
            Color(0xFF8B4020),
            Color(0xFF3D1A0A),
            AppColors.dark,
          ],
          stops: [0.0, 0.25, 0.5, 0.75, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 32),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WELCOME BACK,',
                          style: AppTheme.caption.copyWith(
                            color: Colors.white60,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              displayName,
                              style: AppTheme.headingMedium.copyWith(
                                color: AppColors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _showEditNameDialog(context),
                              child: const Icon(
                                Icons.edit,
                                color: Colors.white60,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => userProvider.logout(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: AppColors.white,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          name.isNotEmpty ? name[0] : 'S',
                          style: AppTheme.headingSmall.copyWith(
                            color: AppColors.dark,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Health Score Title
              Text(
                'Health Score',
                style: AppTheme.headingMedium.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'UPDATED TODAY',
                style: AppTheme.caption.copyWith(
                  color: Colors.white60,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),

              // Gauge
              const SizedBox(height: 24),
              const CircularGauge(score: 92, label: 'Optimal'),

              const SizedBox(height: 16),

              // Pill
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '4/10 ',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Biomarkers to improve',
                      style: AppTheme.bodyMedium.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Action Cards Scroller
              SizedBox(
                height: 180,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    GlassActionCard(
                      icon: Icons.watch,
                      title: 'Connect your devices',
                      subtitle:
                          'Unlock more insights by connecting your wearable devices',
                      buttonText: _isLoading
                          ? 'CONNECTING...'
                          : 'CONNECT A DEVICE',
                      onTap: _connectWearable,
                    ),
                    const SizedBox(width: 16),
                    GlassActionCard(
                      icon: _hasSynced ? Icons.check_circle : Icons.sync,
                      title: 'Fetch Latest Data',
                      subtitle: _hasSynced ? 'UP TO DATE' : 'OUT OF SYNC',
                      subtitleColor: _hasSynced
                          ? Colors.green
                          : const Color(0xFFF97316),
                      buttonText: _isLoading
                          ? 'SYNCING...'
                          : (_hasSynced ? 'SYNC AGAIN' : 'SYNC HEALTH DATA'),
                      onTap: _syncData,
                      isWarning: !_hasSynced,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomLightSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Health areas to improve',
            style: AppTheme.headingMedium.copyWith(color: AppColors.dark),
          ),
          const SizedBox(height: 16),
          const HealthAreaCard(
            icon: CupertinoIcons.heart_fill,
            iconColor: Colors.red,
            title: 'Cardiovascular',
            count: '2/4',
          ),
          const SizedBox(height: 12),
          const HealthAreaCard(
            icon: CupertinoIcons.wind,
            iconColor: Colors.orange,
            title: 'Respiratory',
            count: '2/4',
          ),
          const SizedBox(height: 12),
          HealthAreaCard(
            icon: CupertinoIcons.bolt_fill,
            iconColor: Colors.amber[700]!,
            title: 'Metabolic',
            count: '2/4',
          ),
          const SizedBox(height: 12),
          HealthAreaCard(
            icon: CupertinoIcons.drop_fill,
            iconColor: Colors.red[700]!,
            title: 'Blood',
            count: '2/4',
          ),

          const SizedBox(height: 32),
          Text(
            'Health areas to unlock',
            style: AppTheme.headingMedium.copyWith(color: AppColors.dark),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
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
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    CupertinoIcons.person_solid,
                    color: Color(0xFFF97316),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Face skin',
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Run checkup to see results',
                        style: AppTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.dark,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text(
                    'UNLOCK',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          Text(
            'DISCLAIMER',
            style: AppTheme.caption.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'It\'s important to note that while these biomarkers provide a comprehensive overview, they don\'t capture everything. A regular check-ups with health professionals is recommended. Learn more.',
            style: AppTheme.bodySmall.copyWith(height: 1.5),
          ),

          const SizedBox(height: 40),
          Center(
            child: Text(
              'YOU(th)',
              style: AppTheme.headingMedium.copyWith(
                color: AppColors.dark,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditNameDialog(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final controller = TextEditingController(
      text: userProvider.name ??
          (userProvider.email?.split('@')[0] ?? '').substring(0, 1).toUpperCase() +
              (userProvider.email?.split('@')[0] ?? '').substring(1),
    );
    bool isLoading = false;

    showCupertinoDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return CupertinoAlertDialog(
            title: const Text('Edit Name'),
            content: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: CupertinoTextField(
                controller: controller,
                placeholder: 'Enter your name',
                autofocus: true,
                maxLength: 100,
              ),
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: isLoading
                    ? null
                    : () async {
                        final newName = controller.text.trim();
                        if (newName.isEmpty || newName.length > 100) {
                          showCupertinoDialog(
                            context: dialogContext,
                            builder: (ctx) => CupertinoAlertDialog(
                              title: const Text('Invalid Name'),
                              content: const Text('Name must be between 1 and 100 characters.'),
                              actions: [
                                CupertinoDialogAction(
                                  child: const Text('OK'),
                                  onPressed: () => Navigator.of(ctx).pop(),
                                ),
                              ],
                            ),
                          );
                          return;
                        }

                        setState(() {
                          isLoading = true;
                        });

                        try {
                          await userProvider.updateName(newName);
                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop();
                          }
                        } catch (e) {
                          setState(() {
                            isLoading = false;
                          });
                          if (dialogContext.mounted) {
                            showCupertinoDialog(
                              context: dialogContext,
                              builder: (ctx) => CupertinoAlertDialog(
                                title: const Text('Error'),
                                content: Text('Failed to update name: $e'),
                                actions: [
                                  CupertinoDialogAction(
                                    child: const Text('OK'),
                                    onPressed: () => Navigator.of(ctx).pop(),
                                  ),
                                ],
                              ),
                            );
                          }
                        }
                      },
                child: isLoading
                    ? const CupertinoActivityIndicator()
                    : const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }
}
