import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/user_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_wrapper.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final userProvider = UserProvider();
  await userProvider.loadUser();

  runApp(
    ChangeNotifierProvider.value(
      value: userProvider,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YOU(th) App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: Consumer<UserProvider>(
        builder: (context, userProvider, _) {
          if (userProvider.isLoggedIn) {
            return const MainWrapper();
          } else {
            return const LoginScreen();
          }
        },
      ),
    );
  }
}
