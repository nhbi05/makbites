import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../screens/landing_page.dart';
import '../screens/auth/login.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/customer/customer_home.dart';
import '../screens/vendor/vendor_home.dart';
import '../screens/delivery/delivery_home.dart';

class AppRoutes {
  // Route names
  static const String splash = '/';
  static const String landing = '/landing';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String customerHome = '/customer-home';
  static const String vendorHome = '/vendor-home';
  static const String deliveryHome = '/delivery-home';

  // Route map
  static Map<String, WidgetBuilder> get routes {
    return {
      splash: (context) =>  SplashScreen(),
      landing: (context) =>  LandingScreen(),
      login: (context) =>  LoginScreen(),
      signup: (context) =>  SignUpScreen(),
      customerHome: (context) =>  CustomerHomeScreen(),
      vendorHome: (context) =>  VendorHomePage(),
      deliveryHome: (context) =>  DeliveryHomeScreen(),
    };
  }

  // Handle unknown routes
  static Route<dynamic> onUnknownRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (context) => const NotFoundScreen(),
    );
  }
}

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Page Not Found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'The page you are looking for does not exist.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacementNamed(
                context,
                AppRoutes.splash,
              ),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}

// Optional: Custom page route transitions
class CustomPageRoute<T> extends MaterialPageRoute<T> {
  CustomPageRoute({required WidgetBuilder builder, RouteSettings? settings})
      : super(builder: builder, settings: settings);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(animation),
      child: child,
    );
  }
}