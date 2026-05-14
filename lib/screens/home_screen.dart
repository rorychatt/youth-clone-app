import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import 'link_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;
  String _syncResult = '';

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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Wearable connected!')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _syncData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.syncJunction(userProvider.userId!);
      setState(() {
        _syncResult = res.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sync successful!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('YOU(th) Dashboard'),
        actions: [
          IconButton(icon: Icon(Icons.logout), onPressed: () => userProvider.logout())
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Welcome, ${userProvider.email}', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
            SizedBox(height: 40),
            _isLoading 
              ? Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton.icon(
                      icon: Icon(Icons.watch),
                      label: Text('Connect Oura / Wearable'),
                      onPressed: _connectWearable,
                      style: ElevatedButton.styleFrom(padding: EdgeInsets.all(16)),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: Icon(Icons.sync),
                      label: Text('Sync Data'),
                      onPressed: _syncData,
                      style: ElevatedButton.styleFrom(padding: EdgeInsets.all(16)),
                    ),
                  ],
                ),
            SizedBox(height: 20),
            if (_syncResult.isNotEmpty)
              Expanded(
                child: SingleChildScrollView(
                  child: Text('Latest Data:\n$_syncResult', style: TextStyle(fontFamily: 'monospace', fontSize: 12)),
                ),
              )
          ],
        ),
      ),
    );
  }
}
