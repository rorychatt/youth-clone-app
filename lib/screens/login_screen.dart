import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isRegister = false;

  void _submit() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      final provider = Provider.of<UserProvider>(context, listen: false);
      if (_isRegister) {
        await provider.register(
            _emailController.text, _passwordController.text);
      } else {
        await provider.login(_emailController.text, _passwordController.text);
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              _buildForm(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SizedBox(
      width: double.infinity,
      height: 340,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, 0.3),
                  radius: 0.8,
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
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'YOU(th)',
                style: AppTheme.logo.copyWith(color: AppColors.white),
              ),
            ),
          ),
          Positioned.fill(
            child: Center(
              child: _buildBodyScanVisual(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyScanVisual() {
    return SizedBox(
      width: 300,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 110,
            height: 170,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(55),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.15),
                  Colors.white.withValues(alpha: 0.05),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
          // Horizontal scan lines
          ...List.generate(5, (i) {
            return Positioned(
              top: 70.0 + i * 30,
              left: 60,
              right: 60,
              child: Container(
                height: 0.5,
                color: Colors.white.withValues(alpha: 0.15),
              ),
            );
          }),
          Positioned(
            top: 55,
            left: 10,
            child: _scanLabel('METABOLIC'),
          ),
          Positioned(
            top: 55,
            right: 20,
            child: _scanLabel('LUNGS'),
          ),
          Positioned(
            top: 100,
            left: 0,
            child: _scanLabel('CARDIOVASC.'),
          ),
          Positioned(
            top: 100,
            right: 15,
            child: _scanLabel('MENTAL'),
          ),
          Positioned(
            bottom: 75,
            left: 30,
            child: _scanLabel('BRAIN'),
          ),
          Positioned(
            bottom: 75,
            right: 25,
            child: _scanLabel('AGING'),
          ),
          Positioned(
            top: 145,
            right: 15,
            child: _scanLabel('LIVER'),
          ),
        ],
      ),
    );
  }

  Widget _scanLabel(String text) {
    return Text(
      text,
      style: AppTheme.caption.copyWith(
        color: Colors.white.withValues(alpha: 0.6),
        fontSize: 9,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _isRegister ? 'Create account' : 'Login or register',
            style: AppTheme.headingMedium,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 28),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: AppTheme.bodyMedium,
            decoration: _inputDecoration('Email address'),
          ),
          SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: true,
            style: AppTheme.bodyMedium,
            decoration: _inputDecoration('Password'),
          ),
          SizedBox(height: 12),
          Text(
            'Please make sure to use the same email you\'re using to\nlog in to your "Purovitalis" account.',
            style: AppTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          _isLoading
              ? Center(
                  child: CircularProgressIndicator(color: AppColors.dark))
              : OutlinedButton(
                  onPressed: _submit,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: AppColors.dark, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    _isRegister ? 'CREATE ACCOUNT' : 'CONTINUE WITH EMAIL',
                    style: AppTheme.buttonText,
                  ),
                ),
          SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: Divider(color: AppColors.lightGray)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('OR', style: AppTheme.bodySmall),
              ),
              Expanded(child: Divider(color: AppColors.lightGray)),
            ],
          ),
          SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {},
            icon: Text('G',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark)),
            label: Text(
              'CONTINUE WITH GOOGLE',
              style: AppTheme.buttonText,
            ),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: AppColors.lightGray, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          SizedBox(height: 24),
          GestureDetector(
            onTap: () => setState(() => _isRegister = !_isRegister),
            child: Text(
              _isRegister
                  ? 'Already have an account? Login'
                  : 'Don\'t have an account? Register',
              style: AppTheme.bodySmall.copyWith(
                decoration: TextDecoration.underline,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Any issues or questions? Contact support@youth-prevention.com',
            style: AppTheme.bodySmall.copyWith(fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTheme.bodyMedium.copyWith(color: AppColors.darkGray),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.lightGray),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.lightGray),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.dark),
      ),
    );
  }
}
