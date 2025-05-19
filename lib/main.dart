import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';
import 'package:smart_energy_pay/Screens/DashboardScreen/DashboardProvider/DashboardProvider.dart';
import 'package:smart_energy_pay/Screens/WelcomeScreen/welcome_screen.dart';
import 'package:smart_energy_pay/constants.dart';
import 'package:smart_energy_pay/util/LoadingWidget.dart';
import 'package:smart_energy_pay/util/auth_manager.dart';
import 'package:smart_energy_pay/Screens/TransactionScreen/TransactionDetailsScreen/transaction_details_screen.dart';

// Define a simple state management class for authentication and loading
class AuthenticationState extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isLoading = false; // Add loading state

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;

  void login() {
    _isLoggedIn = true;
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    notifyListeners();
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    Stripe.publishableKey =
        dotenv.env['stripePublishableKey'] ?? 'default_key';
  }
  await AuthManager.init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthenticationState()),
        ChangeNotifierProvider(create: (context) => DashboardProvider()),
        ChangeNotifierProvider(create: (context) => TransactionProvider()),
      ],
      child: const smart_energy_payApp(),
    ),
  );
}

class smart_energy_payApp extends StatelessWidget {
  const smart_energy_payApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthenticationState>(
      builder: (context, authState, child) {
        return MaterialApp(
          title: 'Smart Energy Pay',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(   
            primaryColor: kPrimaryColor,
            scaffoldBackgroundColor: Colors.white,
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                foregroundColor: Colors.white,
                backgroundColor: kPrimaryColor,
                maximumSize: const Size(double.infinity, 56),
                minimumSize: const Size(double.infinity, 56),
              ),
            ),
            inputDecorationTheme: const InputDecorationTheme(
              filled: true,
              fillColor: kPrimaryLightColor,
              iconColor: kPrimaryColor,
              prefixIconColor: kPrimaryColor,
              contentPadding: EdgeInsets.symmetric(
                horizontal: defaultPadding,
                vertical: defaultPadding,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(30)),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          home: Stack(
            children: [
              // Main content
              const WelcomeScreen(), // Example home screen; replace with your actual home screen or navigation logic
              // Show loading indicator when isLoading is true
              if (authState.isLoading)
                const LoadingWidget(), // Use the Lottie animation as the global loading indicator
            ],
          ),
        );
      },
    );
  }
}
