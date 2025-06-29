import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_page.dart';

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Future.delayed(Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    });
    return Scaffold(
      backgroundColor: Color(0xFFE4002B), // Your red background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'MUK BITES',
              style: GoogleFonts.creepster(
                fontSize: 40,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 20),
            Image.asset(
              'assets/images/logo.png',
              width: 100,
              height: 100,
            ),
          ],
        ),
      ),
    );
  }
}
