import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Top image section
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/homepage.png',
                    fit: BoxFit.cover,
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 40),
                      Text(
                        'MUK BITES',
                        style: GoogleFonts.creepster(
                          fontSize: 36,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                      SizedBox(height: 10),
                      Image.asset(
                        'assets/images/logo.png',
                        width: 80,
                        height: 80,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Bottom section with buttons
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFFE5E0), Color(0xFFF78B8B)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 250,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFE4002B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        // TODO: Navigate to LoginPage
                      },
                      child: Text(
                        'Login',
                        style: GoogleFonts.courierPrime(
                          fontSize: 22,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  SizedBox(
                    width: 250,
                    height: 50,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Color(0xFFE4002B), width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.white,
                      ),
                      onPressed: () {
                        // TODO: Navigate to SignUpPage
                      },
                      child: Text(
                        'Sign up',
                        style: GoogleFonts.courierPrime(
                          fontSize: 22,
                          color: Color(0xFFE4002B),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
