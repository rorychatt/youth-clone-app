import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  _ServicesScreenState createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  bool _isLoading = true;
  List<dynamic> _providers = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchProviders();
  }

  Future<void> _fetchProviders() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.userId == null) {
      setState(() {
        _isLoading = false;
        _error = 'User not logged in';
      });
      return;
    }

    try {
      final providers = await ApiService.getProviders(userProvider.userId!);
      if (mounted) {
        setState(() {
          _providers = providers;
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

  Future<void> _disconnectProvider(String slug) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect Device'),
        content: const Text('Are you sure you want to disconnect this device? You will no longer receive data from it.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.darkGray)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Disconnect', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    
    try {
      await ApiService.disconnectProvider(userProvider.userId!, slug);
      await _fetchProviders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Device disconnected successfully.')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text('Linked Devices', style: AppTheme.headingMedium.copyWith(color: AppColors.dark)),
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.dark));
    }

    if (_error != null) {
      return Center(
        child: Text('Error: $_error', style: const TextStyle(color: Colors.red)),
      );
    }

    if (_providers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.link_off, size: 64, color: AppColors.lightGray),
            const SizedBox(height: 16),
            Text('No devices linked yet.', style: AppTheme.bodyMedium.copyWith(color: AppColors.darkGray)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      itemCount: _providers.length,
      itemBuilder: (context, index) {
        final provider = _providers[index];
        final name = provider['name'] ?? 'Unknown';
        final logoUrl = provider['logo'];
        final status = provider['status'] ?? 'unknown';
        
        final isConnected = status == 'connected';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.lightGray),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 4),
              )
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.lightGray.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: logoUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(logoUrl, fit: BoxFit.cover),
                      )
                    : const Icon(Icons.device_hub, color: AppColors.darkGray),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppTheme.headingSmall.copyWith(color: AppColors.dark)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isConnected ? Colors.green : Colors.red,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isConnected ? Colors.green : Colors.red,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () => _disconnectProvider(provider['slug']),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Disconnect', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }
}
