// lib/ui/main_menu_page.dart - Career Mode Only
import 'package:flutter/material.dart';
import 'package:real_formula/services/career/career_manager.dart';

class MainMenuPage extends StatefulWidget {
  @override
  _MainMenuPageState createState() => _MainMenuPageState();
}

class _MainMenuPageState extends State<MainMenuPage> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _buttonController;
  late Animation<double> _logoAnimation;
  late Animation<double> _buttonAnimation;

  @override
  void initState() {
    super.initState();

    // Logo animation
    _logoController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    _logoAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    // Button animation
    _buttonController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    _buttonAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _buttonController,
      curve: Curves.bounceOut,
    ));

    // Start animations
    _logoController.forward();
    Future.delayed(Duration(milliseconds: 500), () {
      _buttonController.forward();
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.red[900]!,
              Colors.black,
              Colors.grey[900]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top spacer
              Expanded(child: Container()),

              // Logo section
              Expanded(
                flex: 3,
                child: AnimatedBuilder(
                  animation: _logoAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _logoAnimation.value,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.red[600]!,
                                  Colors.red[800]!,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.5),
                                  spreadRadius: 10,
                                  blurRadius: 20,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.sports_motorsports,
                              size: 60,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 20),
                          Text(
                            'F1 CAREER',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 4,
                              shadows: [
                                Shadow(
                                  offset: Offset(2, 2),
                                  blurRadius: 4,
                                  color: Colors.black54,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'SIMULATOR',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w300,
                              color: Colors.grey[400],
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Buttons section
              Expanded(
                flex: 4,
                child: AnimatedBuilder(
                  animation: _buttonAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, 50 * (1 - _buttonAnimation.value)),
                      child: Opacity(
                        opacity: _buttonAnimation.value,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Career Mode Button - Main Action
                            _buildMainButton(
                              label: 'START CAREER',
                              icon: Icons.timeline,
                              onPressed: _handleCareerMode,
                              isPrimary: true,
                              description: 'Begin your F1 journey',
                            ),

                            SizedBox(height: 20),

                            // Load Career Button (if career exists)
                            if (CareerManager.currentCareerDriver != null)
                              _buildMainButton(
                                label: 'CONTINUE CAREER',
                                icon: Icons.play_arrow,
                                onPressed: () {
                                  Navigator.pushNamed(context, '/career_home');
                                },
                                isPrimary: false,
                                description: 'Resume your journey',
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Footer
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Build your F1 legend',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required bool isPrimary,
    required String description,
  }) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 32),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? Colors.red[600] : Colors.grey[800],
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: isPrimary ? 8 : 4,
          shadowColor: isPrimary ? Colors.red[600]?.withOpacity(0.5) : Colors.black26,
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 24),
                SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[300],
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Handle Career Mode button press
  void _handleCareerMode() {
    // Check if there's an existing career
    if (CareerManager.currentCareerDriver != null) {
      // Resume existing career
      Navigator.pushNamed(context, '/career_home');
    } else {
      // Start new career - go to driver creation
      Navigator.pushNamed(context, '/driver_creation');
    }
  }
}
